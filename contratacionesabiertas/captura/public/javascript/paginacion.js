// Clase Paginación
var Paginacion = function (config) {

    /*      PROPIEDADES
    ********************************************/
    var content = Object();
    var currentPage = Number();
    var pageSize = Number();
    var maxPageSize = Number();
    var totalRegs = Number();
    var totalPages = Number();
    var search = Function();
    var info = Boolean();
    var numbers = Number();


    /*      INICIALIZACION
    ********************************************/
    this.initPage = function (config) {

        var options = {
            // Contenedor del objeto
            content: '',
            // Función de búsqueda (No usar función que requería parámetros)
            search: function () { },
            // Pagina Actual
            currentPage: 1,
            // Tamaño de la pagina
            pageSize: 10,
            //  Numero de registros
            totalRegs: 0,
            // Indica si se mostrara información sobre las paginas
            info: false,
            // Indica si los botones se mostraran con números
            visibleNumbers: false,
            // Si visibleNumbers es true, mostrara un numero de botones (para estética debe ser un numero impar mayor a 1)
            numbers: 3,
            // Numero maximo de registros a mostrar por pagina
            maxPageSize: null
        }

        $.extend(options, config);

        setContent(options.content);
        setSearch(options.search);
        setTotalRegs(options.totalRegs);
        setPageSize(options.pageSize);
        setTotalPages(totalRegs, pageSize);
        setCurrentPage(options.currentPage);
        setMaxPageSize(options.maxPageSize);

        if (options.info != undefined)
            setInfo(options.info);
        if (options.visibleNumbers == true)
            setNumbers(options.numbers);

        createControls();
        if (info == true) createInfo();

    }




    /*      GETS Y SETS
    ********************************************/
    this.getCurrentPage = function () {
        return currentPage - 1;
    }

    this.getPageSize = function () {
        return pageSize;
    }

    var setContent = function (cont) {
        content = cont;
    }

    var setCurrentPage = function (page) {
        currentPage = parseInt(page <= 0 ? 1 : page > totalPages ? totalPages : page);
    }

    var setPageSize = function (size) {
        pageSize = parseInt(maxPageSize != null && maxPageSize > 0 && size > maxPageSize ? maxPageSize : size);
    }

    var setTotalPages = function (regs, size) {
        if (regs == 0)
            totalPages = parseInt(size);
        else
            totalPages = regs == 1 ? 1 : parseInt(regs % size == 0 ? regs / size: (regs / size) + 1);


    }

    var setTotalRegs = function (total) {
        totalRegs = parseInt(total < 0 ? 1 : total);
    }

    var setSearch = function (s) {
        search = s;
    }

    var setInfo = function (inf) {
        info = inf;
    }

    var setMaxPageSize = function (max) {
        maxPageSize = max;
    }

    var setNumbers = function (n) {
        numbers = n <= 3 ? 3 : n > totalPages ? totalPages : n;
    }


    /*      CONTROL DE BOTONES
    ********************************************/
    var firstPage = function () {
        setCurrentPage(1);
        search();
    }

    var prevPage = function () {
        setCurrentPage(currentPage - 1);
        search();
    }

    var nextPage = function () {
        setCurrentPage(currentPage + 1);
        search();
    }

    var lastPage = function () {
        setCurrentPage(totalPages);
        search();
    }

    var gotoPage = function (page) {
        setCurrentPage(page);
        search();
    }

    this.reset = function () {
        setCurrentPage(1);
        setTotalPages(totalRegs, pageSize);
    }

    /*      ACTUALIZACION DE LOS CONTROLES
    ********************************************/
    this.updateControls = function (total) {
        setTotalRegs(total);
        setPageSize(pageSize);
        setTotalPages(totalRegs, pageSize);
        setCurrentPage(currentPage);
        createControls();

        if (info == true) createInfo();

    }


    /*      CREACION DE BOTONES
    ********************************************/
    var createControls = function () {

        if (totalRegs == 0) return;

        // Ver si ya existe el contenedor de los controles
        if ($(content).children('controls').length > 0) {
            updateData();
        } else {
            var controls = $('<controls class="btn-group"></controls>');
            controls.appendTo($(content));
            if (numbers > 0)
                numberControls(controls);
            else
                basicControls(controls);

        }
    }

    var basicControls = function (controls) {
        $('<input type="button" />')
            .attr('id', 'firstPage')
            .val('<<')
            .click(firstPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);

        $('<input type="button" />')
            .attr('id', 'prevPage')
            .val('<')
            .click(prevPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);

        $('<input type="button" />')
            .attr('id', 'nextPage')
            .val('>')
            .click(nextPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);

        $('<input type="button" />')
            .attr('id', 'firstLast')
            .val('>>')
            .click(lastPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);

    }

    var numberControls = function (controls) {

        $('<input type="button" />')
            .attr('id', 'firstPage')
            .val(1)
            .click(firstPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);

        for (var i = 1; i <= numbers; i++) {
            $('<input type="button" />')
                .val(i + 1)
                .click(function () { gotoPage($(this).val()) })
                .addClass('btn btn-default btn-xs')
                .appendTo(controls);
        }

        $('<input type="button" />')
            .attr('id', 'lastPage')
            .val(totalPages)
            .click(lastPage)
            .addClass('btn btn-default btn-xs')
            .appendTo(controls);
    }

    var updateData = function () {
        if (numbers == 0) return; // Para los controles básicos no se necesita modificaciones

        $(content).children('controls').children('#lastPage').val(totalPages);

        var controls = $(content).children('controls').children('input').toArray();
        var last = parseInt($(controls).last().val());
        var first = parseInt($(controls).first().val());
        var medio = currentPage - Math.round(numbers / 2);
        var center = currentPage >= (last - numbers + 1)
                    ? last - numbers - 1
                    : medio < 1 ? 1
                    : medio;

        for (var i = 1; i <= numbers; i++) {
            $(controls[i])
                .val(i + center)
                .unbind()
                .click(function () { gotoPage($(this).val()) });
        }

    }


    /*      Creación de la información
    ********************************************/
    var createInfo = function () {
        $(content).children('.info').remove();
        var info = $('<div style="display:inline-block; margin-left: 10px"></div>')
                        .addClass('info')
                        .appendTo(content);
        var txtPageSize = $('<input type="number"  max="999" min="0" style="display:inline-block;width: 70px" class="form-control" />')
                                .val(pageSize)
                                .attr('size', 2)
                                .change(function () {
                                    if (maxPageSize == null || maxPageSize == 0 || $(this).val() <= maxPageSize) {
                                        setPageSize($(this).val());
                                        setCurrentPage(1);
                                        search();
                                    } else {
                                        $(this).val(maxPageSize);

                                        if (pageSize != maxPageSize) {
                                            setPageSize(maxPageSize);
                                            setCurrentPage(1);
                                            search();
                                        }
                                    }
                                });

        info.empty()
            .append('Página ' + currentPage + ' de ' + (totalRegs != 0 ? totalPages : 1))
            .append('. Registros encontrados: ' + totalRegs)
            .append('. Registros a mostrar por página: ')
            .append(txtPageSize)
        ;



    }

    if (arguments.length != 0)
        this.initPage(config);
}