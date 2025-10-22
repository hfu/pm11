#!/usr/bin/env bash
set -euo pipefail

# run_all.sh (URL-based pmtiles)
# - Fetches country relations from Overpass (name:en regex)
# - Accepts either GeoJSON or OSM JSON (auto-detects and runs osmtogeojson when needed)
# - Normalizes with ogr2ogr if available
# - Dissolves into a single MultiPolygon with mapshaper, optional simplify
# - Runs pmtiles extract using a PMTILES_URL (can be http(s) URL or local path)
#
# Usage:
#   ./run_all.sh                  # produce combined_countries.geojson only
#   ./run_all.sh OUTPUT.pmtiles   # produce OUTPUT.pmtiles (pmtiles extract)
#   SIMPLIFY_PCT=2 ./run_all.sh out.pmtiles
#   MIN_ZOOM=0 MAX_ZOOM=8 ./run_all.sh out.pmtiles
#
# Env / overrides:
#   PMTILES_URL  default https://tunnel.optgeo.org/protomaps-basemap.pmtiles
#   OVERPASS_URL default https://overpass-api.de/api/interpreter
#   TIMEOUT      default 60
#   SIMPLIFY_PCT default 0  (percent for mapshaper -simplify; 0 = no simplify)
#   MIN_ZOOM, MAX_ZOOM optional for pmtiles extract
#
# Dependencies:
#   curl, npx (node) for osmtogeojson/mapshaper fallback, mapshaper, ogr2ogr (optional), jq (optional), pmtiles (CLI)

PMTILES_URL="${PMTILES_URL:-https://tunnel.optgeo.org/protomaps-basemap.pmtiles}"
OVERPASS_URL="${OVERPASS_URL:-https://overpass-api.de/api/interpreter}"
TIMEOUT="${TIMEOUT:-60}"
SIMPLIFY_PCT="${SIMPLIFY_PCT:-0}"
MIN_ZOOM="${MIN_ZOOM:-}"
MAX_ZOOM="${MAX_ZOOM:-}"

# Temporary and output files
TMP_OSM="countries_osm.json"
TMP_GEO="countries_maybe_geojson.json"
CLEAN_GEO="countries_clean.geojson"
OUT_GEO="combined_countries.geojson"

# Country regex (english names)
COUNTRY_REGEX='^(Togo|Rwanda|Thailand|East Timor|Vanuatu|Fiji|Honduras|Moldova|Ethiopia|Laos|Papua New Guinea)$'

OVERPASS_Q="(relation[\"boundary\"=\"administrative\"][\"admin_level\"=\"2\"][\"name:en\"~\"(?i)$COUNTRY_REGEX\"];);out geom;"

echo "=== Pipeline start ==="
echo "pmtiles source: $PMTILES_URL"
echo "Region GeoJSON output: $OUT_GEO"
if [ $# -ge 1 ]; then
  OUTPUT_PM="$1"
  echo "Will produce output pmtiles: $OUTPUT_PM"
else
  OUTPUT_PM=""
  echo "No output pmtiles requested (pass OUTPUT filename as first arg to run extract)"
fi

echo
echo "1) Fetching Overpass data..."
curl -s -G "$OVERPASS_URL" --data-urlencode "data=[out:json][timeout:${TIMEOUT}];$OVERPASS_Q" -o "$TMP_OSM"
if [ ! -s "$TMP_OSM" ]; then
  echo "ERROR: Overpass returned no data. Abort."
  exit 1
fi
echo "Saved Overpass response to $TMP_OSM"

# Detect whether Overpass returned GeoJSON (FeatureCollection) or OSM JSON
IS_GEOJSON=false
if command -v jq >/dev/null 2>&1; then
  if jq -e 'has("type") and (.type == "FeatureCollection")' "$TMP_OSM" >/dev/null 2>&1; then
    IS_GEOJSON=true
  fi
else
  if grep -q '"FeatureCollection"' "$TMP_OSM"; then
    IS_GEOJSON=true
  fi
fi

if [ "$IS_GEOJSON" = true ]; then
  echo "Detected GeoJSON from Overpass; using as-is."
  mv "$TMP_OSM" "$TMP_GEO"
else
  echo "Detected OSM JSON; converting to GeoJSON with osmtogeojson..."
  if command -v npx >/dev/null 2>&1; then
    npx --yes osmtogeojson "$TMP_OSM" > "$TMP_GEO"
  else
    echo "ERROR: npx not found to run osmtogeojson. Install node/npm or provide GeoJSON directly."
    exit 1
  fi
fi
echo "GeoJSON saved to $TMP_GEO"

echo
echo "2) Normalize / dedupe with ogr2ogr (if available)..."
if command -v ogr2ogr >/dev/null 2>&1; then
  ogr2ogr -f GeoJSON "$CLEAN_GEO" "$TMP_GEO"
  echo "Normalized GeoJSON -> $CLEAN_GEO"
else
  echo "ogr2ogr not found; copying raw geojson to $CLEAN_GEO"
  cp "$TMP_GEO" "$CLEAN_GEO"
fi

echo
echo "3) Dissolve into single MultiPolygon and optional simplify (mapshaper)..."
MAPSHAPER_CMD="mapshaper"
if ! command -v mapshaper >/dev/null 2>&1; then
  MAPSHAPER_CMD="npx --yes mapshaper"
fi

if [ "${SIMPLIFY_PCT}" -gt 0 ]; then
  echo "Running: $MAPSHAPER_CMD $CLEAN_GEO -dissolve -clean -simplify dp ${SIMPLIFY_PCT}% keep-shapes -o format=geojson $OUT_GEO"
  $MAPSHAPER_CMD "$CLEAN_GEO" -dissolve -clean -simplify dp "${SIMPLIFY_PCT}%" keep-shapes -o format=geojson "$OUT_GEO"
else
  echo "Running: $MAPSHAPER_CMD $CLEAN_GEO -dissolve -clean -o format=geojson $OUT_GEO"
  $MAPSHAPER_CMD "$CLEAN_GEO" -dissolve -clean -o format=geojson "$OUT_GEO"
fi

echo "Produced region GeoJSON: $OUT_GEO"
if command -v jq >/dev/null 2>&1; then
  echo " - features: $(jq '.features|length' "$OUT_GEO")"
  echo " - geometry type: $(jq -r '.features[0].geometry.type' "$OUT_GEO")"
fi

if [ -z "$OUTPUT_PM" ]; then
  echo
  echo "Pipeline complete. GeoJSON is at: $OUT_GEO"
  echo "To extract pmtiles, run:"
  echo "  ./run_all.sh output_filename.pmtiles"
  exit 0
fi

echo
echo "4) Running pmtiles extract (using PMTILES_URL directly)..."
if command -v pmtiles >/dev/null 2>&1; then
  EXTRACT_CMD=(pmtiles extract "$PMTILES_URL" "$OUTPUT_PM" --region="$OUT_GEO")
  if [ -n "$MIN_ZOOM" ]; then EXTRACT_CMD+=(--min-zoom "$MIN_ZOOM"); fi
  if [ -n "$MAX_ZOOM" ]; then EXTRACT_CMD+=(--max-zoom "$MAX_ZOOM"); fi
  echo "Executing: ${EXTRACT_CMD[*]}"
  "${EXTRACT_CMD[@]}"
  echo "pmtiles extract finished: $OUTPUT_PM"
else
  echo "pmtiles CLI not found. Skipping extract."
  echo "Run the following manually (pmtiles must accept URL):"
  CMD="pmtiles extract \"$PMTILES_URL\" \"$OUTPUT_PM\" --region=\"$OUT_GEO\""
  if [ -n "$MIN_ZOOM" ]; then CMD+=" --min-zoom $MIN_ZOOM"; fi
  if [ -n "$MAX_ZOOM" ]; then CMD+=" --max-zoom $MAX_ZOOM"; fi
  echo "  $CMD"
  exit 0
fi

echo
echo "=== Done. Output pmtiles: $OUTPUT_PM ; region geojson: $OUT_GEO ==="
