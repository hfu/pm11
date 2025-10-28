# PM11 - PMTiles Extraction for 11 Countries

This repository provides scripts to automatically generate a combined GeoJSON region from 11 specified countries and extract that region from a PMTiles basemap.

**PM11** stands for **PMTiles + 11 countries**.

## Demo Site

A live demo of the extracted PMTiles data is available at:

**https://hfu.github.io/pm11/**

The demo site features:
- Interactive map powered by MapLibre GL JS v5+
- PMTiles data served from `https://tunnel.optgeo.org/pm11.pmtiles`
- GlobeControl for 3D globe view
- GeolocationControl for finding your location
- Minimal UI for optimal viewing experience

The demo site is built with Vite and consists of a single HTML file and a single JavaScript file, hosted via GitHub Pages from the `/docs` folder.

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
chmod +x extract_region.sh

# Generate REGION.geojson only
./extract_region.sh

# Generate GeoJSON and extract pmtiles
./extract_region.sh pm11.pmtiles
```

### Using Makefile

```bash
# Show help
make help

# Extract pmtiles (defaults to pm11.pmtiles)
make extract

# Extract with custom output
make extract OUTPUT=custom.pmtiles

# Upload pmtiles to remote server (defaults to pm11.pmtiles)
make upload

# Upload custom file
make upload OUTPUT=custom.pmtiles

# Clean generated files
make clean
```

### Advanced Usage

#### Custom Simplification

Simplify the geometry by a percentage (useful for smaller file sizes, but be careful with island nations):

```bash
SIMPLIFY_PCT=2 ./extract_region.sh pm11_small.pmtiles
```

#### Custom Zoom Levels

Specify minimum and maximum zoom levels for extraction:

```bash
MIN_ZOOM=0 MAX_ZOOM=8 ./extract_region.sh pm11_z0-8.pmtiles
```

#### Custom PMTiles Source

Use a different PMTiles source (URL or local file):

```bash
# Extract
PMTILES_URL=basemap.pmtiles ./extract_region.sh output.pmtiles

# Or a different URL
PMTILES_URL=https://example.com/custom-basemap.pmtiles ./extract_region.sh output.pmtiles
```

#### Custom Overpass Server

Use a different Overpass API endpoint:

```bash
OVERPASS_URL=https://overpass.kumi.systems/api/interpreter ./extract_region.sh
```

#### Uploading PMTiles

After extracting PMTiles, you can upload them to a remote server using the `upload` target:

```bash
# Upload with default destination
make upload OUTPUT=pm11.pmtiles

# Upload to a custom destination
UPLOAD_HOST=user@server.com:/path/to/destination make upload OUTPUT=pm11.pmtiles
```

**Security Considerations:**

- The `upload` target uploads the default file `pm11.pmtiles` if no OUTPUT is specified
- The file must exist before upload (validation is performed)
- By default, uploads to `pod@pod.local:/home/pod/x-24b/data`
- Uses rsync with progress indicator (`-av --progress`)
- Ensure proper SSH key authentication is configured for the destination server
- Review the destination path carefully before running the command

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PMTILES_URL` | `https://tunnel.optgeo.org/protomaps-basemap.pmtiles` | Source PMTiles URL or local path |
| `OVERPASS_URL` | `https://overpass-api.de/api/interpreter` | Overpass API endpoint |
| `TIMEOUT` | `60` | Overpass query timeout in seconds |
| `SIMPLIFY_PCT` | `0` | Mapshaper simplification percentage (0 = no simplification) |
| `MIN_ZOOM` | (empty) | Minimum zoom level for pmtiles extract |
| `MAX_ZOOM` | (empty) | Maximum zoom level for pmtiles extract |
| `UPLOAD_HOST` | `pod@pod.local:/home/pod/x-24b/data` | Upload destination for rsync |

## Scripts

### `extract_region.sh`

Main script that handles the complete pipeline:

1. Fetches country relations from Overpass API
2. Auto-detects and converts OSM JSON to GeoJSON if needed
3. Normalizes with ogr2ogr (if available)
4. Dissolves features into a single MultiPolygon
5. Optionally simplifies geometry
6. Optionally runs pmtiles extract

**Usage:**
```bash
./extract_region.sh                    # Generate GeoJSON only
./extract_region.sh OUTPUT.pmtiles     # Generate GeoJSON and extract pmtiles
```

## Output Files

- `REGION.geojson` - Final combined MultiPolygon region
- `region_osm.json` / `region_maybe_geojson.json` - Intermediate Overpass response
- `region_clean.geojson` / `region_raw.geojson` - Intermediate normalized GeoJSON

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
TIMEOUT=120 ./extract_region.sh
```

Alternatively, use a different Overpass server that may have better availability.

### Validation

After generating `REGION.geojson`, validate the output:

```bash
# Check feature count and geometry type
jq '.features | length' REGION.geojson
jq '.features[0].geometry.type' REGION.geojson

# Visualize in a web browser
# Upload to https://geojson.io or use QGIS
```

## Examples

### Example 1: Basic GeoJSON Generation

```bash
./extract_region.sh
# Output: REGION.geojson
```

### Example 2: Extract with Default Settings

```bash
./extract_region.sh pm11.pmtiles
# Output: REGION.geojson, pm11.pmtiles
```

### Example 3: Low-Zoom Basemap with Simplification

```bash
SIMPLIFY_PCT=2 MIN_ZOOM=0 MAX_ZOOM=8 ./extract_region.sh lowzoom_countries.pmtiles
```

### Example 4: Using Local PMTiles

```bash
# Download first
curl -o basemap.pmtiles https://tunnel.optgeo.org/protomaps-basemap.pmtiles

# Extract
PMTILES_URL=basemap.pmtiles ./extract_region.sh output.pmtiles
```

### Example 5: Using Makefile

```bash
# Extract with custom settings
SIMPLIFY_PCT=1 make extract OUTPUT=simplified_countries.pmtiles

# Upload to remote server
make upload OUTPUT=simplified_countries.pmtiles

# Clean up
make clean
```

## Testing

To test the scripts without creating output pmtiles (just verify GeoJSON generation):

```bash
# Run GeoJSON generation only
./extract_region.sh

# Check output
ls -lh REGION.geojson
jq '.features[0].geometry.type' REGION.geojson
```

Expected output:

- File `REGION.geojson` exists
- Geometry type is `MultiPolygon`
- Feature count is 1 (all countries dissolved into one)

## Troubleshooting

### Error: "npx not found"

Install Node.js: `brew install node` (macOS) or `apt-get install nodejs npm` (Ubuntu)

### Error: "pmtiles CLI not found"

Install pmtiles: `npm install -g pmtiles` or download from [go-pmtiles releases](https://github.com/protomaps/go-pmtiles/releases)

### Error: "Overpass returned no data"

- Increase timeout: `TIMEOUT=120 ./extract_region.sh`
- Try a different Overpass server
- Check if the country name regex needs adjustment

### Warning: Small islands missing after simplification"

- Reduce `SIMPLIFY_PCT` to 0 or 1
- Use the `keep-shapes` option (already included in scripts)
- Manually verify output with QGIS or geojson.io

## Building the Demo Site

The demo site is built using Vite and can be rebuilt with:

```bash
# Install dependencies
npm install

# Build for production (output goes to /docs folder)
npm run build

# Preview locally
npm run preview
```

The build configuration ensures that output files have no hash in their names:
- `docs/index.html` - Main HTML file
- `docs/index.js` - Bundled JavaScript with MapLibre GL JS and PMTiles support

The `PMTILES_URL` constant in `src/main.js` can be modified to point to different PMTiles sources.

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
