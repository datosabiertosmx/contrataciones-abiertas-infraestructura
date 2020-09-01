(function() {
    const {geocoding, styles} = mapboxSdk({ accessToken: MAPBOX_TOKEN });
    let addresResults,
        map,
        marker;
    
    /**
     * Buscar direcciones
     * @param {String} address Direccion a buscar
     */
    let findAddress = async address => {
        return await geocoding.forwardGeocode({
            query: address,
            limit: 5,
            countries: ['mx'],
            language: ['es'],
            types: ['address']
          })
          .send();
    }

    /**
     * Buscar direccion por coordenada
     * @param {Array} coord Coordenadas a buscar
     */
    let findAddressByCoord = async coord => {
        return await geocoding.reverseGeocode({
            query: coord,
            limit: 1,
            countries: ['mx'],
            language: ['es']
          })
          .send();
    }

    /**
     * Cargar el mapa
     */
    let initMap = () => {
        mapboxgl.accessToken = MAPBOX_TOKEN;
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/streets-v9',
            center: [-102.552784,  23.634501],
            zoom: 4
        });

        /**
         * Agregar pin al dar clic en mapa y buscar direccion
         */
        map.on('click', async evt => {
            addMarker(evt.lngLat);
            let results = await findAddressByCoord([evt.lngLat.lng,evt.lngLat.lat]);
            if(results.body.features) selectResult(results.body.features[0]);
        });

        let lnglat = { 
            lng: parseFloat($('[name="longitude"]').val()),
            lat: parseFloat($('[name="latitude"]').val())
        };

        
        if(!isNaN(lnglat.lng)) {
            addMarker(lnglat);
        }
    }

    /**
     * Agregar un pin en el mapa y hacer zoom
     * @param {Object} lnglat Latitud y longitud
     */
    let addMarker = lnglat => {
        marker = marker || new mapboxgl.Marker().setLngLat(lnglat).addTo(map);
        marker.setLngLat(lnglat);
        map.setCenter([lnglat.lng, lnglat.lat]);
        map.setZoom(16);
    }

    /**
     * Despliega la lista de resultado de direcciones
     */
    let displayResultsAddress = () => {
        let $ul = $('.map-geocoding-result').empty();

        if(!addresResults) {
            $ul.append('<li class="list-group-item text-center">No se han encontrado resultados</>');
            marker.remove();
            marker = undefined;
        } else {
            addresResults.map(a =>{
                $(`<li class="list-group-item"><a href="javascript:void(0)">${a.place_name_es || a.place_name}</a></li>`)
                .click(function(){
                    selectResult(a);
                    addMarker({lng: a.center[0], lat: a.center[1]});
                    $ul.empty();
                })
                .appendTo($ul);
            } );
        }
    }

    /**
     * Seleccionar direccion para establecer los datos que se van a guardar
     * @param {Object} feature Direccion seleccionada
     */
    let selectResult = feature => {
        console.log(feature);
        $('.map-geocoding input').val(feature.place_name);
        $('[name="longitude"]').val(feature.center[0]);
        $('[name="latitude"]').val(feature.center[1]);
        $('[name="location_postalcode"]').val(feature.context.filter(x => x.id.startsWith('postcode')).map(x => x.text_es || x.text)[0]);
        $('[name="location_countryname"]').val(feature.context.filter(x => x.id.startsWith('country')).map(x => x.text_es || x.text)[0]);
        $('[name="location_streetaddress"]').val(feature.text_es || a.text);
        $('[name="location_region"]').val(feature.context.filter(x => x.id.startsWith('region')).map(x => x.text_es || x.text)[0]);
        $('[name="location_locality"]').val(feature.context.filter(x => x.id.startsWith('place')).map(x => x.text_es || x.text)[0]);

        if($('[name="location_postalcode"]').val() !== ''){
            $('[name="location_postalcode"]').parent().addClass('hide');
        } else {
            $('[name="location_postalcode"]').parent().removeClass('hide');
        }
    }
    
    /**
     * Ejecutar la busqueda de direcciones
     */
    $('#btnGeocoding').click(async function(){
        let address = $('.map-geocoding input').val();
        if(!address) return;
        addresResults = (await findAddress(address)).body.features;
        displayResultsAddress();
    });

    setTimeout(initMap, 500);
})();
