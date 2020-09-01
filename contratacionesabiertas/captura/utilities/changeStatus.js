// PostgreSQL database
var db_conf = require('../db_conf');

/**
 * Actualizar automaticamente el estatus en base a los documentos
 */
module.exports = async (cpid, documento, campoFK, idFK) => {

    let huboCambio; // almacena el cambio en las etapas
    let tender, award, contract, implementation;
    let method = await db_conf.edca_db.oneOrNone('SELECT procurementmethod_details from tender where contractingprocess_id = $1 LIMIT 1', [cpid]);

    switch(documento) { 
        case 'marketStudies': //estudio de mercado
            tender = 'planning';
            break;
        case 'request': // requisicion
            tender = 'planned';
            break;
        case 'tenderNotice': // convocatoria

            if (method.procurementmethod_details == 'Licitación pública' || 
                method.procurementmethod_details == 'Invitación a cuando menos tres personas'){
                tender = 'active';   
                award = 'pending';
            }
            break;
        case 'tenderNotice':  // aviso de publicacion en compranet
        if (procurementmethod_details === 'Adjudicación directa'){
            tender = 'active';   
            award = 'pending';
        }
        break;
        case 'unsuccessfulProcedureNotice': // acta de fallo de desierto
        case 'unsuccessfulProcedureNotice': // oficio declaratorio de desierto
            // acta de fallo de desierto
            if (method.procurementmethod_details == 'Licitación pública' || method.procurementmethod_details == 'Invitación a cuando menos tres personas' ){
                tender = 'unsuccessful';   
                award = 'unsuccessful';
            }
            // oficio declaratorio de desierto
            if (method.procurementmethod_details == 'Adjudicación directa'){
                tender = 'unsuccessful';   
                award = 'unsuccessful';
            }
            break;
        case 'awardNotice': // notificacion de adjudicacion
            tender = 'complete';   
            award = 'active';
            contract = 'pending';
            break;
        case 'contractSigned': // contrato
        case 'contractSigned': // pedido
                tender = 'complete';   
                award = 'active';
                contract = 'active';
                implementation = 'ongoing';
                break;
        case 'completionCertificate': // dictamen de cumplimiento
                tender = 'complete';   
                award = 'active';
                contract = 'terminated';
                implementation = 'concluded';
                break;
    }


    if (tender){
        await db_conf.edca_db.none('update tender set status = ${status} where contractingprocess_id = ${cpid}', {status: tender, cpid: cpid});
        huboCambio = {};
        huboCambio.tender = tender;
    }
    if (award){
        huboCambio = huboCambio || {};
        await db_conf.edca_db.none('update contractingprocess set awardstatus = ${status} where id = ${cpid}', {status: award, cpid: cpid});
        if (campoFK == 'award_id'){
            await db_conf.edca_db.none('update award set status = ${status} where id = ${id}', {status: award, cpid: cpid, id: idFK});
        } else if(campoFK == 'contract_id'){
            await db_conf.edca_db.none('update award set status = ${status} where contractingprocess_id = ${cpid} AND ( id::text IN (SELECT awardid FROM contract WHERE id = ${id}) OR awardid IN (SELECT awardid FROM contract WHERE id = ${id}))', {status: award,cpid: cpid, id: idFK});
        } else if(campoFK == 'implementation_id'){
            await db_conf.edca_db.none('update award set status = ${status} where contractingprocess_id = ${cpid} AND ( id::text IN (SELECT awardid FROM contract WHERE id IN (SELECT contract_id FROM implementation WHERE id = ${id})) OR awardid IN (SELECT awardid FROM contract WHERE id IN (SELECT contract_id FROM implementation WHERE id = ${id})) )', {status: award,cpid: cpid, id: idFK});
        } else {
            await db_conf.edca_db.none('update award set status = ${status} where contractingprocess_id = ${cpid} ', {status: award,cpid: cpid});
        }
        huboCambio.award = award;
    }
    if (contract){
        huboCambio = huboCambio || {};
        await db_conf.edca_db.none('update contractingprocess set contractstatus = ${status} where id = ${cpid}', {status: contract, cpid: cpid});
        if (campoFK == 'award_id'){
            await db_conf.edca_db.none('update contract set status = ${status} where contractingprocess_id = ${cpid} and (awardid in (SELECT id::text from award where id = ${id}) OR  awardid in (SELECT awardid from award where id = ${id}))', {status: contract, cpid: cpid, id: idFK});
        } else if(campoFK == 'contract_id'){
            await db_conf.edca_db.none('update contract set status = ${status} where id = ${id}', {status: contract, id: idFK});
        } else if(campoFK == 'implementation_id'){
            await db_conf.edca_db.none('update contract set status = ${status} where id IN (SELECT contract_id FROM implementation WHERE id = ${id})', {status: contract, id: idFK});
        }
        huboCambio.contract = contract;
    }
    if (implementation){
        await db_conf.edca_db.none('update contractingprocess set implementationstatus = ${status} where id = ${cpid}', {status: implementation, cpid: cpid});
        if (campoFK == 'award_id'){
            await db_conf.edca_db.none('update implementation set status = ${status} where contract_id IN (SELECT id FROM contract WHERE contractingprocess_id = ${cpid} and awardid in (SELECT id::text from award where id = ${id}) OR  awardid in (SELECT awardid from award where id = ${id}))', {status: implementation, cpid: cpid, id: idFK});
        } else if(campoFK == 'contract_id'){
            await db_conf.edca_db.none('update implementation set status = ${status} where contract_id = ${id}', {status: implementation, id: idFK});
        } else if(campoFK == 'implementation_id'){
            await db_conf.edca_db.none('update implementation set status = ${status} where id= ${id}', {status: implementation, id: idFK});
        }
        huboCambio.implementation = implementation;
    }

    // el objeto resultante se utiliza en el frontend para actualizar los estatus
    return huboCambio;
};