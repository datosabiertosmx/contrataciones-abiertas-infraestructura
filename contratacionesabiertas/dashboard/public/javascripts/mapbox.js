
let map,
    marker;


/**
 * Cargar el mapa
 */
var initMap = () => {
    mapboxgl.accessToken = MAPBOX_TOKEN;
    map = map || new mapboxgl.Map({
        container: 'map',
        style: 'mapbox://styles/mapbox/streets-v11',
        center: [-102.552784,  23.634501],
        zoom: 4
    });
}

/**
 * Agregar un pin en el mapa y hacer zoom
 * @param {Object} lnglat Latitud y longitud
 */
var addMarker = lnglat => {
    marker = marker || new mapboxgl.Marker();
    marker.setLngLat(lnglat);
    marker.addTo(map);
    map.setCenter([lnglat.lng, lnglat.lat]);
    map.setZoom(16);
}


