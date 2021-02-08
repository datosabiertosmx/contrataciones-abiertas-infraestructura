
// FORMATO A
const FORMAT = 43335;
const FormatFunctions = require('./format-functions');

/**
 * Armar estructura del formato "Resultados adjudicaciones, invitaciones y licitaciones_Procedimientos de adjudicación directa"
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

        fn.addField(334233, 'ejercicio', extras, undefined, true, 'Ejercicio');
        let date = new Date(fn.findValue(`awards[?(@.id==="${contract.awardID}")].date`));
        const quarter = Math.floor(date.getMonth() / 3);
        const start = new Date(date.getFullYear(),quarter*3,1);
        const end = new Date(date.getFullYear(),(quarter*3)+2,1);
        end.setMonth(end.getMonth() + 1);
        end.setDate(end.getDate() - 1);

        fn.add(334258, extras.reportingperiodstartdate.toISOString(), date => fn.dateFormat(date), true, 'Fecha de inicio del periodo que se informa');
        fn.add(334259, extras.reportingperiodenddate.toISOString(), date => fn.dateFormat(date), true, 'Fecha de término del periodo que se informa');

        fn.addField(334269, 'tender.additionalProcurementCategories[0]', undefined, value => {
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
        fn.addField(334230, 'awardID', contract);

        let values = fn.findValue('tender.procurementMethodDetails');

        switch (values) {
            case 'Adjudicación directa':
                values = fn.findValues(`awards[?(@.id==="${contract.awardID}")].rationale`);
                fn.add(334238, values[0]);
                fn.addFields(334250, `planning.documents[?(@.documentType==="exceptionAuthorization")].url`);  
                fn.addFields(334250, `awards[?(@.id==="${contract.awardID}")].documents[?(@.documentType==="technicalEvaluationReport")].url`);
                fn.addFields(334250, `tender.documents[?(@.documentType==="procurementMethodAuthorization")].url`);
                break;
        }

        fn.addField(334270, 'tender.procurementMethodDetails', undefined, value => {
            switch (value) {
                case 'Adjudicación directa':
                case 'Adjudicación directa art.42':
                    value = 0;
                    break;
                default:
                    value = 1;
                    break;
            }
            return value;
        });

        fn.addFields(334239, 'description', contract);


        fn.addTable(334271, 'planning.requestsForQuotes[*].quotes[*]', (quotes, results) => {
            let issueSuppliers = fn.findValues('issuingSupplier', quotes);
            if (issueSuppliers) {
                issueSuppliers.map(supplier => {
                    fn.addInternalField(43311, `parties[?(@.id==="${supplier.id}")].identifier.givenName`, release, results);
                    fn.addInternalField(43312, `parties[?(@.id==="${supplier.id}")].identifier.patronymicName`, release, results);
                    fn.addInternalField(43313, `parties[?(@.id==="${supplier.id}")].identifier.matronymicName`, release, results);
                    fn.addInternalField(43314, `parties[?(@.id==="${supplier.id}")].identifier.legalName`, release, results);
                    fn.addInternalField(43315, `parties[?(@.id==="${supplier.id}")].id`, release, results);
                });
            }
            // solo el primero, aqui no hay netAmount??
            fn.addInternalField(43316, 'value.amount', quotes, results);
        });


        let awardSupplier = fn.findValues(`awards[?(@.id==="${contract.awardID}")].suppliers[0]`);
        if (awardSupplier) {
            awardSupplier.map(x => {
                fn.addField(334264, `parties[?(@.id==="${x.id}")].identifier.givenName`);
                fn.addField(334260, `parties[?(@.id==="${x.id}")].identifier.patronymicName`);
                fn.addField(334265, `parties[?(@.id==="${x.id}")].identifier.matronymicName`);
                fn.addField(334266, `parties[?(@.id==="${x.id}")].identifier.legalName`);
                fn.addField(334267, `parties[?(@.id==="${x.id}")].id`);
            });

        }

        if(extras.requestingUnits){
            values = [];
            extras.requestingUnits.forEach(element => {
                values.push(element.party_legal_name);
            });
            fn.add(334235, values.filter(x => x !== undefined && x !== null).join(', '));
        }

        if(extras.responsibleUnits){
            values = [];
            extras.responsibleUnits.forEach(element => {
                values.push(element.party_legal_name);
            });
            fn.add(334236, values.filter(x => x !== undefined && x !== null).join(', '));
        }

        fn.addField(334231, `id`, contract);
        fn.addField(334243, `dateSigned`, contract, date => fn.dateFormat(date), true, 'Fecha de contrato');
        fn.addField(334244, `value.netAmount`, contract);
        fn.addField(334245, `value.amount`, contract);
        
        fn.addField(334247, `tender.minValue.amount`);
        fn.addField(334248, `tender.value.amount`);
        
        fn.addField(334228, `value.currency`, contract);
        // no se envia (no se guarda en release)
        fn.addFields(334229, `value.exchangeRates[*].rate`, contract);
        fn.addField(334232, `implementation.transactions[0].paymentMethod`, contract, paymentMethod => {
            switch(paymentMethod) {
                case 'letterOfCredit':  return 'Carta de crédito';
                case 'check':  return 'Cheque';
                case 'cash':  return 'Efectivo';
                case 'corporateCard':  return 'Tarjeta corporativa';
                case 'wireTransfe':  return 'Transferencia bancaria';
            }
        });
        fn.addField(334240, `description`, contract);
        fn.addField(334246, `guarantees[*].value.amount`, contract, (amounts) => {
            let total = 0;
            if(Array.isArray(amounts)){
                amounts.map(x => total += x);
            } else {
                total = amounts;
            }
            
            return total;
        });
        fn.addField(334241, `period.startDate`, contract, date => fn.dateFormat(date));
        fn.addField(334261, `period.endDate`, contract, date => fn.dateFormat(date));

        values = fn.findValues(`documents[?(@.documentType==="contractSigned")].url`, contract);
        values = values.concat(fn.findValues(`documents[?(@.documentType==="contractAnnexe")].url`, contract));
        fn.add(334254, values.join(','));
        fn.addField(334253, `documents[?(@.documentType==="suspensionNotice")].url`, contract);


        values = fn.findValues(`planning.budget.budgetBreakdown[*]`);
        values = {'temp': values};

        if(values.temp.length > 0){            
            if(values.temp[0].origin !== undefined){
                fn.add(334234, values.temp[0].origin);
            }
            if(values.temp[0].budgetLines !== undefined && values.temp[0].budgetLines.length > 0){
                if(values.temp[0].budgetLines[0].components[12].description !== undefined){
                    fn.add(334272, values.temp[0].budgetLines[0].components[12].description);
                }
            }
        }
        

        fn.addTable(334255, 'id', (id, results) => {
            let address = fn.findValue('items[?(@.deliveryAddress)].deliveryAddress', contract);
            if(address){
                values = [];
                values.push(address.streetAddress);
                values.push(address.locality);
                values.push(address.region);
                values.push(address.postalCode);
                values.push(address.countryName);
                fn.addInternal(43303, values.filter(x => x !== undefined && x !== null).join(', '), results);
            }
 
            fn.addInternalField(43304, 'planning.documents[?(@.documentType==="environmentalImpact")].url', undefined, results);
            fn.addInternalField(43305, 'implementation.milestones[?(@.type==="publicNotices")].description', contract, results);
            fn.addInternalField(43306, 'implementation.status', contract, results, status => {
                switch (status) {
                    case 'planning': status = 0; break;
                    case 'ongoing': status = 1; break;
                    // esta no existe en pnt
                    case 'concluded': status = 2; break;
                    case 'terminated': status = 2; break;
                }
                return status;
            });
        }, contract);

        value = fn.findValue('amendments[?(@.date)].date', contract);
        fn.add(334273, value ? 0 : 1);
      

         fn.addTable(334268, 'amendments', (amendment, results) => {
            fn.addInternalField(43307, 'id', amendment, results);
            fn.addInternalField(43308, 'description', amendment, results);
            fn.addInternalField(43309, 'date', amendment, results, date => fn.dateFormat(date));
            fn.addInternalFields(43310, 'documents[?(@.documentType=="contractAmendment")].url', contract, results);
        }, contract);
        fn.addField(334237, 'surveillanceMechanisms', contract, value => {
            return value.map(x => {
                switch(x) {
                    case 'socialWitness': return 'Testigo social';
                    case 'citizenComptroller': return 'Contraloría social';
                    case 'internalControlUnit': return 'Órgano Interno de control';
                    case 'externalAuditor': return 'Auditor externo';
                }
            }).join(', ');
        });

        fn.addFields(334274, 'implementation.documents[?(@.documentType=="physicalProgressReport")].url', contract);
        fn.addFields(334251, 'implementation.documents[?(@.documentType=="financialProgressReport")].url', contract);
        fn.addFields(334252, 'implementation.documents[?(@.documentType=="physicalReception")].url', contract);
        fn.addFields(334249, 'implementation.documents[?(@.documentType=="settlement")].url', contract);
        
        fn.add(334262, extras.dataresponsibleunit, undefined, true, 'Área(s) responsable(s) que genera(n), posee(n), publica(n) y actualizan la información');
        fn.addField(334242, 'fechaValidacion', extras, date => fn.dateFormat(date), true, 'Fecha de validación');
        fn.addField(334257, 'fechaActualizacion', extras, date => fn.dateFormat(date), true,'Fecha de actualización');
        
        // notas
        let notes =''
        let desierto = release.tender.status === 'cancelled';
        if (!desierto) {


            // obra publica
            if (release.tender.additionalProcurementCategories.find(x => x === 'worksRelatedServices' ||
                x === 'works')) {
                notes += 'Al no ser una contratación de obras públicas o servicios relacionados con las mismas no se generó información respecto de lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, etapa de la obra pública, avances físicos y financieros así como el de recepcion fisica y finiquito ni estudio de impacto ambiental. ';
            }
            // convenios modificatorios
            if (contract.amendments && contract.amendments.lenght > 0) {
                notes += 'La presente contratación no cuenta a la fecha de actualización con convenios modificatorios por lo cual no se cubrieron los campos relacionados con estos. ';
            }

            // comunicacion de suspencion
            values = fn.findValue('documents[?(@.documentType=="suspensionStatement")].url', contract);
            if (!values) {
                notes += 'En esta contratación no hay a la fecha comunicado de suspensión, rescisión o terminación anticipada. ';
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
        }
        fn.add(334263, extras.notes);
        fn.nextContract();
    });


    return fn.getFormat();
}

module.exports.build = build;