// FORMATO B
const FORMAT = 43336;
const FormatFunctions = require('./format-functions');

/**
 * Armar estructura del formato "Resultados adjudicaciones, invitaciones y licitaciones_Procedimientos de licitación pública e invitación a cuando menos tres personas"
 * @param {Object} release Json del release
 * @param {Array} recordsPnt Registros en PNT
 * @param {Number} position Numero de registro
 * @param {Object} extras Datos que no se pueden obtener del release
 */
let build = (release, recordsPnt, position, extras) => {
    // iniciar proceso para obtener todos los datos del formato

    // crear instancia para obtener funciones 
    const fn = new FormatFunctions(release, recordsPnt, position);

    release.contracts.map(contract => {

        fn.addField(334280, 'ejercicio', extras, undefined, true, 'Ejercicio');

        // calcular trimestre
        
        let date = new Date(fn.findValue(`tender.tenderPeriod.startDate`, release));
        const quarter = Math.floor(date.getMonth() / 3);
        const start = new Date(date.getFullYear(),quarter*3,1);
        const end = new Date(date.getFullYear(),(quarter*3)+2,1);
        end.setMonth(end.getMonth() + 1);
        end.setDate(end.getDate() - 1);

        fn.add(334314, extras.reportingperiodstartdate.toISOString(), date => fn.dateFormat(date), true, 'Fecha de inicio del periodo que se informa');
        fn.add(334315, extras.reportingperiodenddate.toISOString(), date => fn.dateFormat(date), true, 'Fecha de término del periodo que se informa');

        fn.addField(334323, 'tender.procurementMethodDetails', undefined, value => {
            switch (value) {
                case 'Licitación pública':
                    value = 0;
                    break;
                case 'Invitación a cuando menos tres personas':
                    value = 1;
                    break;
                default:
                    value = 2;
                    break;
            }
            return value;
        });
        fn.addField(334304, 'tender.additionalProcurementCategories[0]', undefined, value => {
            switch (value) {
                // este no esta en el catalogo de pnt
                case 'goodsAcquisition':
                    value = 2;
                    break;
                case 'goodsLease':
                    value = 3;
                    break;
                case 'services':
                    value = 4;
                    break;
                case 'worksRelatedServices':
                    value = 1;
                    break;
                case 'works':
                    value = 0;
                    break;
            }
            return value;
        });


        fn.addTable(334277, 'parties[?(@.roles.indexOf("invitedSupplier")!==-1)]', (party, results) => {
            fn.addInternalField(43317, `identifier.givenName`, party, results);
            fn.addInternalField(43318, `identifier.patronymicName`, party, results);
            fn.addInternalField(43319, `identifier.matronymicName`, party, results);
            fn.addInternalField(43320, `identifier.legalName`, party, results);
            fn.addInternalField(43321, `id`, party, results);
        });

        fn.addField(334278, `tender.id`);

        let values = fn.findValues(`tender.documents[?(@.documentType==="tenderNotice")].url`);
        fn.add(334331, values.join(','));

        fn.addField(334332, `tender.tenderPeriod.startDate`, undefined, date => fn.dateFormat(date));

        fn.addField(334287, `tender.description`);

        fn.addTable(334306, 'parties[?(@.roles.indexOf("tenderer")!==-1)]', (party, results) => {
            fn.addInternalField(43322, `identifier.givenName`, party, results);
            fn.addInternalField(43323, `identifier.patronymicName`, party, results);
            fn.addInternalField(43324, `identifier.matronymicName`, party, results);
            fn.addInternalField(43325, `identifier.legalName`, party, results);
            fn.addInternalField(43326, `id`, party, results);
        });

        let juntas = fn.findValues('tender.clarificationMeetings[0]');
        if (juntas) {
            juntas.map(junta => {
                fn.addField(334334, 'date', junta, date => fn.dateFormat(date));

                fn.addTable(334307, 'attendees', (party, results) => {
                    fn.addInternalField(43327, `parties[?(@.id==="${party.id}")].identifier.givenName`, release, results);
                    fn.addInternalField(43328, `parties[?(@.id==="${party.id}")].identifier.patronymicName`, release, results);
                    fn.addInternalField(43329, `parties[?(@.id==="${party.id}")].identifier.matronymicName`, release, results);
                    fn.addInternalField(43330, `parties[?(@.id==="${party.id}")].identifier.legalName`, release, results);
                    fn.addInternalField(43331, `parties[?(@.id==="${party.id}")].id`, release, results);
                }, junta);

                fn.addTable(334308, 'officials', (party, results) => {
                    fn.addInternalField(43332, `parties[?(@.id==="${party.id}")].identifier.givenName`, release, results);
                    fn.addInternalField(43333, `parties[?(@.id==="${party.id}")].identifier.patronymicName`, release, results);
                    fn.addInternalField(43334, `parties[?(@.id==="${party.id}")].identifier.matronymicName`, release, results);
                    fn.addInternalField(43335, `parties[?(@.id==="${party.id}")].position`, release, results);
                    fn.addInternalField(43336, `parties[?(@.id==="${party.id}")].id`, release, results);
                }, junta);
            });
        }

        values = fn.findValues(`tender.documents[?(@.documentType==="clarifications")].url`);
        fn.add(334279, values.join(','));

        values = fn.findValues(`tender.documents[?(@.documentType==="openingOfProposals")].url`);
        fn.add(334335, values.join(','));

        values = fn.findValues(`awards[?(@.id==="${contract.awardID}")].documents[?(@.documentType==="evaluationReports")].url`);
        fn.add(334275, values.join(','));

        let awardSupplier = fn.findValues(`awards[?(@.id==="${contract.awardID}")].suppliers[0]`);
        if (awardSupplier) {
            awardSupplier.map(x => {
                fn.addField(334324, `parties[?(@.id==="${x.id}")].identifier.givenName`);
                fn.addField(334316, `parties[?(@.id==="${x.id}")].identifier.patronymicName`);
                fn.addField(334317, `parties[?(@.id==="${x.id}")].identifier.matronymicName`);
                fn.addField(334318, `parties[?(@.id==="${x.id}")].identifier.legalName`);
                fn.addField(334325, `parties[?(@.id==="${x.id}")].id`);
            });
        }

        values = fn.findValues(`awards[?(@.id==="${contract.awardID}")].rationale`);
        fn.add(334326, values[0]);

        

        fn.addField(334281, 'id', contract);
        fn.addField(334290, 'dateSigned', contract, date => fn.dateFormat(date), true, 'Fecha de contrato');
        fn.addField(334295, 'value.netAmount', contract);
        fn.addField(334296, 'value.amount', contract);

        fn.addField(334294, 'tender.minValue.amount');
        fn.addField(334297, 'tender.value.amount');

        fn.addField(334283, 'value.currency', contract);
        fn.addFields(334282, 'value.exchangeRates[*].rate', contract);
        fn.addField(334327, 'implementation.transactions[0].paymentMethod', contract, paymentMethod => {
            switch(paymentMethod) {
                case 'letterOfCredit':  return 'Carta de crédito';
                case 'check':  return 'Cheque';
                case 'cash':  return 'Efectivo';
                case 'corporateCard':  return 'Tarjeta corporativa';
                case 'wireTransfe':  return 'Transferencia bancaria';
            }
        });
        fn.addField(334288, 'description', contract);
        fn.addField(334292, 'period.startDate', contract, date => fn.dateFormat(date));
        fn.addField(334291, 'period.endDate', contract, date => fn.dateFormat(date));
        values = fn.findValues('documents[?(@.documentType==="contractSigned")].url', contract);
        values = values.concat(fn.findValues('documents[?(@.documentType==="contractAnnexe")].url', contract));
        fn.add(334301, values.join(','));
        values = fn.findValues('documents[?(@.documentType==="suspensionNotice")].url', contract);
        fn.add(334302, values.join(','));

        values = fn.findValues(`planning.budget.budgetBreakdown[*].budgetLines[*].components[?(@.name==="spendingObject")].code`);
        values = {'temp': values};
        
        fn.addTable(334309, 'temp', (code, results) => {
            fn.addInternal(43337, code,results);
        }, values);

        if(extras.requestingUnits){
            values = [];
            extras.requestingUnits.forEach(element => {
                values.push(element.party_legal_name);
            });
            fn.add(334285, values.filter(x => x !== undefined && x !== null).join(', '));
        }

        if(extras.contractingUnits){
            values = [];
            extras.contractingUnits.forEach(element => {
                values.push(element.party_legal_name);
            });
            fn.add(334284, values.filter(x => x !== undefined && x !== null).join(', '));
        }
        
        if(extras.responsibleUnits){
            values = [];
            extras.responsibleUnits.forEach(element => {
                values.push(element.party_legal_name);
            });
            fn.add(334286, values.filter(x => x !== undefined && x !== null).join(', '));
        }

        values = fn.findValues(`planning.budget.budgetBreakdown[*]`);
        values = {'temp': values};
        if(values.temp.length > 0){
            if(values.temp[0].origin !== undefined){
                var val = null;
                switch (values.temp[0].origin) {
                    case 'Federales':
                        val = 0;
                        break;
                    case 'Estatales':
                        val = 1;
                        break;
                    case 'Municipales':
                        val = 2;
                        break;
                }
                fn.add(334313, val);
            }
            if(values.temp[0].fundType !== undefined){
                fn.add(334276, values.temp[0].fundType);
            }
            if(values.temp[0].budgetLines !== undefined && values.temp[0].budgetLines.length > 0){
                if(values.temp[0].budgetLines[0].components[12].description !== undefined){
                    fn.add(334333, values.temp[0].budgetLines[0].components[12].description);
                }
            }
        }
        
        
        let address = fn.findValue('items[?(@.deliveryAddress)].deliveryAddress', contract);
        if(address){
            values = [];
            values.push(address.streetAddress);
            values.push(address.locality);
            values.push(address.region);
            values.push(address.postalCode);
            values.push(address.countryName);
            fn.add(334328, values.filter(x => x !== undefined && x !== null).join(', '));
        }
        values = fn.findValues('description', contract);
        fn.add(334319, values.join(','));
        fn.addField(334329, 'planning.documents[?(@.documentType==="environmentalImpact")].url');

        fn.addFields(334330, 'implementation.milestones[?(@.type==="publicNotices")].description', contract);

        fn.addField(334320, 'implementation.status', contract, status => {
            switch (status) {
                case 'planning': status = 0; break;
                case 'ongoing': status = 1; break;
                // esta no existe en pnt
                case 'concluded': status = 2; break;
                case 'terminated': status = 2; break;
            }
            return status;
        });

        value = fn.findValue('amendments[?(@.date)].date', contract);
        fn.add(334305, value ? 0 : 1);

        fn.addTable(334310, 'amendments', (amendment, results) => {
            fn.addInternalField(43338, 'id', amendment, results);
            fn.addInternalField(43339, 'description', amendment, results);
            fn.addInternalField(43340, 'date', amendment, results, date => fn.dateFormat(date));
            fn.addInternalField(43341, 'documents[?(@.documentType==="contractAmendment")].url', contract, results);
        }, contract);

        fn.addField(334289, 'surveillanceMechanisms', contract, value => {
            return value.map(x => {
                switch(x) {
                    case 'socialWitness': return 'Testigo social';
                    case 'citizenComptroller': return 'Contraloría social';
                    case 'internalControlUnit': return 'Órgano Interno de control';
                    case 'externalAuditor': return 'Auditor externo';
                }
            }).join(', ');
        });

        fn.addField(334298, 'implementation.documents[?(@.documentType==="physicalProgressReport")].url', contract);
        fn.addField(334303, 'implementation.documents[?(@.documentType==="financialProgressReport")].url', contract);
        
        fn.addField(334299, 'implementation.documents[?(@.documentType==="physicalReception")].url', contract);
        fn.addField(334300, 'implementation.documents[?(@.documentType==="settlement")].url', contract);

        fn.add(334321, extras.dataresponsibleunit, undefined, true, 'Área(s) responsable(s) que genera(n), posee(n), publica(n) y actualizan la información');
        fn.addField(334293, 'fechaValidacion', extras, date => fn.dateFormat(date), true, 'Fecha de validación');
        fn.addField(334312, 'fechaActualizacion', extras, date => fn.dateFormat(date), true, 'Fecha de actualización');


        // notas
        let notes = '';
        let desierto = release.tender.status === 'cancelled';
        if (!desierto) {


            // obra publica
            if (release.tender.additionalProcurementCategories.find(x => x !== 'worksRelatedServices' ||
                x !== 'works')) {
                notes += 'Al no ser una contratación de obras públicas o servicios relacionados con las mismas  no se generó información respecto de lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, etapa de la obra pública, avances físicos y financieros, así como el de recepción física y finiquito ni estudio de impacto ambiental. ';
            }
            // convenios modificatorios
            if (contract.amendments && contract.amendments.lenght > 0) {
                notes += 'La presente contratación no cuenta a la fecha de actualización con convenios modificatorios por lo cual no se cubrieron los campos relacionados con estos. ';
            }

            // tipo de fondo de participacion o aportacion
            notes += 'Respecto al tipo de fondo de participación o aportación, los recursos de este Instituto se encuentran en el ramo 44, y las aportaciones y fondos están consideradas en el ramo 28 y 36, de conformidad con el Presupuesto de Egresos de la Federación. ';

            values = fn.findValue('documents[?(@.documentType=="suspensionStatement")].url', contract);
            if (!values) {
                notes += 'En esta contratación no hay a la fecha comunicado de suspensión, rescisión o terminación anticipada. ';
            }
            // junta de aclaraciones
            if (release.tender.procurementMethodDetails === 'Invitación a cuando menos tres personas') {
                notes += 'No se realizó junta de aclaraciones toda vez que de conformidad con el artículo 43 fracción V del Reglamento de Adquisiciones, Arrendamientos y Servicios Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales, la celebración de la junta de aclaraciones es optativa en los procedimientos de Invitación a cuando menos Tres Personas. ';
            }

            if (release.tender.procurementMethodDetails === 'Licitación pública') {
                notes += 'No hay regla de negocio específica, puesto que en este caso siempre se llena el campo correspondiente al hipervínculo. ';
            }

            // instrumento cerrado
            if (!release.tender.minValue || release.tender.minValue.amount === 0) {
                notes += 'Esta contratación se formalizó a través de un instrumento de carácter cerrado, por lo cual no se cuenta con montos mínimos y máximos. ';
            } else {
                // instrumento abierto
                notes += 'Respecto del monto sin impuestos y el monto total con impuestos del instrumento, se informa que en virtud de estar formalizado a través de un instrumento de carácter abierto, en estos rubros se reporta el monto máximo contratado. ';
            }
        } else {
            // cuando se es desierto
            // texto general
            notes = 'El presente procedimiento de contratación no cuenta con información de un pedido o contrato formalizado, por tanto no se generó información relativa a los criterios del nombre del ganador, contrato y sus anexos, convenio modificatorio, convenio de terminación, Descripción breve de las razones que justifican la elección del/los proveedor/es, Número que identifique al contrato, Fecha del contrato, Monto del contrato sin impuestos incluidos, Monto total del contrato con impuestos incluidos, Monto mínimo con impuestos incluidos, Monto máximo con impuestos incluidos, tipo de moneda, Objeto del contrato, tipo y forma de pago, fecha de inicio y término, toda vez que el procedimiento en cuestión se declaró desierto y no fue adjudicado a licitante alguno, en tal virtud los datos concernientes a información de contratos o pedidos tales como: nombre y/o razón social del contratista, RFC, descripción de  las razones que justifican su elección, número de contrato, fecha de contrato, montos del contrato, tipo de moneda, tipo de cambio, forma de pago, fecha de inicio y término, plazo de entrega y ejecución de los servicios, hipervínculo al contrato, mecanismos de vigilancia y supervisión no fueron establecidos al no adjudicarse a licitante alguno. La presente contratación no cuenta a la fecha de actualización con convenios modificatorios por lo cual no se cubrieron los campos relacionados con estos. En esta contratación al declararse desierta por ende no hay a la fecha comunicado de suspensión, rescisión o terminación anticipada. ';

            // tipo de contratacion
            if (release.tender.additionalProcurementCategories.find(x => x !== 'worksRelatedServices' ||
                x !== 'works')) {
                notes += 'De igual manera al  no adjudicarse y no ser una contratación de obra pública no se generó información respecto de Lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, Etapa de la obra pública, avances  físicos y financieros así como el de recepción física y finiquito ni estudio de impacto ambiental. ';
            } else {
                notes += 'De igual manera al  no adjudicarse no se generó información respecto de Lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, Etapa de la obra pública, avances  físicos y financieros así como el de recepción física y finiquito ni estudio de impacto ambiental. ';
            }

            // si es itp
            if (release.tender.procurementMethodDetails === 'Invitación a cuando menos tres personas') {
                notes += 'No se realizó junta de aclaraciones toda vez que de conformidad con el artículo 43 fracción V del Reglamento de Adquisiciones, Arrendamientos y Servicios Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales, la celebración de la junta de aclaraciones es optativa en los procedimientos de Invitación a cuando menos Tres Personas.';
            }
        }


        fn.add(334322, extras.notes);
        fn.nextContract();
    });



    return fn.getFormat();
}

module.exports.build = build;