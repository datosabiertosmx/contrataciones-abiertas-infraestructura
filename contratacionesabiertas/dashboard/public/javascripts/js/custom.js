var initialise_form = function(selectionOptions) {
    var filtroSeleccionado = ""; 
     var filterers = $('.filter_block input');
     filterers.change(function() {
         
         var filters = [];
         var targets = [];
         filterers.filter(function() {
             return !this.checked
         }).each(function(k, v) {
              filters[k] = v.value;
              targets[k] = $(v).data('target');
         });
         use_filters(filters, targets);
     });

    var groupSelect = $('#group-everything-by');
    for (var opt in selectionOptions) {
        var lookup = selectionOptions[opt];
        if (lookup.title != 'Proveedor' && lookup.title != 'Área requirente' ) {
            groupSelect.append('<option value="' + lookup.key + '">' + lookup.title + '</option>');
        }
    }
    var ResetGrouping = function() {
        var groupBy = groupSelect.val();
        group_by(groupBy);
    };
    groupSelect.change(ResetGrouping);
    var colorSelect = $('#color-everything-by');
    for (var opt in selectionOptions) {
        var lookup = selectionOptions[opt];
        colorSelect.append('<option value="' + lookup.key + '">' + lookup.title + '</option>');
    }
    var ResetColors = function() {
        var colorBy = colorSelect.val();
        color_by(colorBy);
    };
    $('.clear').change(function(data) {
        if (data.currentTarget.id == "clear_filters"){
            if ($(this).hasClass('select')) {
                $('.filter_block input').prop('checked', 'checked');
            } else {
                $('.filter_block input').prop('checked', false);
            }
        }else{
            var claseCambio = data.currentTarget.id;
            if ($(this).hasClass('select')) { 
                if (claseCambio == "cProveedor"){
                    $('.cProveedor').prop('checked','checked');
                }else if (claseCambio == "cProcedimiento"){
                    $('.cProcedimiento').prop('checked','checked');
                }else if (claseCambio == "cDestino"){ 
                    $('.cDestino').prop('checked','checked');
                }else if (claseCambio.includes("rea")){
                    $('.cArea').prop('checked','checked');
                }else if (claseCambio == "cVigencia"){
                    $('.cVigencia').prop('checked','checked');
                } 
            } else {
                if (claseCambio == "cProveedor"){
                    $('.cProveedor').prop('checked',false);
                }else if (claseCambio == "cProcedimiento"){
                    $('.cProcedimiento').prop('checked',false);
                }else if (claseCambio == "cDestino"){  
                    $('.cDestino').prop('checked',false);
                }else if (claseCambio.includes("rea")){
                    $('.cArea').prop('checked',false);
                }else if (claseCambio == "cVigencia"){
                    $('.cVigencia').prop('checked',false);
                }	
            }
        }
        $(this).toggleClass('select clear');
        filtroSeleccionado = data.currentTarget.id; 
        filterers.change();
        return false;
    });
    colorSelect.change(ResetColors);
};

$('#filtros').on({
    "click":function(e){
        e.stopPropagation();
    }
});

function get_distinct_values(data, keyType, key) {
    var allValues = {};
    for (var i in data) {
        var value = data[i][key];
        allValues[value] = true;
    }
    var allValuesArray = [];
    for (var i in allValues) allValuesArray.push(i);
    allValuesArray.sort();
    return allValuesArray
}

function keyToLookup(key) {
    var firstPartEnds = key.indexOf(':');
    if (firstPartEnds <= 0) return {
        key: key,
        type: key,
        title: key
    };
    var firstPart = key.substring(0, firstPartEnds);
    var secondPart = key.substring(firstPartEnds + 1);
    return {
        key: key,
        type: firstPart,
        title: secondPart
    };
}

function render_filters_colors_and_groups(data) {
    var first = data[0];

    var lookups = [];
    for (var key in first) {
        var lookup = keyToLookup(key);
        // SELECCIONA LOS CAMPOS A FILTRAR

        if (lookup.type == "Proveedor" || lookup.type == "Vigencia del contrato" || lookup.type == "Procedimiento de contratación" || lookup.type == "Destino de contratación" || lookup.type == "Área requirente"){
            lookups.push(lookup);
        }

    }

    var filterList = $('#filter-list');
    for (var i in lookups) {
        var lookup = lookups[i];
        var values = get_distinct_values (data, lookup.type, lookup.key);
        var item = $('<div class="filter_block col-md-4" style="display: inline-block; width: 19%;margin-left: 10px;"><li class="filter_title"><p style="color:#00cc99;"><strong></strong></p></li></div>');
        for (var j in values) {
            if (lookup.type.includes("rea")){
                var checkbox = $('<li class="sub-filter-block"><label style="cursor:pointer"><input style="cursor:pointer" class="cArea" data-target="' + lookup.key + '" type="checkbox" checked="checked" value="' + values[j] + '"/> ' + values[j] + '</label></li>');
            }else{
                var checkbox = $('<li class="sub-filter-block"><label style="cursor:pointer"><input style="cursor:pointer" class="c' + lookup.type + '" data-target="' + lookup.key + '" type="checkbox" checked="checked" value="' + values[j] + '"/> ' + values[j] + '</label></li>');
            }
            checkbox.appendTo(item);
        }
        item.appendTo(filterList);
    }
    initialise_form(lookups);
}

function hide_color_chart() {
    var colorbar = $('#color-hints');
    colorbar.fadeOut(500, function() {
        $(this).empty();
    });
}

function show_color_chart(what_to_color_by, color_mapper) {
    var colorbar = $('#color-hints');
    colorbar.fadeOut(500, function() {
        colorbar.empty();
        var lookup = keyToLookup(what_to_color_by);
        $('<h4>' + lookup.title + ':</h4>').appendTo(colorbar);
        var row = $('<div class="row" />');
        for (var key in color_mapper) {
            var cell = $('<div class="col-md-3" />');
            var square = $('<div style="width: 15px; height: 15px; background: ' + color_mapper[key] + ';  display: inline-block; vertical-align: middle;">&nbsp;</div><p style="display: inline;"> '+ key +' </p>');
            square.appendTo(cell);
            cell.appendTo(row);
            cell.appendTo(row);
        }
        row.appendTo(colorbar);
        colorbar.fadeIn(500);
    });
}