.PHONY: geojson extract clean help

# Default target
help:
	@echo "PM11 - PMTiles extraction for 11 countries"
	@echo ""
	@echo "Available targets:"
	@echo "  make geojson              - Generate combined_countries.geojson from Overpass API"
	@echo "  make extract OUTPUT=file  - Extract pmtiles using combined_countries.geojson"
	@echo "  make clean                - Remove generated files"
	@echo ""
	@echo "Examples:"
	@echo "  make geojson"
	@echo "  make extract OUTPUT=protomaps_countries.pmtiles"
	@echo "  SIMPLIFY_PCT=2 make geojson"
	@echo "  MIN_ZOOM=0 MAX_ZOOM=8 make extract OUTPUT=countries_z0-8.pmtiles"
	@echo ""
	@echo "Environment variables:"
	@echo "  PMTILES_URL    - Source pmtiles URL (default: https://tunnel.optgeo.org/protomaps-basemap.pmtiles)"
	@echo "  OVERPASS_URL   - Overpass API endpoint (default: https://overpass-api.de/api/interpreter)"
	@echo "  TIMEOUT        - Overpass timeout in seconds (default: 60)"
	@echo "  SIMPLIFY_PCT   - Simplification percentage for mapshaper (default: 0, no simplification)"
	@echo "  MIN_ZOOM       - Minimum zoom level for extraction (optional)"
	@echo "  MAX_ZOOM       - Maximum zoom level for extraction (optional)"

# Generate combined_countries.geojson
geojson:
	./run_all.sh

# Extract pmtiles (requires OUTPUT variable)
extract:
	@if [ -z "$(OUTPUT)" ]; then \
		echo "ERROR: OUTPUT variable required. Usage: make extract OUTPUT=output.pmtiles"; \
		exit 1; \
	fi
	./run_all.sh "$(OUTPUT)"

# Clean generated files
clean:
	rm -f combined_countries.geojson countries_osm.json countries_maybe_geojson.json countries_clean.geojson countries_raw.geojson
	@echo "Cleaned up generated files"
