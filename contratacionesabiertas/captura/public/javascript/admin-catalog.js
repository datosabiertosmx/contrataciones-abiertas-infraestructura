// administracion de listas de catalogos
((catalog) => {


    // instancia del paginador
    let paginacion = new Paginacion({
        content: '#catalogs-pagination',
        search: () => { $('#frmAdminCatalogs').submit() },
        info: true
    });


    let modalAdmin = $('#adminModal');
    let modal = $("#genericModal");
    let processing = false;

    // reset on
    modal.off('submit', '#frmCatalog');
    modal.off('submit', '#frmImportCatalogs');
    modalAdmin.off('click', '[data-edit]');
    modalAdmin.off('click', '#btnNewCatalog');
    $('#catalogs-result').off('click', '[data-delete]');

    let generateCatalogResult = (item) => {
        switch (catalog) {
            case 'item':
                return `<div class="panel panel-default">
                        <div class="panel-heading">
                            <h4 class="panel-title">${item.classificationid}</h4>
                        </div>
                        <div class="panel-body">
                            <div class="pull-right">
                                <button class="btn btn-default" data-edit="${item.id}">Editar</button>
                                <button class="btn btn-danger" data-delete="${item.id}">Eliminar</button>
                            </div> 
                            <p><label>Descripción:</label> ${item.description}</p>
                            <p><label>Unidad:</label> ${item.unit}</p>
                        </div>
                    </div>`;
            case 'activitymir':
                return `<div class="panel panel-default">
                            <div class="panel-heading">
                                <h4 class="panel-title">${item.specificactivity}</h4>
                            </div>
                            <div class="panel-body">
                                <div class="pull-right">
                                    <button class="btn btn-default" data-edit="${item.id}">Editar</button>
                                    <button class="btn btn-danger" data-delete="${item.id}">Eliminar</button>
                                </div> 
                                <p><label>Nombre:</label> ${item.specificactivity_desc}</p>
                            </div>
                        </div>`;
            case 'departure':
                return `<div class="panel panel-default">
                            <div class="panel-heading">
                                <h4 class="panel-title">${item.spendingobject}</h4>
                            </div>
                            <div class="panel-body">
                                <div class="pull-right">
                                    <button class="btn btn-default" data-edit="${item.id}">Editar</button>
                                    <button class="btn btn-danger" data-delete="${item.id}">Eliminar</button>
                                </div> 
                                <p><label>Descripción:</label> ${item.spendingobject_desc}</p>
                            </div>
                        </div>`;
            case 'programaticstructure':
                return `<div class="panel panel-default">
                            <div class="panel-heading">
                                <h4 class="panel-title">${item.cve}</h4>
                            </div>
                            <div class="panel-body">
                                <div class="pull-right">
                                    <button class="btn btn-default" data-edit="${item.id}">Editar</button>
                                    <button class="btn btn-danger" data-delete="${item.id}">Eliminar</button>
                                </div> 
                                <p><label>Año:</label> ${item.year}  <label>Trimestre:</label> ${item.trimester}</p>
                                <p><label>Unidad administrativa:</label> ${item.requestingunit_desc}</p>
                                <p><label>Actividad MIR:</label> ${item.specificactivity_desc}</p>
                                <p><label>Partida:</label> ${item.spendingobject_desc}</p>
                            </div>
                        </div>`;
            case 'administrativeunit':
                return `<div class="panel panel-default">
                            <div class="panel-heading">
                                <h4 class="panel-title">${item.requestingunit}</h4>
                            </div>
                            <div class="panel-body">
                                <div class="pull-right">
                                    <button class="btn btn-default" data-edit="${item.id}">Editar</button>
                                    <button class="btn btn-danger" data-delete="${item.id}">Eliminar</button>
                                </div> 
                                <p><label>Nombre:</label> ${item.requestingunit_desc}</p>
                            </div>
                        </div>`;
        }

        return '';
    }


    // busqueda
    $('#frmAdminCatalogs').submit(function (e) {
        e.preventDefault();
        // se agregan los valores actuales del paginador al formulario
        $(this).find('[name="page"]').val(paginacion.getCurrentPage());
        $(this).find('[name="pageSize"]').val(paginacion.getPageSize());
        const results = $('#catalogs-result');
        results.html('<div class="text-center"><span class="fa  fa-refresh fa-spin fa-2x"></span></div>');
        $.post(`/admin/catalog/${catalog}/search`, $(this).serializeArray(), res => {
            results.empty();
            if (res.data.length === 0) {
                results.html('<div class="alert alert-warning text-center" role="alert">No se han encontrado resultados</div>');
            } else {
                res.data.map(x => results.append(generateCatalogResult(x)));
            }
            // se indica el total de registros para que se recalculen los valores 
            paginacion.updateControls(res.total);
        }).fail(res => {
            paginacion.updateControls(0);
            results.html(`<div class="alert alert-warning text-center" role="alert">${res.message || 'No se ha podido ejecutar la búsqueda'}</div>`);
        });
    });

    // cargar modal crear
    modalAdmin.on('click', '#btnNewCatalog', function () {
        modal.find('.modal-title').text('Agregar Nuevo Código');
        modal.find('#modal_content').html("");
        modal.find('#modal_content').load(`/admin/catalog/${catalog}/fields`), () => initEvents();
        modal.modal('show');
    });
    // editar modal crear
    
    modalAdmin.on('click', '[data-edit]', function () {
        modal.find('.modal-title').text('Editar Código');
        modal.find('#modal_content').html("");
        modal.find('#modal_content').load(encodeURI(`/admin/catalog/${catalog}/fields/${$(this).data('edit')}`),() => initEvents());
        modal.modal('show');
    });

    // crear / editar
    modal.on('submit', '#frmCatalog', function (e) {
        e.preventDefault();
        $.post(`/admin/catalog/${catalog}/`, $(this).serializeArray(), res => {
            alert(res.message);
            $('#frmAdminCatalogs').submit();
            modal.modal('hide');
        }).fail(res => {
            alert(res.responseJSON.message);
        });
    });

    // eliminar
    $('#catalogs-result').on('click', '[data-delete]', function () {
        const parent = $(this).parents('.panel');
        if (confirm('¿Está seguro de eliminar este registro?')) {
            $.post(encodeURI(`/admin/catalog/${catalog}/${$(this).data('delete')}/delete`), (res) => {
                parent.remove();
                $('#frmAdminCatalogs').submit();
                alert(res.message);
            }).fail(res => {
                alert(res.responseJSON.message);
            });
        }
    });

    let importing = (importar) => {

        if ((importar === undefined && processing) || importar) {
            processing = true;
            $('#frmImportCatalogs').addClass('hide');
            $('#spinner').removeClass('hide');
        } else {
            $('#spinner').addClass('hide');
            $('#frmImportCatalogs').removeClass('hide');
            processing = false;
        }

    }

    // cargar importacion
    $('#btnImportCatalog').click(() => {
        modal.find('.modal-title').text('Importar Lista');
        modal.find('#modal_content').html("");
        modal.find('#modal_content').load(`/admin/catalog/${catalog}/import`, () => importing());

        modal.modal('show');
    });


    modal.on('submit', '#frmImportCatalogs', function (e) {
        e.preventDefault();
        $('#errors').empty();
        if (!processing) {
            const formData = new FormData();
            formData.append('datafile', $(this).find('input:file').get(0).files[0]);
            formData.append('clear', $(this).find('input:checkbox').is(':checked'));
            importing(true);
            $.ajax({
                url: `/admin/catalog/${catalog}/import`,
                type: 'post',
                data: formData,
                cache: false,
                contentType: false,
                processData: false,
                success: res => {
                    $('#frmAdminCatalogs').submit();
                    alert(res.message);
                    importing(false);
                    if (res.errors.length > 0) {
                        $('#errors').html(res.errors.join('<br/>'));
                    } else {
                        modal.modal('hide');
                    }
                },
                error: function (err) {
                    importing(false);
                    alert(err.responseText || ' No se ha podido realizar la importación');
                }
            });
        }

    });



    var initEvents = () => {
        var form = $('#frmCatalog');

        switch (catalog) {
            case 'measures':
                form.find('[name="ue"]').change(function(e)  {
                    e.preventDefault();

                    form.find('[name="mir"]').html('<option value="">Seleccione una opción</option>');

                    $.post('/search-activitymir/', { ue: $(this).val() }).done(function (data) {
                        var options = '<option value="">Seleccione una opción</option>';

                        if (data != null) {
                            data.forEach(function (v, i) {
                                options += '<option value="' + v.value + '">' + v.name + '</option>';
                            });
                        }

                        form.find('[name="mir"]').html(options);
                        form.find('[name="part"]').html('<option value="">Seleccione una opción</option>');
                    });
                });

                form.find('[name="mir"]').change(function(e) {
                    e.preventDefault();

                    form.find('[name="part"]').html('<option value="">Seleccione una opción</option>');

                    $.post('/search-departure/', { mir: $(this).val() }).done(function (data) {
                        var options = '<option value="">Seleccione una opción</option>';

                        if (data != null) {
                            data.forEach(function (v, i) {
                                options += '<option value="' + v.value + '">' + v.name + '</option>';
                            });
                        }

                        form.find('[name="part"]').html(options);
                    });
                });
                break;
        }


    }

    setTimeout(() => {
        $('#frmAdminCatalogs').submit();
    }, 500);
})(catalog);