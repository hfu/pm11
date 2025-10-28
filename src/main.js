import maplibregl from 'maplibre-gl';
import { Protocol } from 'pmtiles';
import './index.css';

// PMTiles URL configuration
const PMTILES_URL = 'https://tunnel.optgeo.org/pm11.pmtiles';

// Register PMTiles protocol
let protocol = new Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile);

// Create the style configuration similar to autopilot
const style = {
  "version": 8,
  "sources": {
    "pm11": {
      "type": "vector",
      "attribution": "<a href=\"https://github.com/protomaps/basemaps\">Protomaps</a> © <a href=\"https://openstreetmap.org\">OpenStreetMap</a>",
      "url": `pmtiles://${PMTILES_URL}`
    }
  },
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": {
        "background-color": "#cccccc"
      }
    },
    {
      "id": "earth",
      "type": "fill",
      "filter": ["==", "$type", "Polygon"],
      "source": "pm11",
      "source-layer": "earth",
      "paint": {
        "fill-color": "#e2dfda"
      }
    },
    {
      "id": "landcover",
      "type": "fill",
      "source": "pm11",
      "source-layer": "landcover",
      "paint": {
        "fill-color": [
          "match",
          ["get", "kind"],
          "grassland", "rgba(210, 239, 207, 1)",
          "barren", "rgba(255, 243, 215, 1)",
          "urban_area", "rgba(230, 230, 230, 1)",
          "farmland", "rgba(216, 239, 210, 1)",
          "glacier", "rgba(255, 255, 255, 1)",
          "scrub", "rgba(234, 239, 210, 1)",
          "rgba(196, 231, 210, 1)"
        ],
        "fill-opacity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          5, 1,
          7, 0
        ]
      }
    },
    {
      "id": "landuse_park",
      "type": "fill",
      "source": "pm11",
      "source-layer": "landuse",
      "filter": [
        "in",
        "kind",
        "national_park",
        "park",
        "cemetery",
        "protected_area",
        "nature_reserve",
        "forest",
        "golf_course"
      ],
      "paint": {
        "fill-color": "#9cd3b4",
        "fill-opacity": [
          "interpolate",
          ["linear"],
          ["zoom"],
          6, 0,
          11, 1
        ]
      }
    },
    {
      "id": "water",
      "type": "fill",
      "filter": ["==", "$type", "Polygon"],
      "source": "pm11",
      "source-layer": "water",
      "paint": {
        "fill-color": "#80deea"
      }
    },
    {
      "id": "water_river",
      "type": "line",
      "source": "pm11",
      "source-layer": "water",
      "minzoom": 9,
      "filter": ["in", "kind", "river"],
      "paint": {
        "line-color": "#80deea",
        "line-width": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          9, 0,
          9.5, 1,
          18, 12
        ]
      }
    },
    {
      "id": "buildings",
      "type": "fill",
      "source": "pm11",
      "source-layer": "buildings",
      "filter": ["in", "kind", "building", "building_part"],
      "paint": {
        "fill-color": "#cccccc",
        "fill-opacity": 0.5
      }
    },
    {
      "id": "roads_other",
      "type": "line",
      "source": "pm11",
      "source-layer": "roads",
      "filter": [
        "all",
        ["!has", "is_tunnel"],
        ["!has", "is_bridge"],
        ["in", "kind", "other", "path"]
      ],
      "paint": {
        "line-color": "#ebebeb",
        "line-dasharray": [3, 1],
        "line-width": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          14, 0,
          20, 7
        ]
      }
    },
    {
      "id": "roads_minor",
      "type": "line",
      "source": "pm11",
      "source-layer": "roads",
      "filter": [
        "all",
        ["!has", "is_tunnel"],
        ["!has", "is_bridge"],
        ["==", "kind", "minor_road"]
      ],
      "paint": {
        "line-color": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          11, "#ebebeb",
          16, "#ffffff"
        ],
        "line-width": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          11, 0,
          12.5, 0.5,
          15, 2,
          18, 11
        ]
      }
    },
    {
      "id": "roads_major",
      "type": "line",
      "source": "pm11",
      "source-layer": "roads",
      "filter": [
        "all",
        ["!has", "is_tunnel"],
        ["!has", "is_bridge"],
        ["==", "kind", "major_road"]
      ],
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          6, 0,
          12, 1.6,
          15, 3,
          18, 13
        ]
      }
    },
    {
      "id": "roads_highway",
      "type": "line",
      "source": "pm11",
      "source-layer": "roads",
      "filter": [
        "all",
        ["!has", "is_tunnel"],
        ["!has", "is_bridge"],
        ["==", "kind", "highway"],
        ["!has", "is_link"]
      ],
      "paint": {
        "line-color": "#ffffff",
        "line-width": [
          "interpolate",
          ["exponential", 1.6],
          ["zoom"],
          3, 0,
          6, 1.1,
          12, 1.6,
          15, 5,
          18, 15
        ]
      }
    },
    {
      "id": "boundaries_country",
      "type": "line",
      "source": "pm11",
      "source-layer": "boundaries",
      "filter": ["<=", "kind_detail", 2],
      "paint": {
        "line-color": "#adadad",
        "line-width": 0.7,
        "line-dasharray": [2, 1]
      }
    },
    {
      "id": "places_locality",
      "type": "symbol",
      "source": "pm11",
      "source-layer": "places",
      "filter": ["==", "kind", "locality"],
      "layout": {
        "text-field": ["get", "name:en"],
        "text-font": ["Noto Sans Regular"],
        "text-size": [
          "interpolate",
          ["linear"],
          ["zoom"],
          2, 10,
          10, 20
        ]
      },
      "paint": {
        "text-color": "#5c5c5c",
        "text-halo-color": "#e0e0e0",
        "text-halo-width": 1
      }
    }
  ],
  "sprite": "https://protomaps.github.io/basemaps-assets/sprites/v4/light",
  "glyphs": "https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf"
};

// Initialize the map
const map = new maplibregl.Map({
  container: 'map',
  style: style,
  center: [0, 20],
  zoom: 2,
  hash: true
});

// Add navigation controls
map.addControl(new maplibregl.NavigationControl(), 'top-right');

// Add globe control (requires MapLibre GL JS v5+)
map.addControl(new maplibregl.GlobeControl(), 'top-right');

// Add geolocation control
map.addControl(
  new maplibregl.GeolocateControl({
    positionOptions: {
      enableHighAccuracy: true
    },
    trackUserLocation: true
  }),
  'top-right'
);
