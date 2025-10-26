#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./make_region.sh [OPTIONS] [INPUT_PMtiles OUTPUT_PMtiles]
# Examples:
#   ./make_region.sh                 # produce REGION.geojson only
#   ./make_region.sh input.pmtiles out.pmtiles
#
# Environment / optional overrides:
#   OVERPASS_URL    default https://overpass-api.de/api/interpreter
#   TIMEOUT         default 60
#   SIMPLIFY_PCT    default 0 (no simplify). If >0, mapshaper -simplify will be used.
#
# Dependencies:
#   curl, node (npx), osmtogeojson, mapshaper, jq (optional), ogr2ogr (GDAL, optional), pmtiles (CLI, optional)

OVERPASS_URL="${OVERPASS_URL:-https://overpass-api.de/api/interpreter}"
TIMEOUT="${TIMEOUT:-60}"
SIMPLIFY_PCT="${SIMPLIFY_PCT:-0}"   # 0 means no simplify
REGION_OSM="region_osm.json"
REGION_GEO="region_raw.geojson"
REGION_CLEAN="region_clean.geojson"
REGION="REGION.geojson"

COUNTRY_REGEX='^(Togo|Rwanda|Thailand|East Timor|Vanuatu|Fiji|Honduras|Moldova|Ethiopia|Laos|Papua New Guinea)$'

# Optional args
INPUT_PM="${1:-}"
OUTPUT_PM="${2:-}"

echo "1) Fetching country relations from Overpass..."
curl -s -G "$OVERPASS_URL" \
  --data-urlencode "data=[out:json][timeout:${TIMEOUT}];relation[\"boundary\"=\"administrative\"][\"admin_level\"=\"2\"][\"name:en\"~\"$COUNTRY_REGEX\"];out geom;" \
  -o "$REGION_OSM"

if [ ! -s "$REGION_OSM" ]; then
  echo "ERROR: Overpass returned no data. Check OVERPASS_URL/TIMEOUT/COUNTRY_REGEX."
  exit 1
fi
echo "Saved OSM JSON -> $REGION_OSM"

echo "2) Converting OSM JSON -> GeoJSON (osmtogeojson via npx)..."
if command -v npx >/dev/null 2>&1; then
  npx --yes osmtogeojson "$REGION_OSM" > "$REGION_GEO"
else
  echo "ERROR: npx/osmtogeojson not found. Install node and osmtogeojson (or adjust script)."
  exit 1
fi
echo "Saved GeoJSON -> $REGION_GEO"

echo "3) Normalizing / deduping with ogr2ogr if available..."
if command -v ogr2ogr >/dev/null 2>&1; then
  ogr2ogr -f GeoJSON "$REGION_CLEAN" "$REGION_GEO"
  echo "Saved normalized GeoJSON -> $REGION_CLEAN"
else
  echo "ogr2ogr not found — using raw geojson for next steps."
  cp "$REGION_GEO" "$REGION_CLEAN"
fi

echo "4) Extract polygons from GeoJSON..."
POLYGON_GEO="region_polygons.geojson"
if command -v ogr2ogr >/dev/null 2>&1; then
  ogr2ogr -f GeoJSON "$POLYGON_GEO" "$REGION_CLEAN" -where "OGR_GEOMETRY='POLYGON' OR OGR_GEOMETRY='MULTIPOLYGON'"
  echo "Extracted polygons -> $POLYGON_GEO"
else
  echo "ogr2ogr not found; cannot extract polygons. Abort."
  exit 1
fi

echo "5) Dissolve into single MultiPolygon with ogr2ogr..."
if command -v ogr2ogr >/dev/null 2>&1; then
  ogr2ogr -f GeoJSON "$REGION" "$POLYGON_GEO" -dialect sqlite -sql "SELECT ST_Union(geometry) AS geometry FROM region_maybe_geojson"
  echo "Dissolved GeoJSON -> $REGION"
else
  echo "ogr2ogr not found; cannot dissolve. Abort."
  exit 1
fi

echo "6) Quick checks:"
if command -v jq >/dev/null 2>&1; then
  echo "- Feature count:" $(jq '.features | length' "$REGION")
  echo "- Geometry type:" $(jq -r '.features[0].geometry.type' "$REGION")
fi

if [ -n "$INPUT_PM" ] && [ -n "$OUTPUT_PM" ]; then
  if command -v pmtiles >/dev/null 2>&1; then
    echo "7) Running pmtiles extract ${INPUT_PM} -> ${OUTPUT_PM} with region ${REGION} ..."
    pmtiles extract "${INPUT_PM}" "${OUTPUT_PM}" --region="${REGION}"
    echo "pmtiles extract finished: ${OUTPUT_PM}"
  else
    echo "pmtiles CLI not found. Skipping extraction. Run:"
    echo "  pmtiles extract ${INPUT_PM} ${OUTPUT_PM} --region=${REGION}"
  fi
else
  echo "pmtiles extract skipped (no input/output args provided)."
fi

echo "DONE: produced ${REGION}"
