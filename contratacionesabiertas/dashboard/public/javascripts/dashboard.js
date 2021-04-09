$(document).ready(function () {
    // DONUT CHARTs
    var ff= $.jqplot;

    function donutChart1() {
        $.post('/contratacionesabiertas/donut-chart-data', {
            year: $('#metadataYear').val(),
        }, function (data) {

            var newData = [];

            var colors = [];

            if (data.length > 0) {
                for (var i = 0; i < data.length; i++) {
                    newData.push([data[i].procurementmethod_details, Number(data [i].sum), data[i].percentage, data[i].conteo]);
                    switch (data[i].procurementmethod_details) {
                        case 'Adjudicación directa':
                            colors.push('#00cc99');
                            break;
                        case 'Invitación a cuando menos tres personas':
                            colors.push('#663399');
                            break;
                        case 'Licitación pública':
                            colors.push('#ffcc00');
                            break;
                    }
                }
            } else {
                return;
            }

            var plot4 = ff('chart4', [newData], {
                //title: 'TIPOS DE CONTRATACION',
                seriesDefaults: {
                    // make this a donut chart.
                    renderer: $.jqplot.DonutRenderer,
                    rendererOptions: {
                        // Donut's can be cut into slices like pies.
                        sliceMargin: 0,
                        // Pies and donuts can start at any arbitrary angle.
                        startAngle: -90,
                        showDataLabels: true,
                        dataLabelFormatString: '%.1f%',
                        // By default, data labels show the percentage of the donut/pie.
                        // You can show the data 'value' or data 'label' instead.
                        //dataLabels: 'value',
                        // "totalLabel=true" uses the centre of the donut for the total amount
                        totalLabel: true,
                        shadow: false
                    },
                 // Grafica Procedimiento de la contratación
                    seriesColors: colors
                },
                grid: {
                    drawBorder: false,
                    drawGridLines: true,        // wether to draw lines across the grid or not.
                    shadow: false,
                    backgroundColor: 'transparent'//'white'//'rgb(255, 255, 255)'
                },
                highlighter: {
                    show: true,

                    sizeAdjust: 1,
                    tooltipLocation: 'n',
                    tooltipAxes: 'yref',
                    useAxesFormatters: false,
                    dataLabelFormatString: '%.1f',
                    //dataLabels: 'value',
                    //tooltipFormatString: '%s'
                    tooltipContentEditor: function (current, serie, index, plot) {
                        //return "<div class='col-sm-2'><p style='color: black'><b>" + data[index][1] + " " + data[index][0] + "</b></p></div>";
                        return "<div class='col-sm-2'><p style='color: black'>" + newData[index][0] +  " (" + newData[index][2]+")" +":<br><b> $"
                            +  ( (   newData[index][1]    ).toFixed(1) ).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")  +
                                "</b><br>Número de contratos:<br><b>"+
                               newData[index][3]                            +
                            "</b></p></div>";
                    }
                }
            });
        });
    }

    function donutChart2(  ) {
		$.post('/contratacionesabiertas/donut-chart2-data', {
            year: $('#metadataYear').val(),
        }, function (data) {

            var newData = [];

            var colors = [];

            if (data.length > 0) {
                for (var i = 0; i < data.length; i++) {
                    newData.push([data[i].additionalprocurementcategories, Number(data [i].sum), data[i].percentage, data[i].conteo]);
                    switch (data[i].additionalprocurementcategories) {
                        case 'Adquisición de bienes':
                            colors.push('#00cc99');
                            break;
                        case 'Arrendamiento de bienes':
                            colors.push('#00BFFF');
                            break;
                        case 'Obras públicas':
                            colors.push('#ffcc00');
                            break;
                        case 'Servicios':
                            colors.push('#ff6600');
                            break;
                        case 'Servicios relacionados con obras públicas':
                            colors.push('#663399');
                            break;
                    }
                }
            } else {
                return;
            }
        
            var plot4 = ff('donutchart2', [newData], {
                //title: 'DESTINO DE LA CONTRATACION',
                seriesDefaults: {
                    // make this a donut chart.
                    renderer: ff.DonutRenderer,
                    rendererOptions: {
                        sliceMargin: 0,
                        startAngle: -90,
                        showDataLabels: true,
                        dataLabelFormatString: '%.1f%',
                        totalLabel: true,
                        shadow: false
                    },
                    // Grafica Destino de la contratación
                    seriesColors: colors
                },
                grid: {
                    drawBorder: false,
                    drawGridLines: true,        // wether to draw lines across the grid or not.
                    shadow: false,
                    backgroundColor: 'transparent'//'white'//'rgb(255, 255, 255)'
                },
                highlighter: {
                    show: true,

                    sizeAdjust: 1,
                    tooltipLocation: 'n',
                    tooltipAxes: 'yref',
                    useAxesFormatters: false,
                    //dataLabels: 'value',
                    //tooltipFormatString: '%s'
                    tooltipContentEditor: function (current, serie, index, plot) {
                        return "<div class='col-sm-2'><p style='color: black'>" + newData[index][0] +" ("+newData[index][2]+")" +
                            ":<br><b> $" +  ( (   newData[index][1]    ).toFixed(2) ).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")  +
                                "</b><br>Número de contratos: <br><b>"+
                                newData[index][3]+
                            "</b></p></div>";

                    }
                }
            });
        });
    }

    // Carga la grafica de procedimientos por etapa
    function stageChart() {
        $.post('/contratacionesabiertas/stage-chart-data', {
            year: $('#metadataYear').val(),
        }, function (data) {
            var interval = 1;
            data.map(x => {
                if(x.total > 50){
                    interval = 10;
                } 
            });
            var nData = [[],[],[],[],[]];
            var ticks = ['Licitación pública', 'Adjudicación directa', 'Invitación a cuando menos tres personas'];
            var chartOptions = {
                height: 450,
                stackSeries: true,
                seriesDefaults: {
                    renderer: ff.BarRenderer,
                    shadow: false,
                    rendererOptions: {
                        barDirection: 'horizontal',
                        barWidth: 20,
                        barMargin: 10
                    }
                },
                series: [
                    { label: 'Planeación', color: '#F19192' },    // Planeación    (rosa)
                    { label: 'Licitación', color: '#D6D52D' },    // Licitación    (amarillo)
                    { label: 'Adjudicación', color: '#2AA24A' },  // Adjudicación  (verde)
                    { label: 'Contratación', color: '#1F8BC5' },  // Contratación  (azul)
                    { label: 'Ejecución', color: '#79357C' },     // Ejecución     (morado)
                ],
                axes: {
                    xaxis: {
                        min: 0,
                        tickInterval: interval ,
                        tickOptions: {
                            formatString: '%d'
                        },
                        autoscale: true
                    },
                    yaxis: {
                        renderer: ff.CategoryAxisRenderer,
                        ticks: ticks,
                        tickOptions: {
                            showGridline: true, 
                            markSize: 0
                        },
                        autoscale: true
                    }
                },
                grid: {
                    drawBorder: false,
                    drawGridLines: true,
                    shadow: false,
                    backgroundColor: 'transparent'
                },
                highlighter: {
                    show: true,
                    sizeAdjust: 7.5,
                    tooltipContentEditor: function(current, serie, index, plot){
                        var serieName = plot.series[serie].label;
                        var tickName = ticks[index];
                        var val = plot.data[serie][index];
                        return '<table class="jqplot-highlighter"><tr><td>' + tickName + '</td></tr><tr><td>' + (serieName + ': <strong>' + val[0]) + '</strong></td></tr></table>';
                    }
                }
            };

            var process = data.reduce(function (rv, x) {
                (rv[x['process']] = rv[x['process']] || []).push(x);

                return rv;
            }, {});

            ticks.forEach(function (key, index) {
                for (let i = 0; i < 5; i++) {
                    var actual = $.grep(process[key] || [], function (e) { return e.stage == (i + 1); });
                    nData[i].push([actual.length > 0 ? parseInt(actual[0].total) : 0, index + 1]);
                }
            });

            var bData = $.extend(true, [], nData);
        
            var plot = ff('stages_chart', bData, chartOptions);

            function resizeHandler () {
                if (window.innerWidth < 700) {
                    chartOptions['axes']['yaxis']['ticks'] = ['LP', 'A41', 'A42', 'ER', 'I3P', 'CC', 'AM'];

                    plot.destroy();
                    plot = ff('stages_chart', bData, chartOptions);
                } else {
                    chartOptions['axes']['yaxis']['ticks'] = ['Licitación pública', 'Adjudicación directa', 'Invitación a cuando menos tres personas']; //procedimiento por etapas

                    plot.destroy();
                    plot = ff('stages_chart', bData, chartOptions);
                }
            }

            if (window.addEventListener) {
                window.addEventListener('resize', resizeHandler, false);
            }
            else if (window.attachEvent) {
                window.attachEvent('onresize', resizeHandler);
            }

            $('[data-stage]').on('click', function() {
                $(this).toggleClass('active');
                bData = $.extend(true, [], nData);

                for (var i = 0; i < bData.length; i++) {
                    if ($('[data-stage="' + i + '"]').hasClass('active')) {
                        for (var j = 0; j < bData[i].length; j++) {
                            bData[i][j][0] = 0;
                        }
                    }
                }

                plot.destroy();
                plot = ff('stages_chart', bData, chartOptions);
            });

            window.dispatchEvent(new Event('resize'));
        });
    }

    donutChart1();
    stageChart();
    //donutChart2();
    //donutChart2d3();

    var st= false;

    $('a[data-toggle="tab"]').on('shown.bs.tab', function ( e ) {
        //$('#donutchart2').html("")
        if (!st) {
            donutChart2();
            st = true;
        }
    });


    // FIND CONTRACTS
    function searchbykeyword(keyword, table, param, filter) {
        $.post('/contratacionesabiertas/find-contracts', {
            keyword: keyword,
            orderby: param,
            filter: filter
        }, function (contracts) {
            table.html(contracts);
        });
    }

//Eventos de los botones del paginador
    function p () {
        $('ul.pagination li a').click(function(e){
            $('#ctable').load('/contratacionesabiertas/pagination',{ 
                npage : $(this).data('page'), 
                keyword: $('#keyword').val(),  
                process: $('#processFilter').val(), 
                stage: $('#stageFilter').val(),
                status: $('#statusFilter').val(),
                year: $('#metadataYear').val(),
                orderby: $('#orderby').val()
            }, p);
        });
    }

    $('#ctable').load('/contratacionesabiertas/pagination', { 
        npage : 1, 
        keyword: $('#keyword').val(),  
        process: $('#processFilter').val(), 
        stage: $('#stageFilter').val(),
        status: $('#statusFilter').val(),
        year: $('#metadataYear').val(),
        orderby: $('#orderby').val() 
    }, p);

    $('#anotherkeyword').click(function () {
        $('#ctable').load('/contratacionesabiertas/pagination',{ 
            npage : 1, 
            keyword: $('#keyword').val(),  
            process: $('#processFilter').val(), 
            stage: $('#stageFilter').val(),
            status: $('#statusFilter').val(),
            year: $('#metadataYear').val(),
            orderby: $('#orderby').val() 
        }, p);
    });
    
    $('#orderby').change(function () {
        $('#ctable').load('/contratacionesabiertas/pagination',{ 
            npage : 1, 
            keyword: $('#keyword').val(),  
            process: $('#processFilter').val(), 
            stage: $('#stageFilter').val(),
            status: $('#statusFilter').val(),
            year: $('#metadataYear').val(),
            orderby: $('#orderby').val() 
        }, p);
    });

    // Filtro de proceso
    $('#processFilter').change(function () {
        $('#ctable').load('/contratacionesabiertas/pagination',{ 
            npage : 1, 
            keyword: $('#keyword').val(),  
            process: $('#processFilter').val(), 
            stage: $('#stageFilter').val(),
            status: $('#statusFilter').val(),
            year: $('#metadataYear').val(),
            orderby: $('#orderby').val() 
        }, p);
    });

    // Filtro de etapa
    $('#stageFilter').change(function () {
        $('#statusFilter').empty();

        switch($('option:selected', this).val()) {
            case '2':
                $('#statusFilter').html(`
                    <option value="">Estatus de la etapa</option>
                    <option value="planning">En planeación</option>
                    <option value="planned">Planeada</option>
                    <option value="active">Activa</option>
                    <option value="cancelled">Cancelada</option>
                    <option value="unsuccessful">No exitosa</option>
                    <option value="complete">Concluida</option>
                    <option value="withdrawn">Retirada</option>
                `);
                break;
            case '3':
                $('#statusFilter').html(`
                    <option value="">Estatus de la etapa</option>
                    <option value="pending">Pendiente</option>
                    <option value="active">Activo</option>
                    <option value="cancelled">Cancelado</option>
                    <option value="unsuccessful">No exitoso</option>
                `);
                break;
            case '4':
                $('#statusFilter').html(`
                    <option value="">Estatus de la etapa</option>
                    <option value="pending">Pendiente</option>
                    <option value="active">Activo</option>
                    <option value="cancelled">Cancelado</option>
                    <option value="terminated">Terminado</option>
                `);
                break;
            case '5':
                $('#statusFilter').html(`
                    <option value="">Estatus de la etapa</option>
                    <option value="planning">En planeación</option>
                    <option value="ongoing">En progreso</option>
                    <option value="concluded">En finiquito</option>
                `);
                break;
            default:
                $('#statusFilter').html('<option value="">Estatus de la etapa</option>');
                break;
        }

        $('#statusFilter').selectpicker('refresh');

        $('#ctable').load('/contratacionesabiertas/pagination',{ 
            npage : 1, 
            keyword: $('#keyword').val(),  
            process: $('#processFilter').val(), 
            stage: $('#stageFilter').val(),
            status: $('#statusFilter').val(),
            year: $('#metadataYear').val(),
            orderby: $('#orderby').val() 
        }, p);
    });

    // Filtro de estatus
    $('#statusFilter').change(function () {
        $('#ctable').load('/contratacionesabiertas/pagination',{ 
            npage : 1, 
            keyword: $('#keyword').val(),  
            process: $('#processFilter').val(), 
            stage: $('#stageFilter').val(),
            status: $('#statusFilter').val(),
            year: $('#metadataYear').val(),
            orderby: $('#orderby').val() 
        }, p);
    });

    $('#yearFilter').change(function () {
        window.location.href = "/contratacionesabiertas/contratos/" + $('option:selected', this).val();
    });
});


// BUBBLE CHART (GCHART)
google.charts.load('current', {'packages': ['corechart'], 'language': 'es'});
google.charts.setOnLoadCallback(drawSeriesChart);

function drawSeriesChart() {

    $.post('/contratacionesabiertas/bubble-chart-data', {
        year: $('#metadataYear').val(),
    }, function (data) {

        var newData = [['ID', 'Fecha de firma', 'Vigencia (días naturales)', 'Tipo', 'Monto MXN']];
        var minDate, maxDate, min, max;

        minDate = new Date(Math.min.apply(Math, data.map(function(o) { return new Date(o.datesigned).getTime(); })));
        maxDate = new Date(Math.max.apply(Math, data.map(function(o) { return new Date(o.datesigned).getTime(); })));
        min = Math.min.apply(Math, data.map(function(o) { return Math.abs(o.vigencia.days); }));
        max = Math.max.apply(Math, data.map(function(o) { return Math.abs(o.vigencia.days); }));

        min = 0;
        max = max + 10;
        minDate = new Date(minDate.getFullYear() - 1, minDate.getMonth(), minDate.getDate());
        maxDate = new Date(maxDate.getFullYear() + 1, maxDate.getMonth(), maxDate.getDate());

        if (data.length > 0) {
            for (i = 0; i < data.length; i++) {
                newData.push([ data[i].title , new Date(data[i].datesigned), Math.abs(data[i].vigencia.days), data[i].procurementmethod_details, Number(data[i].exchangerate_amount)]);
            }
        } else {
            return;
        }

        var options = {
            //'legend': 'left',
            //title: 'Contrataciones en el tiempo',
            //sortBubblesBySize: false,
            chartArea: {
            	width: '100%',
                heigth: '100%',
                left: '55',
                right: '30',
                top: '10',
                bottom: '80'
            },
            backgroundColor: 'transparent',
            tooltip: {isHtml: true},

            hAxis: {
                //maxValue: new Date(2017, 2, 2),
                //minValue: new Date(2013, 9, 9),
                viewWindow: {
                    min: minDate,
                    max: maxDate
                },
                title: 'Fecha de firma',
                textStyle: {
                    italic: false,
                    fontName: 'Open Sans',
                    fontSize: '11pt'
                },
                titleTextStyle: {
                    italic: false,
                    fontName: 'Open Sans',
                    fontSize: '14pt'
                },
                gridlines: {
                    color: 'transparent'
                }

            },
            vAxis: {
                //maxValue: 1800,
                //minValue: -100,
                viewWindow: {
                    min: min,
                    max: max
                },
                scaleType: 'log',
                title: 'Vigencia en días naturales',
                textStyle: {
                    italic: false,
                    fontName: 'Open Sans',
                    fontSize: '11pt'
                },
                titleTextStyle: {
                    italic: false,
                    fontName: 'Open Sans',
                    fontSize: '14pt'
                }
                /*gridlines: {
                 color: 'transparent'
                 }*/
            },
            bubble: {
                stroke: 'none',
                textStyle: {
                    //no text
                    color: 'none',
                    fontSize: 11,
                    auraColor: 'none'
                }
            },
            series: {
          // Gráfica Contrataciones en el tiempo
            	'Adjudicación directa': {color: '#00cc99'},
                'Invitación a cuando menos tres personas': {color: '#663399'},
                'Licitación pública': {color: '#ffcc00'}                
            },
            legend: {
                textStyle: {
                	fontName: 'Open Sans',
                	fontSize: 16   //tamaño de la letra de los tipos de procedimiento
                }
            }
        };

        var chart = new google.visualization.BubbleChart(document.getElementById('series_chart_div'));


        //evento para dirigir al detalle del contrato
         function selectHandler() {
             var selectedItem = chart.getSelection()[0];
             window.open(href = '/contratacionesabiertas/contrato/'+(data[selectedItem.row].id)+'/implementacion');

         }
        
        google.visualization.events.addListener(chart, 'select', selectHandler);
        
        //chart.draw( data  , options);

        var dt = google.visualization.arrayToDataTable(newData);
        chart.draw(dt/*google.visualization.arrayToDataTable(newData)*/, options);

        var formatter = new google.visualization.NumberFormat(
            {prefix: '$', negativeColor: 'red', negativeParens: true, decimalSymbol: '.', groupingSymbol: ','});
        formatter.format(dt, 4); // Apply formatter to second column

        var formatter1 = new google.visualization.NumberFormat(
            {negativeColor: 'red', fractionDigits: 0, negativeParens: true, decimalSymbol: '.', groupingSymbol: ','});
        formatter1.format(dt, 2); // Apply formatter to second column


        function resizeHandler () {
            chart.draw(/*google.visualization.arrayToDataTable(newData)*/dt, options);
        }

        if (window.addEventListener) {
            window.addEventListener('resize', resizeHandler, false);
        }
        else if (window.attachEvent) {
            window.attachEvent('onresize', resizeHandler);
        }

    });
}





