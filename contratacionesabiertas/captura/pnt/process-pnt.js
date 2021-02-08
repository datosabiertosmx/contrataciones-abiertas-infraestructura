
// PostgreSQL database
const {edca_db} = require('../db_conf');
// moment format
var moment = require('moment'); // require

// Mongodb
var dbConfig = require('../db.js');
var mongoose = require('mongoose');
    mongoose.Promise = require('bluebird');
    mongoose.connect(dbConfig.url,{useNewUrlParser: true,useUnifiedTopology: true});
var User = require('../models/user');

// Conexion al api de PNT
const api = require('./api-pnt.js');

// formatos
const format43335 = require('./format-43335');
const format43336 = require('./format-43336');

// email de la unidad 
const EMAIL = process.env.PNT_EMAIL || 'dga@inai.org.mx';

/**
 * Inicializar el proceso de la carga/actualizacion masiva de registros
 */
let initProcess = async () => {
    // obtener todas las contrataciones que se van a enviar
    // es necesario que se encuentre publicada, tenga desglose presupuestario y requiera actualizacion a pnt
    let cps = await edca_db.manyOrNone(`select c.id
                                        from contractingprocess c
                                        where published = true and (requirepntupdate = true or requirepntupdate is null) and
                                        id in (select contractingprocess_id from budgetbreakdown)`);

    if(!cps){
        console.log('No hay contrataciones por actualizar');
        return;
    }

    await sendRegisters(cps.map(x => x.id));
}


/**
 * Enviar contratacion a PNT
 * @param {number} cp Id de contratacion a enviar
 */
let send = async cp => {
    await sendRegisters([cp], true);
}


/**
 * Enviar contrataciones
 * @param {Array} cps Ids de contrataciones a actualizar
 */
let sendRegisters = async (cps, throwError) => {
    if(cps.length === 0){
        console.log('----> No hay contrataciones por enviar');
        return;
    }

    // genera token para enviarlo en las peticiones
    await api.generateToken();

    let processFormat = async (cp, release, format, position, date, user) => {
        let records = await edca_db.manyOrNone('select contractid, record_id, position, field_id, reference_id, isroot from pntreference where contractingprocess_id = $1 and format = $2 and record_id is not null', [cp, format]);
        let diferencia = 0;

        // se preparan datos extras que no esta en el release
        let consulta =  (await edca_db.oneOrNone('select * from datapnt order by id desc limit 1')) || {};
        let requestingUnits =  (await edca_db.manyOrNone('select party_legal_name from planning_party_units where contractingprocess_id = $1 and requesting_unit = true order by id',[cp])) || {};
        let contractingUnits =  (await edca_db.manyOrNone('select party_legal_name from planning_party_units where contractingprocess_id = $1 and contracting_unit = true order by id',[cp])) || {};
        let responsibleUnits =  (await edca_db.manyOrNone('select party_legal_name from planning_party_units where contractingprocess_id = $1 and responsible_unit = true order by id',[cp])) || {};
        let extras =  (await edca_db.oneOrNone('select fiscalYear as ejercicio from datapnt order by id desc limit 1')) || {};
        extras.fechaActualizacion = consulta.updatedate;
        extras.fechaValidacion = moment(consulta.valitationdate).format("YYYY-MM-DD");
        extras.dataresponsibleunit = consulta.dataresponsibleunit;
        extras.notes = consulta.notes;
        extras.reportingperiodstartdate = consulta.reportingperiodstartdate;
        extras.reportingperiodenddate = consulta.reportingperiodenddate;
        extras.requestingUnits = requestingUnits;
        extras.contractingUnits = contractingUnits;
        extras.responsibleUnits = responsibleUnits;
        // preparar la entrada a enviar
        let entrada = formats[format](release,records, position, extras);
        let response;

        //console.log(JSON.stringify(entrada, null, 4));
        if(records.length === 0){
            response = await api.registerInfo(format, EMAIL, entrada);         
        } else {
            response = await api.updateInfo(format, EMAIL, entrada);
        }

        
        if(response && response.success){
            await saveResponsePNT(cp, format, entrada, response.mensaje.registros, diferencia);
        } else{
            //console.log(JSON.stringify(response, null, 4));
            await saveError(cp, format, entrada, response.mensaje ? response.mensaje.registros : [], diferencia );
            if(throwError) {
                throw Error('No se ha podido enviar la información');
            }
            
        }
    }

    // preparar formateadores
    let formats = {
        43335: format43335.build,
        43336: format43336.build,
    }

   // realizar envios de contrataciones (una por una)
    for(let i = 0, cp= cps[i]; i < cps.length; i++, cp= cps[i]){
       
            // preparar datos a utilizar
            // es necesario que exista el release
            let {release, update_date, publisher} = await edca_db.oneOrNone("select release_json as release, to_char(update_date, 'YYYY-MM-DD') update_date, publisher from logs where contractingprocess_id = $1 and published = true order by id desc limit 1", [cp]);    
            if(!release) {
                console.log(`-------> La contratacion ${cp} no cuenta con un release generado.`);
                continue;
            };

            let user = await User.findById(publisher);

            console.log(`-----> Procesando contratacion ${cp}`);
            switch(release.tender.procurementMethodDetails) {
                // FORMATO A
                case 'Licitación pública':
                case 'Invitación a cuando menos tres personas':
                await processFormat(cp, release, 43336, i, update_date, user ? user.publisherName || user.name : 'Sistema');
                break;
                // FORMATO B
                case 'Adjudicación directa':
                await processFormat(cp, release, 43335, i, update_date, user ? user.publisherName || user.name : 'Sistema');
                break;
                default:
                    if(throwError) {
                        throw Error('Esta contratacion no pertenece a ningún formato');
                    }
                 
            }
         
    }

}

/**
 * Actualizar respuesta de PNT
 * 
 */
let saveResponsePNT = async (cp, format, entrada, salida, diferencia) => {
    let sqlUpdate = 'update pntreference set date = now(), error = null where (record_id = $1 or record_id is null) and format = $2 and contractingprocess_id = $3 and isroot = $4 and contractid = $7 ',
        sqlInsert = 'insert into pntreference(record_id, format,contractingprocess_id , date, isroot, field_id, position, contractid) values($1, $2, $3, now(), $4, $5, $6, $7)',
        sqlId = 'select id from pntreference where (record_id = $1 or record_id is null) and format = $2 and contractingprocess_id = $3 and isroot = $4 and contractid = $7 limit 1';

    // se registra la raiz
   
    if(salida){
        for (let f = 0; f < salida.length; f++) {
            let contratoSalida = salida[f],
                contratoEntrada = entrada.find(x => (x.numeroRegistro+diferencia) === contratoSalida.numeroRegistro);

            if(!contratoEntrada) continue;

            let param = [contratoSalida.idRegistro, format, cp, true, 0, 0, contratoEntrada.contractid];
            let existe = await edca_db.oneOrNone(sqlId, param);
            await edca_db.none(existe ? sqlUpdate : sqlInsert, param);

            for (let i = 0; contratoSalida.campos && i < contratoSalida.campos.length; i++) {
                let campoSalida = contratoSalida.campos[i],
                    campoEntrada = contratoEntrada.campos.find(x => x.idCampo === campoSalida.idCampo);

                if (campoEntrada && campoEntrada.valor) {
                    // se registran los campos secundarios
                    for (let z = 0; z < campoSalida.valor.length; z++) {
                        let campoSecundrioSalida = campoSalida.valor[z],
                            campoSecundarioEntrada = campoEntrada.valor.find(x => x.numeroRegistro === campoSecundrioSalida.numeroRegistro);

                        if (campoSecundarioEntrada) {
                            param = [campoSecundrioSalida.idRegistro, format, cp, false, campoEntrada.idCampo, campoSecundrioSalida.numeroRegistro, contratoEntrada.contractid];
                            existe = await edca_db.oneOrNone(sqlId, param);
                            await edca_db.none(existe ? sqlUpdate : sqlInsert, param);
                        }
                    }

                }
            }
        }
    }

    // se indica que ya se actualizo en pnt
    await edca_db.none(`update contractingprocess set 
                            pnt_published = true, 
                            pnt_date= now(),
                            pnt_version = (SELECT version FROM logs WHERE contractingprocess_id = $1 AND logs.published = true ORDER BY update_date DESC LIMIT 1) 
                        where id = $1`, [cp]);

    console.log('-----------> Respuesta almacenada');
}

/**
 * Registrar error de envio
 * @param {Number} cpid ID de contratacion
 * @param {Number} format Numeor de formato
 * @param {Array} entrada Datos enviados
 * @param {Array} salida Respuesta de PNT
 */
let saveError = async function(cpid, format, entrada, salida, diferencia){
    let sqlUpdate = 'update pntreference set date = now(), error = $3 where contractingprocess_id = $1 and format = $2 and isroot = true and contractid = $4',
        sqlInsert = 'insert into pntreference(contractingprocess_id, format , date, isroot, error, contractid) values($1, $2, now(), true, $3, $4)',
        sqlId = 'select id from pntreference where  isroot = true and format = $2 and contractingprocess_id = $1 and contractid = $4 limit 1';
    
    if(!salida) return ;
    salida = salida.reverse();

    for (let f = 0; f < salida.length; f++) {
        let contratoSalida = salida[f],
            contratoEntrada = entrada.find(x => (x.numeroRegistro+diferencia) === contratoSalida.numeroRegistro);

        if(!contratoEntrada) continue;
        
        let params = [cpid, format, JSON.stringify(contratoSalida), contratoEntrada.contractid];
        let existe = await edca_db.oneOrNone(sqlId,params);
        console.log('Respuesta de error', JSON.stringify(contratoSalida, null, 4));
        if(existe){
            await edca_db.none(sqlUpdate, params);
        } else {
            await edca_db.none(sqlInsert, params);
        }
        
    }

}


module.exports = {
    init: initProcess,
    send: send
}