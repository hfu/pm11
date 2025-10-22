# PM11 - PMTiles Extraction for 11 Countries

This repository provides scripts to automatically generate a combined GeoJSON region from 11 specified countries and extract that region from a PMTiles basemap.

**PM11** stands for **PMTiles + 11 countries**.

## Target Countries

The 11 countries (based on OSM `name:en` tag):
- Togo
- Rwanda
- Thailand
- East Timor
- Vanuatu
- Fiji
- Honduras
- Moldova
- Ethiopia
- Laos
- Papua New Guinea

## Features

- ✅ Automatic fetching of country boundaries from Overpass API
- ✅ Auto-detection of OSM JSON vs GeoJSON format
- ✅ GeoJSON normalization with GDAL (optional)
- ✅ Dissolve multiple features into a single MultiPolygon
- ✅ Optional simplification with mapshaper
- ✅ PMTiles extraction with support for URL-based input
- ✅ Configurable zoom levels and simplification parameters

## Dependencies

### Required
- **curl** - For fetching data from Overpass API
- **Node.js/npm** - For running npx commands

### Recommended
- **mapshaper** - For dissolving and simplifying geometries (can be installed globally or used via npx)
- **osmtogeojson** - For converting OSM JSON to GeoJSON (used via npx)
- **pmtiles CLI** - For extracting pmtiles regions
- **jq** - For JSON validation and inspection (optional but helpful)
- **ogr2ogr (GDAL)** - For GeoJSON normalization (optional)

### Installing Dependencies

```bash
# macOS (with Homebrew)
brew install node curl jq gdal
npm install -g mapshaper
npm install -g pmtiles  # or download from https://github.com/protomaps/go-pmtiles

# Ubuntu/Debian
apt-get install curl nodejs npm jq gdal-bin
npm install -g mapshaper
npm install -g pmtiles
```

## Usage

### Quick Start

```bash
# Make scripts executable (if not already)
chmod +x run_all.sh make_countries_geojson.sh

# Generate combined_countries.geojson only
./run_all.sh

# Generate GeoJSON and extract pmtiles
./run_all.sh protomaps_countries.pmtiles
```

### Using Makefile

```bash
# Show help
make help

# Generate combined_countries.geojson
make geojson

# Extract pmtiles
make extract OUTPUT=protomaps_countries.pmtiles

# Clean generated files
make clean
```

### Advanced Usage

#### Custom Simplification

Simplify the geometry by a percentage (useful for smaller file sizes, but be careful with island nations):

```bash
SIMPLIFY_PCT=2 ./run_all.sh protomaps_countries_small.pmtiles
```

#### Custom Zoom Levels

Specify minimum and maximum zoom levels for extraction:

```bash
MIN_ZOOM=0 MAX_ZOOM=8 ./run_all.sh protomaps_countries_z0-8.pmtiles
```

#### Custom PMTiles Source

Use a different PMTiles source (URL or local file):

```bash
PMTILES_URL=/path/to/local/basemap.pmtiles ./run_all.sh output.pmtiles

# Or a different URL
PMTILES_URL=https://example.com/custom-basemap.pmtiles ./run_all.sh output.pmtiles
```

#### Custom Overpass Server

Use a different Overpass API endpoint:

```bash
OVERPASS_URL=https://overpass.kumi.systems/api/interpreter ./run_all.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PMTILES_URL` | `https://tunnel.optgeo.org/protomaps-basemap.pmtiles` | Source PMTiles URL or local path |
| `OVERPASS_URL` | `https://overpass-api.de/api/interpreter` | Overpass API endpoint |
| `TIMEOUT` | `60` | Overpass query timeout in seconds |
| `SIMPLIFY_PCT` | `0` | Mapshaper simplification percentage (0 = no simplification) |
| `MIN_ZOOM` | (empty) | Minimum zoom level for pmtiles extract |
| `MAX_ZOOM` | (empty) | Maximum zoom level for pmtiles extract |

## Scripts

### `run_all.sh`

Main script that handles the complete pipeline:
1. Fetches country relations from Overpass API
2. Auto-detects and converts OSM JSON to GeoJSON if needed
3. Normalizes with ogr2ogr (if available)
4. Dissolves features into a single MultiPolygon
5. Optionally simplifies geometry
6. Optionally runs pmtiles extract

**Usage:**
```bash
./run_all.sh                    # Generate GeoJSON only
./run_all.sh OUTPUT.pmtiles     # Generate GeoJSON and extract pmtiles
```

### `make_countries_geojson.sh`

Legacy script for generating GeoJSON (similar functionality to `run_all.sh`):

**Usage:**
```bash
./make_countries_geojson.sh                          # Generate GeoJSON only
./make_countries_geojson.sh input.pmtiles output.pmtiles  # Include pmtiles extraction
```

## Output Files

- `combined_countries.geojson` - Final combined MultiPolygon region
- `countries_osm.json` / `countries_maybe_geojson.json` - Intermediate Overpass response
- `countries_clean.geojson` / `countries_raw.geojson` - Intermediate normalized GeoJSON

## Important Notes

### Island Nations and Simplification

⚠️ **Warning:** Island nations (Vanuatu, Fiji, Papua New Guinea, East Timor) can lose small islands during aggressive simplification. Use `SIMPLIFY_PCT` cautiously:
- `SIMPLIFY_PCT=0` (default) - No simplification, preserves all details
- `SIMPLIFY_PCT=1-2` - Mild simplification, usually safe
- `SIMPLIFY_PCT=5+` - Aggressive simplification, may lose small islands

The scripts use mapshaper's `keep-shapes` option to help preserve small features, but manual verification is recommended.

### PMTiles CLI URL Support

Some versions of the pmtiles CLI may not support URL inputs directly. If you encounter issues:

1. Download the PMTiles file locally first:
   ```bash
   curl -o basemap.pmtiles https://tunnel.optgeo.org/protomaps-basemap.pmtiles
   ```

2. Use the local path:
   ```bash
   PMTILES_URL=basemap.pmtiles ./run_all.sh output.pmtiles
   ```

### Overpass API Timeouts

If the Overpass query times out, increase the timeout:

```bash
TIMEOUT=120 ./run_all.sh
```

Alternatively, use a different Overpass server that may have better availability.

### Validation

After generating `combined_countries.geojson`, validate the output:

```bash
# Check feature count and geometry type
jq '.features | length' combined_countries.geojson
jq '.features[0].geometry.type' combined_countries.geojson

# Visualize in a web browser
# Upload to https://geojson.io or use QGIS
```

## Examples

### Example 1: Basic GeoJSON Generation

```bash
./run_all.sh
# Output: combined_countries.geojson
```

### Example 2: Extract with Default Settings

```bash
./run_all.sh protomaps_11countries.pmtiles
# Output: combined_countries.geojson, protomaps_11countries.pmtiles
```

### Example 3: Low-Zoom Basemap with Simplification

```bash
SIMPLIFY_PCT=2 MIN_ZOOM=0 MAX_ZOOM=8 ./run_all.sh lowzoom_countries.pmtiles
```

### Example 4: Using Local PMTiles

```bash
# Download first
curl -o basemap.pmtiles https://tunnel.optgeo.org/protomaps-basemap.pmtiles

# Extract
PMTILES_URL=basemap.pmtiles ./run_all.sh output.pmtiles
```

### Example 5: Using Makefile

```bash
# Generate GeoJSON
make geojson

# Extract with custom settings
SIMPLIFY_PCT=1 make extract OUTPUT=simplified_countries.pmtiles

# Clean up
make clean
```

## Testing

To test the scripts without creating output pmtiles (just verify GeoJSON generation):

```bash
# Run GeoJSON generation only
./run_all.sh

# Check output
ls -lh combined_countries.geojson
jq '.features[0].geometry.type' combined_countries.geojson
```

Expected output:
- File `combined_countries.geojson` exists
- Geometry type is `MultiPolygon`
- Feature count is 1 (all countries dissolved into one)

## Troubleshooting

### Error: "npx not found"
Install Node.js: `brew install node` (macOS) or `apt-get install nodejs npm` (Ubuntu)

### Error: "pmtiles CLI not found"
Install pmtiles: `npm install -g pmtiles` or download from [go-pmtiles releases](https://github.com/protomaps/go-pmtiles/releases)

### Error: "Overpass returned no data"
- Increase timeout: `TIMEOUT=120 ./run_all.sh`
- Try a different Overpass server
- Check if the country name regex needs adjustment

### Warning: Small islands missing after simplification
- Reduce `SIMPLIFY_PCT` to 0 or 1
- Use the `keep-shapes` option (already included in scripts)
- Manually verify output with QGIS or geojson.io

## License

See LICENSE file in the repository.

## Contributing

Contributions are welcome! Please ensure:
- Scripts remain POSIX-compliant where possible
- Makefile recipes use tabs (not spaces)
- Test with both local and URL-based PMTiles sources
- Validate GeoJSON output with multiple countries

## Credits

- **Protomaps** - PMTiles format and basemap
- **OpenStreetMap** - Country boundary data
- **Overpass API** - OSM data query service
