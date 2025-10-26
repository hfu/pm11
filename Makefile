.PHONY: geojson extract upload clean help

# Default target
help:
	@echo "PM11 - PMTiles extraction for 11 countries"
	@echo ""
	@echo "Available targets:"
	@echo "  make geojson              - Generate REGION.geojson from Overpass API"
	@echo "  make extract OUTPUT=file  - Extract pmtiles using REGION.geojson"
	@echo "  make upload OUTPUT=file   - Upload pmtiles to remote server"
	@echo "  make clean                - Remove generated files"
	@echo ""
	@echo "Examples:"
	@echo "  make geojson"
	@echo "  make extract OUTPUT=pm11.pmtiles"
	@echo "  make upload OUTPUT=pm11.pmtiles"
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
	@echo "  UPLOAD_HOST    - Upload destination (default: pod@pod.local:/home/pod/x-24b/data)"

# Generate REGION.geojson
geojson:
	./extract_region.sh

# Extract pmtiles (requires OUTPUT variable)
extract:
	@if [ -z "$(OUTPUT)" ]; then \
		echo "ERROR: OUTPUT variable required. Usage: make extract OUTPUT=output.pmtiles"; \
		exit 1; \
	fi
	./extract_region.sh "$(OUTPUT)"

# Upload pmtiles to remote server (requires OUTPUT variable)
upload:
	@if [ -z "$(OUTPUT)" ]; then \
		echo "ERROR: OUTPUT variable required. Usage: make upload OUTPUT=output.pmtiles"; \
		exit 1; \
	fi
	@if [ ! -f "$(OUTPUT)" ]; then \
		echo "ERROR: File $(OUTPUT) does not exist. Please create it first with 'make extract OUTPUT=$(OUTPUT)'"; \
		exit 1; \
	fi
	@UPLOAD_HOST=$${UPLOAD_HOST:-pod@pod.local:/home/pod/x-24b/data}; \
	case "$(OUTPUT)" in \
		*[!A-Za-z0-9._-]*) echo "ERROR: OUTPUT contains invalid characters. Allowed: A-Za-z0-9._-"; exit 1;; \
		"") echo "ERROR: OUTPUT is empty."; exit 1;; \
	esac; \
	echo "Uploading $(OUTPUT) to $${UPLOAD_HOST}..."; \
	rsync -av --progress "$(OUTPUT)" "$${UPLOAD_HOST}"
	@echo "Upload complete."

# Clean generated files
clean:
	rm -f REGION.geojson region_osm.json region_maybe_geojson.json region_clean.geojson region_raw.geojson
	@echo "Cleaned up generated files"
