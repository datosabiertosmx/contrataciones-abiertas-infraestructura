/**
 * Created by mtorres on 19/04/16.
 */

/*window.onbeforeunload = function() {
        return "Si recarga la página perdera sus últimos cambios";
 };*/

/* Date picker */
$(function () {
    $('#lici_date1, #lici_date2, #lici_date3, #lici_date4, #lici_date5, #lici_date6, #lici_date7').datetimepicker({
        locale: 'es',
        format: 'YYYY-MM-DD HH:mm:ss'//'DD/MM/YYYY HH:mm:ss'
    });
    $('#adju_date1, #adju_date2, #adju_date3, #adju_date4').datetimepicker({
        locale: 'es',
        format: 'YYYY-MM-DD HH:mm:ss'//'DD/MM/YYYY HH:mm:ss'
    });
    $('#cont_date1, #cont_date2, #cont_date3, #cont_date4').datetimepicker({
        locale: 'es',
        format: 'YYYY-MM-DD HH:mm:ss'//'DD/MM/YYYY HH:mm:ss'
    });

    $('#datetimepicker1').datetimepicker({
        format: 'YYYY-MM-DD',
        useCurrent: false,
        locale: 'es'
    }).on("dp.change", function (e) {
        $('#datetimepicker2').data("DateTimePicker").minDate(e.date);
    });

    $('#datetimepicker2').datetimepicker({
        format: 'YYYY-MM-DD',
        useCurrent: true,
        locale: 'es'
    }).on("dp.change", function (e) {
        $('#datetimepicker1').data("DateTimePicker").maxDate(e.date);
    });

    $(document).on('keypress', '[data-vregex]', function (e) {
        var type = this.getAttribute('data-vregex').toLowerCase();

        switch (type) {
            case 'integer':
                return /\d/.test(String.fromCharCode(e.keyCode));
                break;
            case 'decimal':
                return /\d|\./.test(String.fromCharCode(e.keyCode)) && /^\d+(\.\d*)?$/.test(this.value + String.fromCharCode(e.keyCode));
                break;
        }
    });

    $.fn.extend({
        serializeJSON: function (exclude) {
          exclude || (exclude = []);
          return this.serializeArray().reduce(function (hash, pair) {
            var match = pair.name.match(/(.+)\[([0-9]+)\]\.(.+)/);

            if (match) {
                if (!(match[1] in exclude)) {
                    var index = parseInt(match[2]);

                    hash[match[1]] = hash[match[1]] || [];
                    hash[match[1]][index] = hash[match[1]][index] || {};
                    hash[match[1]][index][match[3]] = pair.value;
                }
            } else {
                if (!(pair.name in exclude)) {
                    if (hash[pair.name]) {
                        hash[pair.name] = hash[pair.name].constructor == Array ? hash[pair.name] : [hash[pair.name]];

                        if (pair.value) {
                            hash[pair.name].push(pair.value);
                        }
                    } else {
                        if (pair.value) {
                            hash[pair.name] = pair.value;
                        }
                    }
                }
            }

            return hash;
          }, {});
        }
    });
});

var importing = false;


// Tooltips
$(document).ready(function(){
    $('[data-tooltip="crear_proceso"]').tooltip();

    $('#create_process, #nuevo_jumbo').click(function () {
        if ( confirm('¿Está seguro de crear un nuevo proceso de contratación?')) {
            $.post('/new-process').done(function (data) {
                alert("Se ha creado un nuevo proceso de contratación");
                window.location.href = data.url;
            });
        }
    });

    $('#create_project').click(function () {
        if ( confirm('¿Está seguro de crear un nuevo proyecto?')) {
            $.post('/new-project').done(function (data) {
                if(data.url === '/main/'){
                    alert("El usuario no tiene un publicador asignado")
                }else{
                    alert("Se ha creado un nuevo proyecto")
                }
                window.location.href = data.url; 
            });
        }
    });
    $('[name = delete_related_contracting_process_project]').click(function (event) {
        //console.log(event);
        if (confirm("¿Está seguro de elimiar el registro?")){
            $.ajax({
                url: "/1.1/delete_related_contracting_process_project",
                method: "DELETE",
                data: {contracting_process_id : $(this).data("contracting_process_id")},
                success:  function (data) {
                    alert(data.description);
                    if (data.status === 'Ok'){location.reload();}
                }
            })
        }
    });
    $('#project_form').submit(function (event) {
        alert("Se almacenó correctamente el proyecto")
    });
    $('#completion_project_form').submit(function (event) {
        alert("Se almacenó correctamente el proyecto")
    });
    $('#download_project_package').click(function (event) {download_project
        const pid =  $('[name="project_id"]').val();
        $.get('/edcapi/projectPackage/'+pid).done(function (data) {
            //alert(data);
            var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent((JSON.stringify(data,null,4)));
            var dlAnchorElem = document.getElementById('downloadAnchorElem');
            dlAnchorElem.setAttribute("href",     dataStr     );
            dlAnchorElem.setAttribute("download", "ProjectPackage"+pid+".json");
            dlAnchorElem.click();
        });
        
    });
    $('#download_project').click(function (event) {
        const pid =  $('[name="project_id"]').val();
        $.get('/edcapi/project/'+pid).done(function (data) {
            //alert(data);
            var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent((JSON.stringify(data,null,4)));
            var dlAnchorElem = document.getElementById('downloadAnchorElem');
            dlAnchorElem.setAttribute("href",     dataStr     );
            dlAnchorElem.setAttribute("download", "Project"+pid+".json");
            dlAnchorElem.click();
        });
        
    });
});


//Update planning
$( "#planning_form" ).submit(function(event) {
    event.preventDefault();

    var form = $(this);
    const cpid = form.find('[name="contractingprocess_id"]').val();

    setTags(cpid, 1, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });

        $.post('/update-planning/', params).done(function (data) {
            alert(data);
        });
    });
});

//Update tender
$("#tender_form").submit(function(event) {
    event.preventDefault();

    var form = $(this);
    const cpid = form.find('[name="contractingprocess_id"]').val();

    setTags(cpid, 2, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });

        $.post('/update-tender/', params).done(function (data) {
            alert(data);
            location.reload();
        });
    });
});

// load award
let loadAward = (ele, refresh) => {
    const id = $(ele).attr('data-id') || '';
    const cpid = $(ele).attr('data-contractingprocess_id');

    if(id && id === $('#award').attr('data-actual')) return;

    if(!$('#award').attr('data-actual')){
        // agregar directamente cuando no se ha cargado nada
        $('#award').load(`/award/${cpid}/${id}`, () => updateListAwards(cpid, refresh));
    } else if(confirm('¿Desea cargar la adjudicación?')){
        // preguntar antes de cargar, por si accidentalmente dio clic
        $('#award').load(`/award/${cpid}/${id}`,  () => updateListAwards(cpid, refresh));
    }
}
$('#list-awards').on('click', 'a', function(){
    loadAward(this);
});
$('#btnAddAward').click(function() {
    loadAward(this, true);
});

// actualiza estados de las listas de adjudicacion
let updateListAwards = (cpid, refresh, callback) => {
    const id = $('#award_form [name="id"]').val();

    $('#award').attr('data-actual', id || '');
    $('#list-awards a').removeClass('active');

    if(refresh) {
        $('#list-awards').load(`/award-list/${cpid}`, () => {
            $(`#list-awards a[data-id="${id}"]`).addClass('active');
            $('#award_form #actual-text').html($(`#list-awards a[data-id="${id}"] .list-group-item-heading`).text());
            generateAwardSelector();
            if (callback) callback();
        });
       
    } else {
        $('#award_form #actual-text').html($(`#list-awards a[data-id="${id}"] .list-group-item-heading`).text());
        $(`#list-awards a[data-id="${id}"]`).addClass('active');
    }

    $('#adju_date1, #adju_date2, #adju_date3').datetimepicker({
        format: 'YYYY-MM-DD',
        useCurrent: false,
        locale: 'es'
    });

    $('select[name="suppliers"]').multiselect({
        buttonContainer: '<div class="dropdown"></div>',
        buttonClass: 'form-control',
        nonSelectedText: 'Seleccione una opción',
        nSelectedText: 'seleccionados',
        allSelectedText: 'Todos',
        enableHTML: true,
        numberDisplayed: 2
    });

    $('#frmAwardStatus select').val($('#award_form [name="status"]').val());
    $('#frmAwardStatus [name="id"]').val($('#award_form [name="id"]').val());
    let textoStatus = $('#frmAwardStatus select option:selected').text();
    $('#awardStatus').text(textoStatus === 'Seleccione una opción' ? '' : textoStatus);
}

// load first award
$('#list-awards a[data-actual="true"]:first').click();

//Update award
$("#award").on('submit', '#award_form',function(event){
    event.preventDefault();
    
    var form = $(this);
    const cpid = form.find('[name="contractingprocess_id"]').val();

    setTags(cpid, 3, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });

        $.post('/update-award/', params, data => {
            alert(data.message);
            updateListAwards(cpid, true);
        }).fail(function (data) {
            alert(data.responseJSON.message);
        });
    });
});


// delete award
$("#award").on('click', '#btnDeleteAward', function(event){
    const awardid =  $(this).attr('data-id');
    const cpid =  $('[name="contractingprocess_id"]').val();
    if (confirm('¿Desea eliminar está adjudicación')){
        $.post(`/delete-award/${cpid}/${awardid}`, undefined, (data) => {
            $(`#list-awards a[data-id="${awardid}"]`).remove();
            $("#award").html('<h3 class="text-center">Seleccione o agregue una nueva adjudicación</h3>');
            updateListAwards($('[name="contractingprocess_id"]').val(), true);
            alert(data.message);
        }).fail(function (data) {
            alert(data.responseJSON.message);
        });
    }
});

let generateAwardSelector = () => {
    const $selector = $('#contract [name="awardid"]');
    if($selector.length > 0){
        const selected = $selector.data('val') || $selector.val();
        $selector.empty()
        $('#list-awards a').each(function() {
            let extra = $(this).find('.list-group-item-text').text();
            $selector.append(`<option value="${$(this).data('id')}">${$(this).find('.list-group-item-heading').text()} ${(extra ? ' - ' + extra: '')}</option>`)
        });
        $selector.val(selected);
    }
}

$("#contract").on('change', '[name="awardid"]',function() {
    $(this).data('val', $(this).val());
});

// load contracts
let loadContracs = (ele, refresh) => {
    const id = $(ele).attr('data-id') || '';
    const cpid = $(ele).attr('data-contractingprocess_id');

    if(id && id === $('#contract').attr('data-actual')) return;

    if(!$('#contract').attr('data-actual')){
        // agregar directamente cuando no se ha cargado nada
        $('#contract').load(`/contract/${cpid}/${id}`, () => updateListContracts(cpid, refresh));
    } else if(confirm('¿Desea cargar el contrato?')){
        // preguntar antes de cargar, por si accidentalmente dio clic
        $('#contract').load(`/contract/${cpid}/${id}`,  () => updateListContracts(cpid, refresh));
    }
}
$('#list-contracts').on('click', 'a', function(){
    loadContracs(this);
});
$('#btnAddContract').click(function() {
    loadContracs(this, true);
});

// actualiza estados de las listas de contratos
let updateListContracts = (cpid, refresh, callback) => {
    const id = $('#contract_form [name="id"]').val();

    $('#contract').attr('data-actual', id || '');
    $('#list-contracts a').removeClass('active');
    
    if(refresh) {
        $('#list-contracts').load(`/contract-list/${cpid}`, () => {
            $(`#list-contracts a[data-id="${id}"]`).addClass('active');
            $('#contract_form #actual-text').html($(`#list-contracts a[data-id="${id}"] .list-group-item-heading`).text());
            if(callback)callback();
        });
        updateListImplementations(cpid, true, callback);
    } else {
        $('#contract_form #actual-text').html($(`#list-contracts a[data-id="${id}"] .list-group-item-heading`).text());
        $(`#list-contracts a[data-id="${id}"]`).addClass('active');
    }

    $('#cont_date1, #cont_date2, #cont_date3').datetimepicker({
        format: 'YYYY-MM-DD',
        useCurrent: false,
        locale: 'es'
    })

    generateAwardSelector();

    $('#frmContractStatus select').val($('#contract_form [name="status"]').val());
    $('#frmContractStatus [name="id"]').val($('#contract_form [name="id"]').val());
    let textoStatus = $('#frmContractStatus select option:selected').text();
    $('#contractStatus').text(textoStatus === 'Seleccione una opción' ? '' : textoStatus);
}

// load first contract
$('#list-contracts a[data-actual="true"]:first').click();

//Update contracts
$("#contract").on('submit', '#contract_form',function(event){
    event.preventDefault();

    var form = $(this);
    const cpid = form.find('[name="contractingprocess_id"]').val();

    setTags(cpid, 4, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });

        $.post('/update-contract/', params, data => {
            alert(data.message);
            updateListContracts(cpid, true);
            updateListImplementations(cpid, true);
        }).fail(function (data) {
            alert(data.responseJSON.message);
        });
    });
});


// delete contract
$("#contract").on('click', '#btnDeleteContract', function(event){
    const contractid =  $(this).attr('data-id');
    const cpid =  $(this).attr('data-contractingprocess_id');
    if (confirm('¿Desea eliminar este contrato?')){
        $.post(`/delete-contract/${cpid}/${contractid}`, undefined, (data) => {
            $(`#list-contracts a[data-id="${contractid}"]`).remove();
            $("#contract").html('<h3 class="text-center">Seleccione o agregue un nuevo contrato</h3>');
            updateListContracts($('[name="contractingprocess_id"]').val(), true);
            updateListImplementations(cpid, true);
            if($('#implementation [name="contractid"]').val() === contractid){
                $('#implementation').html('<h3 class="text-center">Seleccione o agregue una nuevo ejecución</h3>');
            }
            alert(data.message);
        }).fail(function (data) {
            alert(data.responseJSON.message);
        });
    }
});





// load implementations
$('#list-implementations').on('click', 'a', function() {
    const id = $(this).attr('data-id') || '';
    const cpid = $(this).attr('data-contractingprocess_id');

    if(id && id === $('#implementation').attr('data-actual')) return;

    if(!$('#implementation').attr('data-actual')){
        // agregar directamente cuando no se ha cargado nada
        $('#implementation').load(`/implementation/${cpid}/${id}`, () => updateListImplementations(cpid));
    } else if(confirm('¿Desea cargar la ejecución?')){
        // preguntar antes de cargar, por si accidentalmente dio clic
        $('#implementation').load(`/implementation/${cpid}/${id}`,  () => updateListImplementations(cpid));
    }
});

// actualiza estados de la lista de ejecuciones
let updateListImplementations = (cpid, refresh, callback) => {
    const id = $('#implementation_form [name="id"]').val();

    $('#implementation').attr('data-actual', id || '');
    $('#list-implementations a').removeClass('active');
    
    if(refresh) {
        $('#list-implementations').load(`/implementation-list/${cpid}`, () => {
            $(`#list-implementations a[data-id="${id}"]`).addClass('active');
            $('#implementation_form #actual-text').html($(`#list-implementations a[data-id="${id}"] .list-group-item-heading`).text());
            if(callback)callback();
        });
    } else {
        $('#implementation_form #actual-text').html($(`#list-implementations a[data-id="${id}"] .list-group-item-heading`).text());
        $(`#list-implementations a[data-id="${id}"]`).addClass('active');
    }

    $('#frmImplementationStatus select').val($('#implementation_form [name="status"]').val());
    $('#frmImplementationStatus [name="id"]').val($('#implementation_form [name="id"]').val());
    let textoStatus = $('#frmImplementationStatus select option:selected').text();
    $('#implementationStatus').text(textoStatus === 'Seleccione una opción' ? '' : textoStatus);
}

// load first implementation
$('#list-implementations a[data-actual="true"]:first').click();

//Update implementation
$("#implementation").on('submit', '#implementation_form',function(event){
    event.preventDefault();

    var form = $(this);
    const cpid = form.find('[name="contractingprocess_id"]').val();

    setTags(cpid, 5, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });

        $.post('/update-implementation/', params, data => {
            alert(data.message);
            updateListImplementations(cpid, true);
        }).fail(function (data) {
            alert(data.message);
        });
    });
});

function setTags(id, stage, callback) {
    var modal = $('#genericModal');
    modal.find('.modal-title').text('Etiquetas de publicación');
    modal.find('#modal_content').html("");
    modal.find('#modal_content').load('/tags/', { id: id, stage: stage }, function () {
        $('#tags_form').submit(function (event) {
            event.preventDefault();

            if ($('input[type="checkbox"]:checked').length > 0) {
                if (callback) {
                    callback($(this).serializeArray());
                    modal.modal('hide');
                } else {
                    $.post('/update-tags/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                }
            } else {
                alert('Debe seleccionar al menos una etiqueta');
            }
        });

        modal.modal('show');
    });
}


$('#genericModal').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var modal = $(this);

    modal.off('hide.bs.modal');
    modal.on('hide.bs.modal', function () {
        modal.find('.modal-dialog').css('width', '');
     });

    switch ( button.data('action') ){
        //import data from csv files
        case "edit_publisher":
            modal.find('.modal-title').text('Publicador');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/publisher/',{ localid: button.data('contractingprocess_id') }, function () {
                // Edit publisher submit event
                $('#updatepub_form').submit(function (event) {
                    $.post('/update-publisher/', $(this).serialize()).done(function (data) {
                        alert( data.description );
                        if ( data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
            //edit project publisher
        case "edit_project_publisher":
            modal.find('.modal-title').text('Publicador');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/project-publisher/',{ projectId: button.data('project_id') }, function () {
            });
            break;
        
        // Datos PNT 
        case "data_pnt":
            modal.find('.modal-title').text('Datos PNT');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/data-PNT/',{ datapnt_cp_id: button.data('contractingprocess_id') }, function () {
                //datepickers
                $('#pnt_date1, #pnt_date2, #pnt_date3, #pnt_date4').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }); 
                //submit data
                $('#dataPNT_form').submit(function (event) {
                    $.post('/register-dataPNT/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){modal.modal('hide');}
                    });
                    event.preventDefault();
                });           
            });
            break;

        case "edit_parties":
            modal.find('.modal-title').text('Actores');
            modal.find('#modal_content').load('/1.1/parties.html', { contractingprocess_id : button.data("contractingprocess_id")}, function () {
            	$('button[name="delete_party"]').click(function () {
            		let id = $(this).data('parties_id');
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/party",
                            method: "DELETE",
                            data: {parties_id : $(this).data("parties_id"), contractingprocess_id: button.data("contractingprocess_id")},   
                            success:  function (data) {
                                console.log("hhhhhhhhh" + JSON.stringify(data))
                                alert(data.description);
                                $('[name="numberoftenderers"]').val(data.total);
                                if (data.status === 'Ok'){ 
                                    modal.modal('hide');
                                }
                            },
                            error: function (data) {
                                alert("No es posible eliminar el actor porque cuenta información asociada a los formularios de Solicitud de cotizaciones y Cotizaciones.");
                            }
                        })
                    }
                });
            	$('button[name="edit_party"]').click(function () {
                    let id = $(this).data('parties_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_party.html', { parties_id: id},function(){
                        $('#update_party_form').submit(function (e) {
                            $.post('/1.1/party', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                $('[name="numberoftenderers"]').val(data.total);
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                                location.reload();
                            });
                            e.preventDefault();
                        });

                        // add member
                        $('[data-action="new_memberof"]').click(function() {
                            modal.find('.modal-title').text('Miembro de...');
                            modal.find('#modal_content').html("").load('/member/fields/' +  $(this).data('id'), () => initModalMember(modal, $(this).data('id')));
                        });

                        // edit member
                        $('[data-action="edit_memberof"]').click(function() {
                            modal.find('.modal-title').text('Miembros');
                            modal.find('#modal_content').html("").load('/members/' +  $(this).data('id'), () => initModalMember(modal, $(this).data('id')));
                        });

                        modal.find('[data-action="new_contactpoint"]').click(function () {
                            modal.find('.modal-title').text('Punto de contacto adicional');
                            modal.find('#modal_content').html("").load('/newcontactpoint-fields', {
                                partyid: $(this).data('id')
                            }, () => initModalContactPoint(modal, $(this).data('id')));
                        });

                        modal.find('[data-action="edit_contactpoints"]').click(function () {
                            modal.find('.modal-title').text('Puntos de contacto adicional');
                            modal.find('#modal_content').html("").load('/contactpoint-list', {
                                partyid: $(this).data('id')
                            }, () => initModalContactPoint(modal, $(this).data('id')));
                        });

                        modal.find('[name$="language"]').multiselect({
                            buttonContainer: '<div class="dropdown"></div>',
                            buttonClass: 'form-control',
                            nonSelectedText: 'Seleccione una opción',
                            enableHTML: true,
                            enableFiltering: true,
                            nSelectedText: 'seleccionados',
                            allSelectedText: 'Todos',
                            filterPlaceholder: 'Búsqueda',
                        });
                    });
                })
            });
            break;
        case "edit_parties_project":
            modal.find('.modal-title').text('Actores');
            modal.find('#modal_content').load('/1.1/parties_project.html', { project_id : button.data("project_id")}, function () {
                $('button[name="edit_party_project"]').click(function () {
                    let id = $(this).data('parties_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_party_project.html', { parties_id: id},function(){
                        
                        $('#update_party_project_form').submit(function (e) {
                            $.post('/1.1/party_project', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                            });
                            e.preventDefault();
                        });
                        //aditional identifiers party project
                        modal.find('[data-action="add_additional_identifiers"]').click(function () {
                            modal.find('.modal-title').text('Identificadores adicionales');
                            modal.find('#modal_content').html("").load('/add-additional-identifiers', {
                                partyId: $(this).data('id')
                            }, () => initModalAdditionalIdentifiers(modal, $(this).data('id')));
                        });      
                        //edit aditional identifiers party project
                        modal.find('[data-action="edit_additional_identifiers"]').click(function () {
                            modal.find('.modal-title').text('Identificadores adicionales');
                            modal.find('#modal_content').html("").load('/edit-additional-identifiers', {
                                partyId: $(this).data('id')
                            }, () => initModalAdditionalIdentifiers(modal, $(this).data('id')));
                        });
                        
                    });
                }),
                $('button[name="delete_party_project"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/party_project",
                            method: "DELETE",
                            data: {parties_id : $(this).data("parties_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                });
            });
            break;
        case "edit_budget_breakdown_project":
            modal.find('.modal-title').text('Desgloses de presupuestos');
            modal.find('#modal_content').load('/1.1/budget_breakdown_project_list.html', { project_id : button.data("project_id")}, function () {
                $('button[name="edit_budgetbreakdown_project"]').click(function () {
                    let id = $(this).data('budgetbreakdown_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_budgetBreakdown_project.html', { budgetbreakdown_id: id},function(){
                        
                        $('#update_budget_breakdown_project_form').submit(function (e) {
                            $.post('/1.1/update_budgetbreakdown_project', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                            });
                            e.preventDefault();
                        });
                        //add budget lines project
                        modal.find('[data-action="add_budget_lines"]').click(function () {
                            modal.find('.modal-title').text('Líneas presupuestarias');
                            modal.find('#modal_content').html("").load('/add-budget-lines', {
                                budgetBreakdownId: $(this).data('id')
                            }, () => initModalBudgetLines(modal, $(this).data('id')));
                        });      
                        //edit budget lines project
                        modal.find('[data-action="edit_budget_lines"]').click(function () {
                            modal.find('.modal-title').text('Líneas presupuestarias');
                            modal.find('#modal_content').html("").load('/edit-budget-lines', {
                                budgetBreakdownId: $(this).data('id')
                            }, () => initModalBudgetLines(modal, $(this).data('id')));
                        });
                        
                    });
                }),
                $('button[name="delete_budgetbreakdown_project"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/delete_budget_breakdown_project",
                            method: "DELETE",
                            data: {budgetbreakdown_id : $(this).data("budgetbreakdown_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                });
            });
            break;
        case "edit_additional_classification_project":
             modal.find('.modal-title').text('Clasificaciones Adicionales');
             modal.find('#modal_content').load('/1.1/additional_classifications_list_project.html', { project_id : button.data("project_id")}, function () {
                $('button[name="edit_additional_classification"]').click(function () {
                    let id = $(this).data('classification_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_additional_classification.html', { classification_id: id},function(){
                        
                        $('#update_additional_classification_form').submit(function (e) {
                            $.post('/1.1/update_additional_classification', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                            });
                            e.preventDefault();
                        });
                    });
                }),
                $('button[name="delete_additional_classification"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/delete_additional_classification",
                            method: "DELETE",
                            data: {classification_id : $(this).data("classification_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                });
             });
            break;
        case "edit_location":
            modal.find('.modal-title').text('Ubicaciones del proyecto');
            modal.find('#modal_content').load('/1.1/locations_project.html', { project_id : button.data("project_id")}, function () {
                 // Agrega nuevos items a las coordenadas
                 modal.off('click', '[data-action="add_item"]');
                 modal.on('click', '[data-action="add_item"]', function (e) {
                     e.preventDefault();
                     var template = modal.find('#itemTemplate').html();
 
                     var index = new Date().getTime();
                     template = template.replace(/\[0\]/g, '[' + index + ']');
 
                     var content = $(template).appendTo(modal.find('#items'));
                     initItem(content);
                     updateSelectedItem();
                 });
 
                 // Elimina items de las coordenadas
                 modal.on('click', '[data-dismiss="item"]', function (e) {
                     e.preventDefault();
 
                     $(this).parent().remove();
 
                     if (modal.find('#items').children().length == 0) {
                         var template = modal.find('#itemTemplate').html();
 
                         var index = new Date().getTime();
                         template = template.replace(/\[0\]/g, '[' + index + ']');
 
                         var content = $(template).appendTo(modal.find('#items'));
                     }
                     updateSelectedItem();
                 });
                $('button[name="edit_location_project"]').click(function () {
                    let id = $(this).data('location_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_location_project.html', { location_id: id},function(){
                        
                        modal.find('#update_location_project_form').submit(function (event) {
                            event.preventDefault();
                            $.ajax({
                                url: '/1.1/update_location_project',
                                type: 'post',
                                contentType: 'application/json',
                                data: JSON.stringify($(this).serializeJSON())
                            }).done(function (data) {
                                alert(data.description);
                                if (data.status === 'Ok') { modal.modal('hide'); }
                            });
                        });
                    });
                }),
                $('button[name="delete_location_project"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/delete_location_project",
                            method: "DELETE",
                            data: {location_id : $(this).data("location_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                });
            });
            break;
        case "edit_document_project":
            modal.find('.modal-title').text('Documentos');
            modal.find('#modal_content').load('/1.1/documents_project.html', { project_id : button.data("project_id")}, function () {
                $('button[name="edit_document_project"]').click(function () {
                    let id = $(this).data('document_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_document_project.html', { document_id: id},function(){
                        
                        $('#update_document_project_form').submit(function (e) {
                            $.post('/1.1/update_document_project', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                            });
                            e.preventDefault();
                        });
                    });
                }),
                $('button[name="delete_document_project"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/delete_document_project",
                            method: "DELETE",
                            data: {document_id : $(this).data("document_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                });
            });
            break; 
        case "edit_document":
            modal.find('.modal-title').text('Editar Documento');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editdoc-fields', { 
                id: button.data('id'),
                stage: button.data('stage'),
                table: button.data('table'), function () {
                setTimeout(() => {
                    //Date picker
                    modal.find('#newdoc_date1, #newdoc_date2').datetimepicker({
                        locale: 'es',
                        format: 'YYYY-MM-DD HH:mm:ss'
                    });

                    //submit new document event
                    modal.find('#editdoc_form').submit(function (event) {
                        $.post('/edit-document/', $(this).serialize()).done(function (data) {
                            alert(data.description);
                            if (data.status === 'Ok'){ modal.modal('hide'); }
                        });
                        event.preventDefault();
                    });
                }, 500);
            }});
            break;
        case "edit_related_projects":
            modal.find('.modal-title').text('Proyectos relacionados');
            modal.find('#modal_content').load('/1.1/related_projects.html', { project_id : button.data("project_id")}, function () {
                $('button[name="edit_related_projects"]').click(function () {
                    let id = $(this).data('related_projects_id');
                    modal.find('.modal-title').text("Editar");
                    modal.find("#modal_content").load('/1.1/edit_related_projects.html', { related_projects_id: id},function(){
                        
                        modal.find('[name="relatedProject_title"]').autocomplete({
                            minLength: 0,
                            source: function(request, response) {
                                modal.find('[name="relatedProject_identifier"]').val('');
                                modal.find('[name="relatedProject_uri"]').val('');                                
                                $.post('/search-projects', { search: request.term }).done(function(data) {
                                    if (data.length == 0) {
                                        modal.find('[name="relatedProject_title"]').val('');
                                    }
                                    response(data);
                                });
                            },
                            close: function (e) {
                                if (modal.find('[name="url"]').val() == '') {
                                    modal.find('[name="relatedProject_title"]').val('');
                                }
                            },
                            select: function(event, ui) {
                                modal.find('[name="relatedProject_identifier"]').val(ui.item.projects[0].title);
                                modal.find('[name="relatedProject_title"]').val(ui.item.projects[0].oc4idsIdentifier);
                                modal.find('[name="relatedProject_uri"]').val(ui.item.uri);
                                return false;
                            }
                        }).autocomplete('instance')._renderItem = function (ul, item) {
                            return $('<li>')
                                .data('item.autocomplete', item)
                                .append('<div>' + item.projects[0].oc4ids+'-'+item.projects[0].identifier + '</div>')
                                .appendTo(ul);
                        };

                        $('#update_related_project_form').submit(function (e) {
                            $.post('/1.1/update_related_project', $(this).serialize()).done(function (data) {
                                alert( data.description );
                                if ( data.status === 'Ok'){ modal.modal('hide');}
                            });
                            e.preventDefault();
                        });
                    });
                }),
                $('button[name="delete_related_projects"]').click(function () {
                    if (confirm("¿Está seguro de eliminar el registro?")){
                        $.ajax({
                            url: "/1.1/delete_related_project",
                            method: "DELETE",
                            data: {related_projects_id : $(this).data("related_projects_id")},
                            success:  function (data) {
                                alert(data.description);
                                if (data.status === 'Ok'){ modal.modal('hide');}
                            }
                        })
                    }
                 });
            });
            break;
        case "add_party":
        	modal.find('.modal-title').text('Actor');
            modal.find('#modal_content').load('/1.1/add_party.html', { contractingprocess_id : button.data("contractingprocess_id")}, function(){
                $('#add_party_form').submit(function (e) {
                   $.ajax({
                       url: "/1.1/party/",
                       method: "PUT",
                       data: $(this).serialize(),
                       success: function (data) {
                           alert(data.description);
                           $('[name="numberoftenderers"]').val(data.data.total);
                           if (data.status === 'Ok'){ modal.modal('hide');}
                           location.reload();
                       }
                   });
                    e.preventDefault();
                });

                modal.find('[name$="language"]').multiselect({
                    buttonContainer: '<div class="dropdown"></div>',
                    buttonClass: 'form-control',
                    nonSelectedText: 'Seleccione una opción',
                    enableHTML: true,
                    enableFiltering: true,
                    nSelectedText: 'seleccionados',
                    allSelectedText: 'Todos',
                    filterPlaceholder: 'Búsqueda',
                });
            });
            break;
        case "add_budget_breakdown_project":
            const pid =  $('[name="project_id"]').val();
            var params = new Array();
            params.push({ name: 'project_id', value: pid });
            $.post('/validate-project-amount/', params).done(function (data) {
                switch (data.status) {
                    case 'Ok':
                        modal.find('.modal-title').text('Desglose del presupuesto');
                        modal.find('#modal_content').load('/1.1/add_budget_breakdown_project.html', { project_id : button.data("project_id")}, function(){
                            $('#add_budget_breakdown_project_form').submit(function (e) {
                               $.ajax({
                                   url: "/1.1/add_budget_breakdown_project/",
                                   method: "PUT",
                                   data: $(this).serialize(),
                                   success: function (data) {
                                       alert(data.description);
                                       if (data.status === 'Ok'){ modal.modal('hide');}
                                   }
                               });
                                e.preventDefault();
                            });
                        });
                      break;
                    case 'Error1':
                        modal.find('.modal-title').text('Desglose del presupuesto');
                        modal.modal('hide');
                        alert(data.message);
                      break;
                    case 'Error':
                        modal.find('.modal-title').text('Desglose del presupuesto');
                        modal.modal('hide');
                        alert(data.message);
                      break;
                    default:
                        modal.find('.modal-title').text('Desglose del presupuesto');
                        modal.modal('hide');
                        alert("ERROR");
                      break;
                  }
            });
            break;
        case "add_party_project":
        	modal.find('.modal-title').text('Actor');
            modal.find('#modal_content').load('/1.1/add_party_project.html', { project_id : button.data("project_id")}, function(){
                $('#add_party_project_form').submit(function (e) {
                   $.ajax({
                       url: "/1.1/party_project/",
                       method: "PUT",
                       data: $(this).serialize(),
                       success: function (data) {
                           alert(data.description);
                           if (data.status === 'Ok'){ modal.modal('hide');}
                       }
                   });
                    e.preventDefault();
                });

                modal.find('[name$="language"]').multiselect({
                    buttonContainer: '<div class="dropdown"></div>',
                    buttonClass: 'form-control',
                    nonSelectedText: 'Seleccione una opción',
                    enableHTML: true,
                    enableFiltering: true,
                    nSelectedText: 'seleccionados',
                    allSelectedText: 'Todos',
                    filterPlaceholder: 'Búsqueda',
                });
            });
            break;
        case "import_data":
            modal.find('.modal-title').text('Importar datos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load ('/uploadfile-fields', { localid : button.data('contractingprocess_id'), stage: button.data('stage'), id: button.data('id') });
            break;
        //add new elements
        case "new_item":
            modal.find('.modal-title').text('Ítem');
            modal.find('#modal_content').load('/newitem-fields', {
                localid : button.data('contractingprocess_id'), 
                table: button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
            }, function () {
                $('#newitem_form').find('[name="classification_id"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        $('#newitem_form').find('[name="classification_description"]').val('');
                        $('#newitem_form').find('[name="unit_name"]').val('');

                        $.post('/search-item/', { search: request.term, prop: 'classificationid' }).done(function(data) {
                            if (data.length == 0) {
                                $('#newitem_form').find('[name="classification_id"]').val('');
                            }

                            response(data);
                        });
                    },
                    close: function (e) {
                        if ($('#newitem_form').find('[name="classification_description"]').val() == '') {
                            $('#newitem_form').find('[name="classification_id"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        $('#newitem_form').find('[name="classification_id"]').val(ui.item.classificationid);
                        $('#newitem_form').find('[name="classification_description"]').val(ui.item.description);
                        $('#newitem_form').find('[name="unit_name"]').val(ui.item.unit);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.classificationid + '</div>')
                      .appendTo(ul);
                };

                //submit new item event
                $('#newitem_form').submit(function (event) {
                    $.post('/new-item/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "new_milestone":
            modal.find('.modal-title').text('Hito');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newmilestone-fields',{
                localid: button.data('contractingprocess_id'), 
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
            }, function () {
                // Submit new milestone event
                $('#newmilestone_form').submit(function (event) {
                    $.post('/new-milestone/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
                //datepickers
                $('#newmilestone_date1, #newmilestone_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
            });
            break;
        case "new_document":
            modal.find('.modal-title').text('Documento');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newdoc-fields', { 
                localid: button.data('contractingprocess_id'), 
                stage: button.data('stage'),
                table: button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') }, function () {
                //Date picker
                $('#newdoc_date1, #newdoc_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
                //submit new document event
                $('#newdoc_form').submit(function (event) {
                    $.post('/new-document/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                        if(data.cambio){
                            const cambio = data.cambio;
                            if(cambio.tender) {
                                $('#frmTenderStatus select').val(cambio.tender);
                                $('#tenderStatus').html($('#frmTenderStatus select option:selected').text());
                            }
                            if(cambio.award) {
                                updateListAwards( button.data('contractingprocess_id'), true, () => {
                                    $('#frmAwardStatus select').val(cambio.award);
                                    $('#awardStatus').html($('#frmAwardStatus select option:selected').text());
                                });
                                
                               
                            }
                            if(cambio.contract) {
                                updateListContracts( button.data('contractingprocess_id'), true, () => {
                                    $('#frmContractStatus select').val(cambio.contract);
                                    $('#contractStatus').html($('#frmContractStatus select option:selected').text());
                                });
                                
                                
                            }
                            if(cambio.implementation) {
                                updateListImplementations( button.data('contractingprocess_id'), true, () => {
                                    $('#frmImplementationStatus select').val(cambio.implementation);
                                    $('#implementationStatus').html($('#frmImplementationStatus select option:selected').text());
                                });
                               
                                
                            }
                        }
                    });
                    event.preventDefault();
                });
            });
            break;
        case "new_change":
            modal.find('.modal-title').text('Nueva modificación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newamendmentchange-fields', {
                localid : button.data('contractingprocess_id'), 
                table: button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') }, function () {
                //datepicker
                $('#newchange_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });

                //submit new amendment change event
                $('#newamendmentchange_form').submit(function (event) {
                    $.post('/new-amendment-change',$(this).serialize()).done(function (data) {
                        alert(data.description);
                        if ( data.status === 'Ok' ){modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "new_transaction":
            modal.find('.modal-title').text('Información de pagos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newtransaction-fields', {
                localid : button.data('contractingprocess_id'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
            }, function () {
                //datepicker
                $('#newtrans_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
                //submit new transaction event
                $('#newtransaction_form').submit(function (event) {
                    $.post('/new-transaction', $(this).serialize()).done(function(data){
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "new_quote_request":
            modal.find('.modal-title').text('Solicitud de cotizacion');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newquoterequest-fields', {
                localid: button.data('contractingprocess_id')
            }, function () {
                function initAutocomplete(container) {
                    container.find('[name$="itemname"]').autocomplete({
                        minLength: 0,
                        source: function(request, response) {
                            container.find('[name$="itemid"]').val('');
    
                            $.post('/search-item/', { search: request.term, prop: 'description' }).done(function(data) {
                                if (data.length == 0) {
                                    container.find('[name$="itemid"]').val('');
                                }

                                response(data);
                            });
                        },
                        close: function (e) {
                            if (container.find('[name$="itemname"]').val() == '') {
                                container.find('[name$="itemid"]').val('');
                            }
                        },
                        select: function(event, ui) {
                            container.find('[name$="itemid"]').val(ui.item.classificationid);
                            container.find('[name$="itemname"]').val(ui.item.description + ' / ' + ui.item.unit);
                            container.find('[name$="item"]').val(ui.item.description);
                            return false;
                        }
                    }).autocomplete('instance')._renderItem = function (ul, item) {
                        return $('<li>')
                          .data('item.autocomplete', item)
                          .append('<div>' + item.description + ' / ' + item.unit + '</div>')
                          .appendTo(ul);
                    };
                }

                modal.find('#newquote_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newquote_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('[name="invitedsuppliers"]').multiselect({
                    buttonContainer: '<div class="dropdown"></div>',
                    buttonClass: 'form-control',
                    nonSelectedText: 'Seleccione una opción',
                    nSelectedText: 'Opciones seleccionadas',
                    allSelectedText: 'Opciones seleccionadas'
                });

                modal.off('click', '[data-action="add_item"]');
                modal.on('click', '[data-action="add_item"]', function (e) {
                    e.preventDefault();
                    var template = modal.find('#itemTemplate').html();

                    var index = new Date().getTime();
                    template = template.replace(/\[0\]/g, '[' + index + ']');

                    var content = $(template).appendTo(modal.find('#items'));
                    initAutocomplete(content);
                });

                modal.on('click', '[data-dismiss="item"]', function (e) {
                    e.preventDefault();

                    $(this).parent().remove();

                    if (modal.find('#items').children().length == 0) {
                        var template = modal.find('#itemTemplate').html();

                        var index = new Date().getTime();
                        template = template.replace(/\[0\]/g, '[' + index + ']');

                        var content = $(template).appendTo(modal.find('#items'));
                        initAutocomplete(content);
                    }
                });

                modal.find('#items').children().each(function () {
                    initAutocomplete($(this));
                });

                modal.find('#newquoterequest_form').submit(function (event) {
                    event.preventDefault();

                    modal.find('#items').children().each(function (i) {
                        $(this).find('input, textarea, select').each(function () {
                            $(this).attr('name', $(this).attr('name').replace(/\[[0-9]+\]/g, '[' + i + ']'));
                        });
                    });

                    $.ajax({
                        url: '/new-quote-request',
                        type: 'post',
                        contentType: 'application/json',
                        data: JSON.stringify($(this).serializeJSON())
                    }).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "new_quote":
            modal.find('.modal-title').text('Cotización');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newquote-fields', {
                localid: button.data('contractingprocess_id')
            }, function () {
                // Almacena una copia de los items disponibles en la solicitud
                var items = [];

                // Actualiza el total de la cuantificación
                function updateTotal() {
                    var total = 0;

                    modal.find('#items [name$="quantity"]').each(function (i) {
                        total += parseFloat($(this).val()) || 0;
                    });

                    modal.find('[name="value"]').val(total.toFixed(2));
                }

                // Inicializa el nuevo registro de item
                function initItem(container) {
                    container.find('[name$="quantity"]').val('');
                    container.find('[name$="quantity"]').attr('readonly', 'readonly');

                    var itemOptions = '<option value="">Seleccione una opción</option>';

                    if (items != null) {
                        items.forEach(function (v, i) {
                            itemOptions += '<option value="' + v.classificationid + '">' + v.itemname + '</option>';
                        });
                    }

                    container.find('[name$="itemid"]').html(itemOptions);
                }

                // Actualiza la lista de items por cotizar
                function updateSelectedItem() {
                    var selected = [];

                    modal.find('#items [name$="itemid"]').each(function (i) {
                        var val = $('option:selected', this).val();

                        if (val != '') {
                            selected.push(val);
                        }
                    });

                    modal.find('#items [name$="itemid"]').each(function (i) {
                        var input = $(this);
                        input.find('option').show();

                        selected.forEach(function (v, j) {
                            if (input.val() != v) {
                                input.find('option[value="' + v + '"]').hide();
                            }
                        })
                    });
                }

                // Inicializa campos de fecha
                modal.find('#newquote_date').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
                
                modal.find('#newquote_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newquote_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date1').data("DateTimePicker").maxDate(e.date);
                });

                // Actualiza los catalogos cuando cambia la solicitud
                modal.find('[name="requestforquotes_id"]').change(function () {
                    var id = $('option:selected', this).val();

                    modal.find('[name="issuingSupplier_id"]').html('<option value="">Seleccione una opción</option>');

                    items = [];
                    initItem(modal.find('#items'));

                    if (id !== '') {
                        // Carga los items y los proveedores disponibles de la solicitud
                        $.post('/load-quote-dependencies/', { id: id }).done(function(data) {
                            var supplierOptions = '<option value="">Seleccione una opción</option>';

                            items = data.items;

                            if (data.suppliers != null) {
                                data.suppliers.forEach(function (v, i) {
                                    supplierOptions += '<option value="' + v.id + '">' + v.name + '</option>';
                                });
                            }

                            modal.find('[name="issuingSupplier_id"]').html(supplierOptions);
                            initItem(modal.find('#items'));
                        });
                    }

                    updateTotal();
                });

                // Agrega nuevos items a la cotizacion
                modal.off('click', '[data-action="add_item"]');
                modal.on('click', '[data-action="add_item"]', function (e) {
                    e.preventDefault();
                    var template = modal.find('#itemTemplate').html();

                    var index = new Date().getTime();
                    template = template.replace(/\[0\]/g, '[' + index + ']');

                    var content = $(template).appendTo(modal.find('#items'));
                    initItem(content);
                    updateSelectedItem();
                });

                // Elimina items de la cotizacion
                modal.on('click', '[data-dismiss="item"]', function (e) {
                    e.preventDefault();

                    $(this).parent().remove();

                    if (modal.find('#items').children().length == 0) {
                        var template = modal.find('#itemTemplate').html();

                        var index = new Date().getTime();
                        template = template.replace(/\[0\]/g, '[' + index + ']');

                        var content = $(template).appendTo(modal.find('#items'));
                    }

                    updateTotal();
                    updateSelectedItem();
                });

                // Activa los campos del item cuando este cambia
                modal.off('change', '#items [name$="itemid"]');
                modal.on('change', '#items [name$="itemid"]', function () {
                    var container = $(this).closest('.row');

                    if ($('option:selected', this).val() !== '') {
                        container.find('[name$="quantity"]').removeAttr('readonly');
                    } else {
                        container.find('[name$="quantity"]').val('');
                        container.find('[name$="quantity"]').attr('readonly', 'readonly');
                    }

                    updateTotal();
                    updateSelectedItem();
                });

                // Actualiza el total cuando cambia el valor de un item
                modal.off('change', '#items [name$="quantity"]');
                modal.on('change', '#items [name$="quantity"]', function () {
                    updateTotal();
                });

                // Guarda la cotizacion
                modal.find('#newquote_form').submit(function (event) {
                    event.preventDefault();

                    modal.find('#items').children().each(function (i) {
                        $(this).find('input, textarea, select').each(function () {
                            $(this).attr('name', $(this).attr('name').replace(/\[[0-9]+\]/g, '[' + i + ']'));
                        });
                    });

                    $.ajax({
                        url: '/new-quote',
                        type: 'post',
                        contentType: 'application/json',
                        data: JSON.stringify($(this).serializeJSON())
                    }).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "new_guarantee":
            modal.find('.modal-title').text('Garantía');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newguarantee-fields', {
                localid: button.data('contractingprocess_id'),
                table: button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
            }, function () {
                modal.find('#newguarantee_date').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                });
                
                modal.find('#newguarantee_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    // modal.find('#newguarantee_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newguarantee_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    // modal.find('#newguarantee_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('#newguarantee_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/new-guarantee', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "new_budgetbreakdown":
            modal.find('.modal-title').text('Desglose del presupuesto');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newbudgetbreakdown-fields', {
                localid: button.data('contractingprocess_id')
            }, function () {
                modal.find('#newbudgetbreakdown_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    modal.find('#newbudgetbreakdown_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newbudgetbreakdown_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    modal.find('#newbudgetbreakdown_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('#newbudgetbreakdown_form').off('focusout', '.error');
                modal.find('#newbudgetbreakdown_form').on('focusout', '.error', function() {
                    $(this).removeClass('error');
                });

                modal.find('[data-action="new_budgetclassification"]').click(function () {
                    var valid = true;

                    modal.find('#newbudgetbreakdown_form [required]').each(function() {
                        if ($(this).val() === '') {
                            $(this).focus();
                            $(this).addClass('error');
                            valid = false;

                            alert('Debe llenar los campos obligatorios');

                            return valid;
                        }
                    });

                    if (valid) {
                        $.post('/new-budgetbreakdown', modal.find('#newbudgetbreakdown_form').serialize()).done(function (data) {
                            alert(data.description);
                            if (data.status === 'Ok' && data.id != null) {
                                modal.find('.modal-title').text('Clasificación del presupuesto');
                                modal.find('#modal_content').html("").load('/newbudgetclassification-fields', {
                                    budgetid: data.id
                                }, () => initModalBudgetClassification(modal, data.id));
                            }
                        });
                    }
                });

                modal.find('#newbudgetbreakdown_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/new-budgetbreakdown', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "new_relatedprocedure":
            modal.find('.modal-title').text('Procedimiento relacionado');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/newrelatedprocedure-fields', {
                localid: button.data('contractingprocess_id')
            }, function () {
                modal.find('[name="relatedprocedure_identifier"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        modal.find('[name="url"]').val('');

                        $.post('/search-contractingprocess/', { search: request.term }).done(function(data) {
                            if (data.length == 0) {
                                modal.find('[name="relatedprocedure_identifier"]').val('');
                            }

                            response(data);
                        });
                    },
                    close: function (e) {
                        if (modal.find('[name="url"]').val() == '') {
                            modal.find('[name="relatedprocedure_identifier"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        modal.find('[name="relatedprocedure_identifier"]').val(ui.item.ocid);
                        modal.find('[name="url"]').val(ui.item.record);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.ocid + '</div>')
                      .appendTo(ul);
                };

                modal.find('#newrelatedprocedure_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/new-relatedprocedure', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "add_related_summary_procedure_project":
            modal.find('.modal-title').text('Proceso de contratación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/add_related_summary_procedure_project', {
                project_id: button.data('project_id')
            }, function () {
                modal.find('[name="relatedprocedure_identifier"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        modal.find('[name="title"]').val('');
                        modal.find('[name="contractingprocess_id"]').val('');
                        modal.find('[name="tender_id"]').val('');

                        $.post('/search-contractingprocess/', { search: request.term }).done(function(data) {
                            if (data.length == 0) {
                                modal.find('[name="relatedprocedure_identifier"]').val('');
                            }
                            console.log("### - /search-contractingprocess/" + JSON.stringify(data))
                            response(data);
                        });
                    },
                    close: function (e) {
                        if (modal.find('[name="title"]').val() == '') {
                            modal.find('[name="relatedprocedure_identifier"]').val('');
                            modal.find('[name="contractingprocess_id"]').val('');
                            modal.find('[name="tender_id"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        //console.log("##### add_related_summary_procedure_project AUTOCOMPLETE " + JSON.stringify(ui.item));
                        modal.find('[name="relatedprocedure_identifier"]').val(ui.item.ocid);
                        modal.find('[name="title"]').val(ui.item.title);
                        modal.find('[name="contractingprocess_id"]').val(ui.item.id);
                        modal.find('[name="tender_id"]').val(ui.item.tenderid);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.ocid + '</div>')
                      .appendTo(ul);
                };

                modal.find('#add_related_summary_procedure_project_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/insert-related-summary-procedure-project', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); location.reload();}
                    });
                });
            });
            break;
        case "edit_related_summary_procedure_project":
            modal.find('.modal-title').text('Editar');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/edit_related_summary_procedure_project', {
                contracting_process_id: button.data('contracting_process_id')
            }, function () {
                modal.find('[name="relatedprocedure_identifier"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        modal.find('[name="title"]').val('');
                        modal.find('[name="contractingprocess_id"]').val('');
                        modal.find('[name="tender_id"]').val('');

                        $.post('/search-contractingprocess/', { search: request.term }).done(function(data) {
                            if (data.length == 0) {
                                modal.find('[name="relatedprocedure_identifier"]').val('');
                            }

                            response(data);
                        });
                    },
                    close: function (e) {
                        if (modal.find('[name="title"]').val() == '') {
                            modal.find('[name="relatedprocedure_identifier"]').val('');
                            modal.find('[name="contractingprocess_id"]').val('');
                            modal.find('[name="tender_id"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        modal.find('[name="relatedprocedure_identifier"]').val(ui.item.ocid);
                        modal.find('[name="title"]').val(ui.item.title);
                        modal.find('[name="contractingprocess_id"]').val(ui.item.id);
                        modal.find('[name="tender_id"]').val(ui.item.tenderid);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.ocid + '</div>')
                      .appendTo(ul);
                };

                modal.find('#update_related_summary_procedure_project_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/update-related-summary-procedure-project', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { 
                            modal.modal('hide');
                            location.reload(); 
                        }
                    });
                });
            });
            break;
        case "add_location":
            modal.find('.modal-title').text('Ubicaciones del proyecto');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/add-location-project', {
                project_id: button.data('project_id')
            }, function () {
                modal.find('#add_location_project_form').submit(function (event) {
                    event.preventDefault();

                    modal.find('#items').children().each(function (i) {
                        $(this).find('input, textarea, select').each(function () {
                            $(this).attr('name', $(this).attr('name').replace(/\[[0-9]+\]/g, '[' + i + ']'));
                        });
                    });

                    $.ajax({
                        url: '/insert-location-project',
                        type: 'post',
                        contentType: 'application/json',
                        data: JSON.stringify($(this).serializeJSON())
                    }).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "add_document":
            modal.find('.modal-title').text('Documento');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/add-document-project', {
                project_id: button.data('project_id')
            }, function () {
                modal.find('#add_document_project_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/insert-document-project', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "add_additional_classification":
            modal.find('.modal-title').text('Clasificaciones adicionales');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/add-additional-classification', {
                projectId: button.data('project_id')
            }, function () {
                modal.find('#add-additional-classification_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/insert-additional-classification', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        //Proyectos relacionados
        case "add_related_projects":
            modal.find('.modal-title').text('Proyectos relacionados');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/add-related-projects', {
                projectId: button.data('project_id')
            }, function () {
                modal.find('[name="relatedProject_title"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        modal.find('[name="relatedProject_identifier"]').val('');
                        modal.find('[name="relatedProject_uri"]').val('');

                        $.post('/search-projects', { search: request.term }).done(function(data) {
                            if (data.length == 0) {
                                modal.find('[name="relatedProject_title"]').val('');
                            }
                            response(data);
                        });
                    },
                    close: function (e) {
                        if (modal.find('[name="url"]').val() == '') {
                            modal.find('[name="relatedProject_title"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        modal.find('[name="relatedProject_identifier"]').val(ui.item.projects[0].title);
                        modal.find('[name="relatedProject_title"]').val(ui.item.projects[0].oc4idsIdentifier);
                        modal.find('[name="relatedProject_uri"]').val(ui.item.uri);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                        .data('item.autocomplete', item)
                        .append('<div>' + item.projects[0].oc4ids+'-'+item.projects[0].identifier + '</div>')
                        .appendTo(ul);
                };

                modal.find('#add_related_projects_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/insert-related-projects', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_relatedprocedure":
            modal.find('.modal-title').text('Editar procedimiento relacionado');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editrelatedprocedure-fields', {
                id: button.data('id'),
                ocid: button.data('ocid')
            }, function () {
                modal.find('[name="relatedprocedure_identifier"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        modal.find('[name="url"]').val('');

                        $.post('/search-contractingprocess/', { search: request.term }).done(function(data) {
                            if (data.length == 0) {
                                modal.find('[name="relatedprocedure_identifier"]').val('');
                            }

                            response(data);
                        });
                    },
                    close: function (e) {
                        if (modal.find('[name="url"]').val() == '') {
                            modal.find('[name="relatedprocedure_identifier"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        modal.find('[name="relatedprocedure_identifier"]').val(ui.item.ocid);
                        modal.find('[name="url"]').val(ui.item.record);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.ocid + '</div>')
                      .appendTo(ul);
                };

                modal.find('#editrelatedprocedure_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/edit-relatedprocedure', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_relatedprocedures":
            modal.find('.modal-title').text('Procedimientos relacionados');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/relatedprocedure-list', {
                ocid: button.data('contractingprocess_id'),
                table : 'relatedprocedure'
            }, function () {
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_relatedprocedure') {
                        if (confirm('¿Desea eliminar el procedimiento relacionado?')){
                            $.post('/delete', {
                                id: b.data('id'),
                                table: b.data('table')
                            }).done(function (data) {
                                alert(data.msg);
                                if (data.status === 0) {
                                    b.parent().parent().remove();
    
                                    if (div.children('.panel').length === 0) {
                                        div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado procedimientos relacionados</div>');
                                    }
                                }
                            });
                        }
                    }
                });
            });
            break;
        case "edit_budgetbreakdown":
            modal.find('.modal-title').text('Editar desglose del presupuesto');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editbudgetbreakdown-fields', {
                id: button.data('id'),
                ocid: button.data('ocid')
            }, function () {
                modal.find('#newbudgetbreakdown_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    modal.find('#newbudgetbreakdown_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newbudgetbreakdown_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    modal.find('#newbudgetbreakdown_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('[data-action="new_budgetclassification"]').click(function () {
                    modal.find('.modal-title').text('Líneas presupuestarias');
                    modal.find('#modal_content').html("").load('/newbudgetclassification-fields', {
                        budgetid: $(this).data('id')
                    }, () => initModalBudgetClassification(modal, $(this).data('id')));
                });

                modal.find('[data-action="edit_budgetclassifications"]').click(function () {
                    modal.find('.modal-title').text('Líneas presupuestarias');
                    modal.find('#modal_content').html("").load('/budgetclassification-list', {
                        budgetid: $(this).data('id')
                    }, () => initModalBudgetClassification(modal, $(this).data('id')));
                });

                modal.find('#editbudgetbreakdown_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/edit-budgetbreakdown', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_budgetbreakdowns":
            modal.find('.modal-title').text('Desgloses de presupuestos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/budgetbreakdown-list', {
                ocid: button.data('contractingprocess_id')
            }, function () {
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_budgetbreakdown') {
                        if (confirm('¿Desea eliminar el desglose del presupuesto?')){
                            $.post('/delete', {
                                id: b.data('id'),
                                table: b.data('table')
                            }).done(function (data) {
                                alert(data.msg);
                                if (data.status === 0) {
                                    b.parent().parent().remove();
    
                                    if (div.children('.panel').length === 0) {
                                        div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado desgloses de presupuestos</div>');
                                    }
                                }
                            });
                        }
                    }
                });
            });
            break;
        case "edit_guarantee":
            modal.find('.modal-title').text('Editar garantía');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editguarantee-fields', {
                id: button.data('id'),
                table: button.data('table'),
                ocid: button.data('ocid')
            }, function () {
                modal.find('#newguarantee_date').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                });
                
                modal.find('#newguarantee_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    // modal.find('#newguarantee_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newguarantee_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD'
                }).on("dp.change", function (e) {
                    // modal.find('#newguarantee_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('#editguarantee_form').submit(function (event) {
                    event.preventDefault();

                    $.post('/edit-guarantee', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_guarantees":
            modal.find('.modal-title').text('Garantías');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/guarantee-list', {
                ocid: button.data('contractingprocess_id'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') 
            }, function () {
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_guarantee') {
                        if (confirm('¿Desea eliminar la garantía?')){
                            $.post('/delete', {
                                id: b.data('id'),
                                table: b.data('table')
                            }).done(function (data) {
                                alert(data.msg);
                                if (data.status === 0) {
                                    b.parent().parent().remove();
    
                                    if (div.children('.panel').length === 0) {
                                        div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado garantías</div>');
                                    }
                                }
                            });
                        }
                    }
                });
            });
            break;
        case "edit_quote":
            modal.find('.modal-title').text('Editar cotización');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editquote-fields', {
                id: button.data('id'),
                rid: button.data('rid')
            }, function () {
                // Almacena una copia de los items disponibles en la solicitud
                var items = [];

                // Actualiza el total de la cuantificación
                function updateTotal() {
                    var total = 0;

                    modal.find('#items [name$="quantity"]').each(function (i) {
                        total += parseFloat($(this).val()) || 0;
                    });

                    modal.find('[name="value"]').val(total.toFixed(2));
                }

                // Inicializa el nuevo registro de item
                function initItem(container) {
                    container.find('[name$="quantity"]').val('');
                    container.find('[name$="quantity"]').attr('readonly', 'readonly');

                    var itemOptions = '<option value="">Seleccione una opción</option>';

                    if (items != null) {
                        items.forEach(function (v, i) {
                            itemOptions += '<option value="' + v.classificationid + '">' + v.itemname + '</option>';
                        });
                    }

                    container.find('[name$="itemid"]').html(itemOptions);
                }

                // Actualiza la lista de items por cotizar
                function updateSelectedItem() {
                    var selected = [];

                    modal.find('#items [name$="itemid"]').each(function (i) {
                        var val = $('option:selected', this).val();

                        if (val != '') {
                            selected.push(val);
                        }
                    });

                    modal.find('#items [name$="itemid"]').each(function (i) {
                        var input = $(this);
                        input.find('option').show();

                        selected.forEach(function (v, j) {
                            if (input.val() != v) {
                                input.find('option[value="' + v + '"]').hide();
                            }
                        })
                    });
                }

                setTimeout(() => {
                    var id = modal.find('[name="requestforquotes_id"]').val();

                    // Carga los items disponibles de la solicitud
                    $.post('/load-quote-dependencies/', { id: id }).done(function(data) {
                        items = data.items;
                    });

                    updateSelectedItem();
                }, 500);

                // Inicializa campos de fecha
                modal.find('#newquote_date').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
                
                modal.find('#newquote_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newquote_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date1').data("DateTimePicker").maxDate(e.date);
                });

                // Agrega nuevos items a la cotizacion
                modal.off('click', '[data-action="add_item"]');
                modal.on('click', '[data-action="add_item"]', function (e) {
                    e.preventDefault();
                    var template = modal.find('#itemTemplate').html();

                    var index = new Date().getTime();
                    template = template.replace(/\[0\]/g, '[' + index + ']');

                    var content = $(template).appendTo(modal.find('#items'));
                    initItem(content);
                    updateSelectedItem();
                });

                // Elimina items de la cotizacion
                modal.on('click', '[data-dismiss="item"]', function (e) {
                    e.preventDefault();

                    $(this).parent().remove();

                    if (modal.find('#items').children().length == 0) {
                        var template = modal.find('#itemTemplate').html();

                        var index = new Date().getTime();
                        template = template.replace(/\[0\]/g, '[' + index + ']');

                        var content = $(template).appendTo(modal.find('#items'));
                    }

                    updateTotal();
                    updateSelectedItem();
                });

                // Activa los campos del item cuando este cambia
                modal.off('change', '#items [name$="itemid"]');
                modal.on('change', '#items [name$="itemid"]', function () {
                    var container = $(this).closest('.row');

                    if ($('option:selected', this).val() !== '') {
                        container.find('[name$="quantity"]').removeAttr('readonly');
                    } else {
                        container.find('[name$="quantity"]').val('');
                        container.find('[name$="quantity"]').attr('readonly', 'readonly');
                    }

                    updateTotal();
                    updateSelectedItem();
                });

                // Actualiza el total cuando cambia el valor de un item
                modal.off('change', '#items [name$="quantity"]');
                modal.on('change', '#items [name$="quantity"]', function () {
                    updateTotal();
                });

                // Guarda la cotizacion
                modal.find('#editquote_form').submit(function (event) {
                    event.preventDefault();

                    modal.find('#items').children().each(function (i) {
                        $(this).find('input, textarea, select').each(function () {
                            $(this).attr('name', $(this).attr('name').replace(/\[[0-9]+\]/g, '[' + i + ']'));
                        });
                    });

                    $.ajax({
                        url: '/edit-quote',
                        type: 'post',
                        contentType: 'application/json',
                        data: JSON.stringify($(this).serializeJSON())
                    }).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_quotes":
            modal.find('.modal-title').text('Cotizaciones');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/quote-list', {
                ocid: button.data('contractingprocess_id')
            }, function () {
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_quote') {
                        $.post('/delete', {
                            id: b.data('id'),
                            table: b.data('table'),
                            dependencies: b.data('dependencies'),
                            dkey: b.data('dkey')
                        }).done(function (data) {
                            alert(data.msg);
                            if (data.status === 0) {
                                b.parent().parent().remove();

                                if (div.children('.panel').length === 0) {
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado cotizaciones</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_quote_request":
            modal.find('.modal-title').text('Editar solicitud de cotizacion');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editquoterequest-fields', {
                id: button.data('id'),
                ocid: button.data('ocid')
            }, function () {
                function initAutocomplete(container) {
                    container.find('[name$="itemname"]').autocomplete({
                        minLength: 0,
                        source: function(request, response) {
                            container.find('[name$="itemid"]').val('');
    
                            $.post('/search-item/', { search: request.term, prop: 'description' }).done(function(data) {
                                if (data.length == 0) {
                                    container.find('[name$="itemid"]').val('');
                                }

                                response(data);
                            });
                        },
                        close: function (e) {
                            if (container.find('[name$="itemname"]').val() == '') {
                                container.find('[name$="itemid"]').val('');
                            }
                        },
                        select: function(event, ui) {
                            container.find('[name$="itemid"]').val(ui.item.classificationid);
                            container.find('[name$="itemname"]').val(ui.item.description + ' / ' + ui.item.unit);
                            container.find('[name$="item"]').val(ui.item.description);
                            return false;
                        }
                    }).autocomplete('instance')._renderItem = function (ul, item) {
                        return $('<li>')
                          .data('item.autocomplete', item)
                          .append('<div>' + item.description + ' / ' + item.unit + '</div>')
                          .appendTo(ul);
                    };
                }

                modal.find('#newquote_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date2').data("DateTimePicker").minDate(e.date);
                });

                modal.find('#newquote_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                }).on("dp.change", function (e) {
                    modal.find('#newquote_date1').data("DateTimePicker").maxDate(e.date);
                });

                modal.find('[name="invitedsuppliers"]').multiselect({
                    buttonContainer: '<div class="dropdown"></div>',
                    buttonClass: 'form-control',
                    nonSelectedText: 'Seleccione una opción',
                    nSelectedText: 'Opciones seleccionadas',
                    allSelectedText: 'Opciones seleccionadas'
                });

                modal.off('click', '[data-action="add_item"]');
                modal.on('click', '[data-action="add_item"]', function (e) {
                    e.preventDefault();
                    var template = modal.find('#itemTemplate').html();

                    var index = new Date().getTime();
                    template = template.replace(/\[0\]/g, '[' + index + ']');

                    var content = $(template).appendTo(modal.find('#items'));
                    initAutocomplete(content);
                });

                modal.on('click', '[data-dismiss="item"]', function (e) {
                    e.preventDefault();

                    $(this).parent().remove();

                    if (modal.find('#items').children().length == 0) {
                        var template = modal.find('#itemTemplate').html();

                        var index = new Date().getTime();
                        template = template.replace(/\[0\]/g, '[' + index + ']');

                        var content = $(template).appendTo(modal.find('#items'));
                        initAutocomplete(content);
                    }
                });

                modal.find('#items').children().each(function () {
                    initAutocomplete($(this));
                });

                modal.find('#editquoterequest_form').submit(function (event) {
                    event.preventDefault();

                    modal.find('#items').children().each(function (i) {
                        $(this).find('input, textarea, select').each(function () {
                            $(this).attr('name', $(this).attr('name').replace(/\[[0-9]+\]/g, '[' + i + ']'));
                        });
                    });

                    $.ajax({
                        url: '/edit-quote-request',
                        type: 'post',
                        contentType: 'application/json',
                        data: JSON.stringify($(this).serializeJSON())
                    }).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok') { modal.modal('hide'); }
                    });
                });
            });
            break;
        case "edit_quote_requests":
            modal.find('.modal-title').text('Solicitudes de cotizaciones');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/quoterequest-list', {
                ocid: button.data('contractingprocess_id')
            }, function () {
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_quoterequest') {
                        $.post('/delete', {
                            id: b.data('id'),
                            table: b.data('table'),
                            dependencies: b.data('dependencies'),
                            dkey: b.data('dkey')
                        }).done(function (data) {
                            alert(data.msg);
                            if (data.status === 0) {
                                b.parent().parent().remove();

                                if (div.children('.panel').length === 0) {
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado solicitudes</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        //edit elements
        case "edit_change":
            modal.find('.modal-title').text('Editar modificación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editamendmentchange-fields', {
                id: button.data('id'),
                table: button.data('table')
            }, function () {
                setTimeout(() => {
                    //datepicker
                    modal.find('#newchange_date1').datetimepicker({
                        locale: 'es',
                        format: 'YYYY-MM-DD HH:mm:ss'
                    });

                    //submit new amendment change event
                    modal.find('#editamendmentchange_form').submit(function (event) {
                        $.post('/edit-amendment-change',$(this).serialize()).done(function (data) {
                            alert(data.description);
                            if ( data.status === 'Ok' ){modal.modal('hide');}
                        });
                        event.preventDefault();
                    });
                }, 500);
            });
            break;
        case "edit_changes":
            modal.find('.modal-title').text('Modificaciónes');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load( '/amendmentchange-list/' ,{ 
                ocid: button.data('contractingprocess_id'), 
                table: button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') }, function () {
                //button events
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_change') {
                        $.post('/delete', { id: b.data('id'), table: b.data('table') }).done(function(data){
                            alert(data.msg);
                            if ( data.status === 0 ){
                                b.parent().parent().remove();
                                if(div.children('.panel').length === 0){
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado cambios</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_item":
            modal.find('.modal-title').text('Editar Ítem');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/edititem-fields', {
                id: button.data('id'), 
                table: button.data('table'),
            }, function () {
                $('#edititem_form').find('[name="classification_id"]').autocomplete({
                    minLength: 0,
                    source: function(request, response) {
                        $('#edititem_form').find('[name="classification_description"]').val('');
                        $('#edititem_form').find('[name="unit_name"]').val('');

                        $.post('/search-item/', { search: request.term, prop: 'classificationid' }).done(function(data) {
                            if (data.length == 0) {
                                $('#edititem_form').find('[name="classification_id"]').val('');
                            }

                            response(data);
                        });
                    },
                    close: function (e) {
                        if ($('#edititem_form').find('[name="classification_description"]').val() == '') {
                            $('#edititem_form').find('[name="classification_id"]').val('');
                        }
                    },
                    select: function(event, ui) {
                        $('#edititem_form').find('[name="classification_id"]').val(ui.item.classificationid);
                        $('#edititem_form').find('[name="classification_description"]').val(ui.item.description);
                        $('#edititem_form').find('[name="unit_name"]').val(ui.item.unit);
                        return false;
                    }
                }).autocomplete('instance')._renderItem = function (ul, item) {
                    return $('<li>')
                      .data('item.autocomplete', item)
                      .append('<div>' + item.classificationid + '</div>')
                      .appendTo(ul);
                };

                $('#edititem_form').submit(function (event) {
                    $.post('/edit-item/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "edit_items":
            modal.find('.modal-title').text('Artículos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load( '/item-list/' ,{ 
                ocid: button.data('contractingprocess_id'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') 
            }, function () {
                //button events
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_item') {
                        $.post('/delete', { id : b.data('id'), table: b.data('table') }).done(function(data){
                            alert(data.msg);
                            if ( data.status === 0 ){
                                b.parent().parent().remove();
                                if(div.children('.panel').length === 0){
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado artículos</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_transaction":
            modal.find('.modal-title').text('Editar Transaccion');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/edittransaction-fields', {
                id: button.data('id'),
                table: button.data('table'),
                ocid: button.data('ocid')
            }, function () {
                //datepicker
                modal.find('#newtrans_date1').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });

                //submit new transaction event
                modal.find('#edittransaction_form').submit(function (event) {
                    $.post('/edit-transaction', $(this).serialize()).done(function(data){
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "edit_transactions":
            modal.find('.modal-title').text('Transacciones');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load( '/transaction-list/', { 
                ocid: button.data('contractingprocess_id'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
             }, function () {
                //button events
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_transaction') {
                        $.post('/delete', { id: b.data('id'), table: b.data('table') }).done(function (data) {
                            alert(data.msg);
                            if ( data.status === 0 ){
                                b.parent().parent().remove();
                                if(div.children('.panel').length === 0){
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado transacciones</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_document":
            modal.find('.modal-title').text('Editar Documento');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editdoc-fields', { 
                id: button.data('id'),
                stage: button.data('stage'),
                table: button.data('table'), function () {
                setTimeout(() => {
                    //Date picker
                    modal.find('#newdoc_date1, #newdoc_date2').datetimepicker({
                        locale: 'es',
                        format: 'YYYY-MM-DD HH:mm:ss'
                    });

                    //submit new document event
                    modal.find('#editdoc_form').submit(function (event) {
                        $.post('/edit-document/', $(this).serialize()).done(function (data) {
                            alert(data.description);
                            if (data.status === 'Ok'){ modal.modal('hide'); }
                        });
                        event.preventDefault();
                    });
                }, 500);
            }});
            break;
        case "edit_documents":
            modal.find('.modal-title').text('Documentos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load( '/document-list/' ,{ 
                ocid: button.data('contractingprocess_id'),
                stage: button.data('stage'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid') 
             }, function(){
                //button events
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_document') {
                        $.post('/delete', { id: b.data('id'), table: b.data('table') }).done(function (data) {
                            alert(data.msg);
                            if (data.status === 0){
                                b.parent().parent().remove();

                                if(div.children('.panel').length === 0) {
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado documentos</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_milestone":
            modal.find('.modal-title').text('Editar hito');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/editmilestone-fields', {
                id: button.data('id'), 
                table : button.data('table')
            }, function () {
                // Submit new milestone event
                $('#editmilestone_form').submit(function (event) {
                    $.post('/edit-milestone/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
                //datepickers
                $('#newmilestone_date1, #newmilestone_date2').datetimepicker({
                    locale: 'es',
                    format: 'YYYY-MM-DD HH:mm:ss'
                });
            });
            break;
        case "edit_milestones":
            modal.find('.modal-title').text('Hitos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load( '/milestone-list/', { 
                ocid: button.data('contractingprocess_id'),
                table : button.data('table'),
                fkname: button.data('fkname'),
                fkid: button.data('fkid')
            }, function () {
                //button events
                var div = modal.find('#modal_content');

                div.find('[data-action]').click(function () {
                    var b = $(this);

                    if (b.data('action') == 'delete_milestone') {
                        $.post('/delete', { id: b.data('id'), table: b.data('table') }).done(function(data){
                            alert(data.msg);
                            if ( data.status === 0 ){
                                b.parent().parent().remove();
                                if(div.children('.panel').length === 0){
                                    div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado hitos</div>');
                                }
                            }
                        });
                    }
                });
            });
            break;
        case "edit_uris":
            modal.find('.modal-title').text('Metadatos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/uris/',{ id: button.data('contractingprocess_id') }, function () {
                // Edit publisher submit event
                $('#uri_form').submit(function (event) {
                    $.post('/update-uris/', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "edit_uris_project":
            modal.find('.modal-title').text('Metadatos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/uris-project/',{ id: button.data('project_id') }, function () {
            });
            break;
        case "show_logs":
            modal.find('.modal-title').text('Historial');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/logs/', { id: button.data('contractingprocess_id') }, function () {
                
            });
            break;
        case "edit_user":
            modal.find('.modal-title').text('Actualizar información del usuario');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/user-profile', { id : button.data('user_id')}, function () {
                $('#form_update_user_profile').submit(function (event) {
                    $.post('/update/user', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide');}
                    });
                    event.preventDefault();
                });
            });
            break;
        case "edit_user_admin":
                modal.find('.modal-title').text('Actualizar información del usuario');
                modal.find('#modal_content').html("");
                modal.find('#modal_content').load('/user-profile-admin', { id : button.data('user_id')}, function () {
                    $('#form_update_user_profile_admin').submit(function (event) {
                        $.post('/update/user', $(this).serialize()).done(function (data) {
                            alert(data.description);
                            if (data.status === 'Ok'){ modal.modal('hide');}
                        });
                        event.preventDefault();
                    });
                });
                break;
        case "delete_user":
            modal.find('.modal-title').text('Eliminar usuario');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/delete-user', { id : button.data('user_id') }, function () {
                $('#form_delete_user').submit(function (event) {
                    $.post('/delete/user', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide'); }
                    });
                    event.preventDefault();
                });
            });
            break;
        case "update_password":
            modal.find('.modal-title').text('Actualizar contraseña');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/change-password', { id : button.data('user_id')}, function () {
                $('#form_update_user_password').submit(function (event) {

                    if ( $('input[name = new_pass]').val().length >= 8 ) {
                        $.post('/update/password', $(this).serialize()).done(function (data) {
                            alert(data.description);
                            if (data.status === 'Ok') {
                                modal.modal('hide');
                            }
                        });
                    } else{
                        alert('La contraseña debe tener una longitud de al menos 8 caracteres.');
                    }
                    event.preventDefault();
                });
            });
            break;
        case "search":
            modal.find('.modal-title').text('Buscar contratación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/search',{user_id : button.data('user_id')}, function () {
                $('#searchprocessbyocid_form').submit(function (event) {
                    $('#searchprocess_result').load('/search-process-by-ocid/', $(this).serializeArray());
                    event.preventDefault();
                });
                $('#searchprocessbydate_form').submit(function (event) {
                    $('#searchprocess_result').load('/search-process-by-date/', $(this).serializeArray());
                    event.preventDefault();
                });
            });
            break;
        case "delete_contratacion":
            modal.find('.modal-title').text('Eliminar contratación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/delete-contratacion', { id : button.data('id') }, function () {
                $('#form_delete_contratacion').submit(function (event) {
                    $.post('/delete/contratacion', $(this).serialize()).done(function (data) {
                        alert(data.description);
                        if (data.status === 'Ok'){ modal.modal('hide'); }
                    });
                    event.preventDefault();
                });
            });
            break;           
            
        case "manual":
            modal.find('.modal-title').text('Manual de Contrataciones Abiertas');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/manual/');
            break;
       case 'new_clarification':
            var cp = button.data('contractingprocess_id');
            modal.find('.modal-title').text('Agregar Junta de Aclaración');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/clarificationmeetings/'+ cp + '/fields', () => initModalClarificationMeetingFields(modal));
       break;
       case 'edit_clarification':
            modal.find('.modal-title').text('Juntas de Aclaraciones');
            modal.find('#modal_content').html("");
            loadModalClarificationMeetingList(modal, button);
       break;
       case 'import':
            var cp = button.data('contractingprocess_id');
            var stage = button.data('stage');
            var id = button.data('id');
            modal.find('.modal-title').text('Importación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load(`/main/${cp}/import/${stage}/${id}`, () =>  {
                
                
                let loading = () => {
                    if(importing){
                        modal.find('.import-container').addClass('hidden');
                        modal.find('h3').removeClass('hidden');
                    } else {
                        modal.find('.import-container').removeClass('hidden');
                        modal.find('h3').addClass('hidden');
                    }
                }

                loading();
               
                modal.find('#frmImport').submit(function(e){
                    e.preventDefault();
                    if (!importing) {                    
                        const formData = new FormData();
                        formData.append('datafile', $(this).find('input:file').get(0).files[0]);
                        importing = true;
                        loading();
                        $.ajax({
                            url: `/main/${cp}/import/${stage}/${id}`,
                            type: 'post',
                            data: formData,
                            cache: false,
                            contentType: false,
                            processData: false,
                            success: res => {
                                location.reload();
                                alert(res);
                            },
                            error: function(err) {
                                importing = false;
                                loading();
                                alert(err.responseText || ' No se ha podido realizar la importación');
                            }
                        });
                    }
                });
            });
        break;
        case 'pnt_status':
        var cp = button.data('contractingprocess_id');
        modal.find('.modal-title').text('Conexión a Servicio PNT');
        modal.find('#modal_content').html("");
        modal.find('#modal_content').load(`/pnt-status/${cp}`, () => {
            if(modal.find('.json').length > 0){
                modal.find('.modal-dialog').css('width', '80%');
            }
        });
       
      
        break;
    }
});



let loadModalClarificationMeetingList = (modal, button) => {
    modal.find('#modal_content').load('/clarificationmeetings/' + button.data('contractingprocess_id'), () => {
        modal.find('[data-editar]').click(function() {
            var cp = $(this).data('contractingprocess_id');
            modal.find('.modal-title').text('Editar Junta de Aclaración');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load(`/clarificationmeetings/${cp}/fields/${$(this).data('editar')}`, () => initModalClarificationMeetingFields(modal) );
        });

        modal.find('[data-eliminar]').click(function() {
            if(confirm('¿Desea eliminar esta junta de aclaración?')){
                $.post(`/clarificationmeetings/${$(this).data('contractingprocess_id')}/${$(this).data('eliminar')}/delete`, res => {
                    alert(res.message);
                    loadModalClarificationMeetingList(modal, button);
                });
            }
        });
    });
}

let initModalClarificationMeetingFields = (modal) => {

    // configurar selector multiple de asistentes
    modal.find('[name="attenders"], [name="officials"]').multiselect({
        buttonWidth: '100%',
        dropRight: true,
        enableFiltering: true,
        nonSelectedText: 'Seleccione una opción',
        nSelectedText: 'seleccionados',
        allSelectedText: 'Todos',
        filterPlaceholder: 'Búsqueda',
        numberDisplayed: 4
    });

    modal.find('h4[title],label[title]').tooltip();

    modal.find('[name="date"]').datetimepicker({
        locale: 'es',
        format: 'YYYY-MM-DD HH:mm:ss'
    });

    // guardado
    modal.find('#frmClarification').submit(function(e){
        e.preventDefault();
        if($(this).find('[name="attenders"]').val().length === 0) {
            alert('Debe seleccionar por lo menos un asistente');
            return false;
        }
        if($(this).find('[name^="officials"]').length === 0) {
            alert('Debe agregar por lo menos a un servidor público');
            return false;
        }
       
        let params = {
            id: $(this).find('[name="id"]').val(),
            contractingprocess_id: $(this).find('[name="contractingprocess_id"]').val(),
            clarificationmeetingid: $(this).find('[name="clarificationmeetingid"]').val(),
            date: $(this).find('[name="date"]').val(),
            attenders: $(this).find('[name="attenders"]').val(),
            officials: $(this).find('[name="officials"]').val(),
        };

        $.ajax({
            url: `/clarificationmeetings/${params.contractingprocess_id}/fields`,
            type: 'post',
            contentType: 'application/json',
            data: JSON.stringify(params),
            success: res => {
                alert(res.message);
                modal.modal('hide');
            },
            error: res => {
                alert(res.responseJSON.message)
            }
        });
    });
}

let initModalMember = (modal, actor) => {

    let loadMembers = ()=> {
        modal.find('.modal-title').text('Miembros');
        modal.find('#modal_content').load('/members/' +  actor, () => initModalMember(modal, actor));
    }

    // registro de miembro
    modal.find('#frmMiembro').submit(function(e) {
        e.preventDefault();
        $.post('/member/fields/'+actor, $(this).serializeArray(), res => {
            alert(res.message);
            loadMembers();
        }).fail(res => alert(res.responseJSON.message));
    });

    // editar
    modal.find('[data-editar]').click(function() {
        modal.find('.modal-title').text('Editar Miembro');
        modal.find('#modal_content').load(`/member/fields/${actor}/${$(this).data('editar')}`, () => initModalMember(modal, actor));
    });

     // eliminar
     modal.find('[data-eliminar]').click(function() {
        if(confirm('¿Desea eliminar al miembro?')){
            $.post(`/member/delete/${$(this).data('eliminar')}`, res => {
                alert(res.message);
                loadMembers();
            }).fail(res => alert(res.responseJSON.message));
        }
    });
}

let initModalContactPoint = (modal, party) => {
    let loadContactPoints = () => {
        modal.find('.modal-title').text('Puntos de contacto adicional');
        modal.find('#modal_content').load('/contactpoint-list', {
            partyid: party
        }, () => initModalContactPoint(modal, party));
    }

    modal.find('[name="language"]').multiselect({      
        buttonContainer: '<div class="dropdown"></div>',
        buttonClass: 'form-control',
        nonSelectedText: 'Seleccione una opción',
        enableHTML: true,
        enableFiltering: true,
        nSelectedText: 'seleccionados',
        allSelectedText: 'Todos',
        filterPlaceholder: 'Búsqueda',
    });

    modal.find('[data-action="edit_contactpoint"]').click(function () {
        modal.find('.modal-title').text('Editar punto de contacto adicional');
        modal.find('#modal_content').load('/editcontactpoint-fields', {
            id: $(this).data('id')
        }, () => initModalContactPoint(modal, party));
    });

    modal.find('[data-action="delete_contactpoint"]').click(function () {
        var b = $(this);
        var div = modal.find('#modal_content');

        if(confirm('¿Desea eliminar el punto de contacto adicional?')) {
            $.post('/delete', {
                id: b.data('id'),
                table: 'additionalcontactpoints',
            }).done(function (data) {
                alert(data.msg);

                if (data.status === 0) {
                    b.parent().parent().remove();
    
                    if (div.children('.panel').length === 0) {
                        div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado puntos de contacto adicional</div>');
                    }
                }
            });
        }
    });

    modal.find('#newcontactpoint_form').submit(function (event) {
        event.preventDefault();

        $.post('/new-contactpoint', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.message);
                loadContactPoints();
            }
        });
    });

    modal.find('#editcontactpoint_form').submit(function (event) {
        event.preventDefault();

        $.post('/edit-contactpoint', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.message);
                loadContactPoints();
            }
        });
    });
}

let initModalAdditionalIdentifiers = (modal, party) => {
    
    modal.find('#add_additional_identifiers_form').submit(function (event) {
        event.preventDefault();

        $.post('/1.1/new-additional-identifiers', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.description);
                modal.modal('hide');
            }
        });
    });

    $('button[name="edit_additional_identifiers"]').click(function () {
        let id = $(this).data('identifier_id');
        modal.find('.modal-title').text("Editar");
            modal.find("#modal_content").load('/1.1/edit_additional_identifier.html', { identifier_id: id},function(){ 
                //Update aditional identifiers party project   
                $('#update_additional_identifiers_form').submit(function (e) {
                    $.post('/1.1/update_additional_identifier', $(this).serialize()).done(function (data) {
                        alert( data.description );
                        if ( data.status === 'Ok'){ modal.modal('hide');}
                    });
                    e.preventDefault();
                });    
        });
    });
    //delete aditional identifiers party project
    $('button[name="delete_additional_identifiers"]').click(function () {
        if (confirm("¿Está seguro de eliminar el registro?")){
            $.ajax({
                url: "/1.1/delete_additional_identifier",
                method: "DELETE",
                data: {identifier_id : $(this).data("identifier_id")},
                success:  function (data) {
                    alert(data.description);
                    if (data.status === 'Ok'){ modal.modal('hide');}
                }
            })
        }
    });
}


let initModalBudgetLines = (modal, party) => {
    
    modal.find('#add_budget_lines_form').submit(function (event) {
        event.preventDefault();

        $.post('/1.1/new-budget-lines', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.description);
                modal.modal('hide');
            }
        });
    });
    //edit budget line project
    $('button[name="edit_budget_line"]').click(function () {
        let id = $(this).data('budget_line_component_id');
        modal.find('.modal-title').text("Editar");
            modal.find("#modal_content").load('/1.1/edit_budget_line.html', { budget_line_component_id: id},function(){ 
                //Update budget line project   
                $('#update_budget_line_form').submit(function (e) {
                    $.post('/1.1/update_budget_line', $(this).serialize()).done(function (data) {
                        alert( data.description );
                        if ( data.status === 'Ok'){ modal.modal('hide');}
                    });
                    e.preventDefault();
                }); 
                //add budget line measure project
                modal.find('[data-action="add_budget_line_measure"]').click(function () {
                    modal.find('.modal-title').text('Momentos presupuestarios');
                    modal.find('#modal_content').html("").load('/add-budget-line-measure', {
                        budgetLineId: $(this).data('id')
                    }, function(){
                        modal.find('#budget_measureDate').datetimepicker({
                            locale: 'es',
                            format: 'YYYY-MM-DD HH:mm:ss'
                        });
                        modal.find('#add_budget_line_measure_form').submit(function (event) {
                            event.preventDefault();
                            $.post('/1.1/new-budget-line-measure', $(this).serialize()).done(function (data) {
                                if (data.status === 'Ok') {
                                    alert(data.description);
                                    modal.modal('hide');
                                }
                            });
                        })
                    });
                });      
                //edit budget line measure project
                modal.find('[data-action="edit_budget_line_measure"]').click(function () {
                    modal.find('.modal-title').text('Momentos presupuestarios');
                    modal.find('#modal_content').html("").load('/edit-budget-line-measure', {
                        budgetLineId: $(this).data('id')
                    }, function(){
                        $('button[name="edit_measure"]').click(function () {
                            let id = $(this).data('budget_line_measure_id');
                            modal.find('.modal-title').text("Editar");
                            modal.find('#modal_content').html("").load('/1.1/edit_budget_line_measure.html', {
                                budgetLineMeasureId: id
                            }, function(){
                                modal.find('#update_budget_line_measure_form').submit(function (event) {
                                    event.preventDefault();
                                    $.post('/1.1/update_budget_line_measure', $(this).serialize()).done(function (data) {
                                        if (data.status === 'Ok') {
                                            alert(data.description);
                                            modal.modal('hide');
                                        }
                                    });
                                })
                            });
                        });
                        //delete aditional identifiers party project
                        $('button[name="delete_measure"]').click(function () {
                            if (confirm("¿Está seguro de eliminar el registro?")){
                                $.ajax({
                                    url: "/1.1/delete_budget_line_measure",
                                    method: "DELETE",
                                    data: {budget_line_measure_id : $(this).data("budget_line_measure_id")},
                                    success:  function (data) {
                                        alert(data.description);
                                        if (data.status === 'Ok'){ modal.modal('hide');}
                                    }
                                })
                            }
                        });
                    });
                });  
        });
    });
    //delete budget line project
    $('button[name="delete_budget_line"]').click(function () {
        if (confirm("¿Está seguro de eliminar el registro?")){
            $.ajax({
                url: "/1.1/delete_budget_line",
                method: "DELETE",
                data: {budget_line_id : $(this).data("budget_line_id")},
                success:  function (data) {
                    alert(data.description);
                    if (data.status === 'Ok'){ modal.modal('hide');}
                }
            })
        }
    });
}

let initModalBudgetClassification = (modal, budget) => {
    let loadBudgetClassifications = () => {
        modal.find('.modal-title').text('Líneas presupuestarias');
        modal.find('#modal_content').load('/budgetclassification-list', {
            budgetid: budget
        }, () => initModalBudgetClassification(modal, budget));
    }

    modal.find('[data-action="edit_budgetclassification"]').click(function () {
        modal.find('.modal-title').text('Editar líneas presupuestarias');
        modal.find('#modal_content').load('/editbudgetclassification-fields', {
            id: $(this).data('id')
        }, () => initModalBudgetClassification(modal, budget));
    });

    modal.find('[data-action="delete_budgetclassification"]').click(function () {
        var b = $(this);
        var div = modal.find('#modal_content');

        if(confirm('¿Desea eliminar la clasificación del presupuesto?')) {
            $.post('/delete', {
                id: b.data('id'),
                table: 'budgetclassifications',
            }).done(function (data) {
                alert(data.msg);

                if (data.status === 0) {
                    b.parent().parent().remove();
    
                    if (div.children('.panel').length === 0) {
                        div.html('<div class="alert alert-warning" role="alert"><strong>Atención:</strong> No se han registrado líneas presupuestarias</div>');
                    }
                }
            });
        }
    });

    modal.find('[name="year"]').change(function (event) {
        event.preventDefault();
        var year = $('option:selected', this).val();

        $.post('/search-requestingunit/', { year: year }).done(function(data) {
            var unitOptions = '<option value="">Seleccione una opción</option>';

            if (data != null) {
                data.forEach(function (v, i) {
                    unitOptions += '<option value="' + v.value + '">' + v.name + '</option>';
                });
            }

            modal.find('[name="requestingunit"]').html(unitOptions);
        });
    });

    modal.find('[name="requestingunit"]').change(function (event) {
        event.preventDefault();
        var year = modal.find('[name="year"] option:selected').val();
        var requiredunit = $('option:selected', this).val();

        if (year != '' && requiredunit != null) {
            $.post('/search-programaticstructure/', { year: year, requiredunit: requiredunit }).done(function(data) {
                if (data != null) {
                    Object.keys(data).forEach(function(v, i) {
                        if (['year', 'id', 'specificactivity', 'spendingtype', 'budgetsource', 'spendingobject'].indexOf(v) === -1) {
                            modal.find('[name="' + v + '"]').val(data[v]);
                        }
                    });
                } else {
                    modal.find('input[data-source="programaticstructure"]').each(function () {
                        $(this).val('');
                    });
                }
            });
        } else {
            modal.find('input[data-source="programaticstructure"]').each(function () {
                $(this).val('');
            });
        }

        modal.find('[name="specificactivity"]').html('<option value="">Seleccione una opción</option>');
        modal.find('[name="spendingobject"]').html('<option value="">Seleccione una opción</option>');
        modal.find('input[data-source="departure"]').each(function () {
            $(this).val('');
        });
        
        $.post('/search-activitymir/', { year: year,ue: requiredunit }).done(function(data) {
            var mirOptions = '<option value="">Seleccione una opción</option>';

            if (data != null) {
                data.forEach(function (v, i) {
                    mirOptions += `<option value="${v.value}">${v.name}</option>`;
                });
            }

            modal.find('[name="specificactivity"]').html(mirOptions);
        });
    });

    modal.find('[name="specificactivity"]').change(function (event) {
        event.preventDefault();
        var year = modal.find('[name="year"] option:selected').val();
        var mir = $('option:selected', this).val();
        var requiredunit = $('[name="requestingunit"]').val();

        modal.find('[name="spendingobject"]').html('<option value="">Seleccione una opción</option>');
        modal.find('input[data-source="departure"]').each(function () {
            $(this).val('');
        });

        $.post('/search-departure/', { year: year, mir: mir, ue: requiredunit }).done(function(data) {
            var objectOptions = '<option value="">Seleccione una opción</option>';

            if (data != null) {
                data.forEach(function (v, i) {
                    objectOptions += `<option value="${v.value}" data-budgetsource="${v.budgetsource}" data-spendingtype="${v.spendingtype}">${v.name}</option>`;
                });
            }

            modal.find('[name="spendingobject"]').html(objectOptions);
        });
    });

    modal.find('[name="spendingobject"]').change(function (event) {
        event.preventDefault();
        var data = $('option:selected', this).data();

        if (Object.keys(data).length > 0) {
            Object.keys(data).forEach(function(v, i) {
                modal.find('[name="' + v + '"]').val(data[v]);
            })
        } else {
            modal.find('input[data-source="departure"]').each(function () {
                $(this).val('');
            });
        }
    });

    modal.find('#newbudgetclassification_form').submit(function (event) {
        event.preventDefault();

        $.post('/new-budgetclassification', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.description);
                loadBudgetClassifications();
            }
        });
    });

    modal.find('#editbudgetclassification_form').submit(function (event) {
        event.preventDefault();

        $.post('/edit-budgetclassification', $(this).serialize()).done(function (data) {
            if (data.status === 'Ok') {
                alert(data.description);
                loadBudgetClassifications();
            }
        });
    });
}

$(document).on('click', '[data-show="modal"]', function (e) {
    var target = $(this).data('target');
    $(target).modal('show', e.currentTarget);
});

// Esto arregla el problema de doble modal al mismo tiempo
$(document).on('hidden.bs.modal', '.modal', function () {
    $('.modal:visible').length && $(document.body).addClass('modal-open');
});

$('#frmTenderStatus, #frmAwardStatus, #frmImplementationStatus, #frmContractStatus').submit(function(e) {
    e.preventDefault();

    var form = $(this);
    const cpid = form.find('[name="cpid"]').val();
  
    let stage = form.find('[name="stage"]').val();

    setTags(cpid, stage, function(tags) {
        var params = form.serializeArray();

        tags.forEach(element => {
            params.push({ name: element.name, value: element.value });
        });
        

        $.post('/process/status', params, res => {
            alert(res);
            location.reload();
        }).fail(res => alert(res.responseText));
    });


   
});

$('#generatePackage').click(function(){
    let id = $(this).data('id');
    var modal = $('#genericModal');
    modal.find('.modal-title').text('Paquete de Registros');
    modal.find('#modal_content').html("");
    modal.find('#modal_content').load('/record-package-period-selector/' + id ,() => {
       
        modal.find('[name="mode"]').change(function(){
            let mode = $(this).val();
            modal.find('#trimester, #year').addClass('hide').find('select').val('').removeAttr('required');
            modal.find('#' + mode).removeClass('hide').find('select').attr('required', true);
            if(mode === 'trimester'){
                modal.find('#year').removeClass('hide').find('select').attr('required', true);
            }
        });

        modal.find('#frmPackage').submit(function(e){
            e.preventDefault();
            let mode = $(this).find('[name="mode"]').val(),
                 ocid = $(this).find('[name="ocid"]').val(),
                 value = $(this).find('[name="year"]').val()+'-'+$(this).find('[name="trimester"]').val()||$(this).find('[name="year"]').val()||''
            let params = `${ocid}/${mode}/${value}`;
            
            var link = document.createElement('a');
                link.href = '/record-package-period/'+params;
                link.download = `record-package-${ocid}-${mode}${value}.json`;;
                link.click();
        });

        modal.modal('show');
    });
   
});

$('#testter').click(function(){
    let id = $(this).data('id');
    var modal = $('#genericModal');
    modal.find('.modal-title').text('Paquete de Registros');
    modal.find('#modal_content').html("");
    modal.find('#modal_content').load('/record-package-period-selector/' + id ,() => {
       
        modal.find('[name="mode"]').change(function(){
            let mode = $(this).val();
            modal.find('#trimester, #year').addClass('hide').find('select').val('').removeAttr('required');
            modal.find('#' + mode).removeClass('hide').find('select').attr('required', true);
            if(mode === 'trimester'){
                modal.find('#year').removeClass('hide').find('select').attr('required', true);
            }
        });

        modal.find('#frmPackage').submit(function(e){
            e.preventDefault();
            let mode = $(this).find('[name="mode"]').val(),
                 ocid = $(this).find('[name="ocid"]').val(),
                 value = $(this).find('[name="year"]').val()+'-'+$(this).find('[name="trimester"]').val()||$(this).find('[name="year"]').val()||''
            let params = `${ocid}/${mode}/${value}`;
            
            var link = document.createElement('a');
                link.href = '/record-package-period/'+params;
                link.download = `record-package-${ocid}-${mode}${value}.json`;;
                link.click();
        });

        modal.modal('show');
    });
});