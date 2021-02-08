// PostgreSQL database
var db_conf = require('../db_conf');

const Stages = {
    planning: 1,
    tender: 2,
    award: 3,
    contract: 4,
    implementation: 5
};


let updateHisitory = async (objectRecived)  => {

    let {cpid} = objectRecived, 
    {user} = objectRecived,
    {stage} = objectRecived,
    {host} = objectRecived;

    try{
        await registerLog({
            publisher: user._id,
            ocid: cpid,
            stage: stage,
            register: true
        });
    }
    catch(e){
        console.log('Error al generar release', e)
    }

    try{
        await registerRecord(cpid, host);
    }
    catch(e){
        console.log('Error al registrar record', e)
    }

    try{
        // registrar datos para el historial de versiones
        await db_conf.edca_db.none(`UPDATE contractingprocess 
                               SET updated = true, 
                                   updated_date = now(),
                                   updated_version = (SELECT version FROM logs WHERE contractingprocess_id = $1 ORDER BY update_date DESC LIMIT 1)                               
                               WHERE id = $1`, [cpid]);
        console.log('Historial actualizado', cpid, Object.keys(Stages)[stage-1]);
    }catch(e) {
        console.log('Error al registrar historial', e)
    }

    process.exit(0);
}


let registerLog = async (data) => {
    try{
        var logs = await db_conf.edca_db.one('select count(*) from logs where contractingProcess_id = $1', [data.ocid]);
        let {ocid} = await db_conf.edca_db.one('select ocid from contractingprocess where id = $1',[data.ocid]);

        // Verifica si es el primer cambio o si ya existe algun cambio en la etapa
        if (data.register || logs.count == 0) {
            let release = require('../io/release')(db_conf.edca_db);
            let stage = Object.keys(Stages)[data.stage-1];     
            data.version = parseInt(logs.count) + 1;
            let name = `${ocid}.v${data.version}.${stage}`;
            data.releaseFile = `${name}.json`;
            data.release_json = await release.generateRelease(data.ocid, name);
    
            await db_conf.edca_db.one(`insert into logs (version, update_date, publisher, release_file, contractingProcess_id, release_json)
                values ($1, clock_timestamp() AT TIME ZONE 'America/Mexico_City', $2, $3, $4, $5) returning id`, [
                data.version,
                data.publisher,
                data.releaseFile,
                data.ocid,
                data.release_json
            ]);

        }
    }
    catch(e) {
        console.log('Error al registrar log', e, data)
    }
}

let registerRecord = async (ocid, host) => {
    try{
        let log = await db_conf.edca_db.one('select id, version from logs where contractingprocess_id = $1 order by update_date desc limit 1', [ocid]);
        let record = require('../io/record')(db_conf.edca_db);
        let record_json = await record.generateRecord(ocid, host);
        let version_json = await record.getChanges(ocid, record_json);
        await db_conf.edca_db.one('update logs set record_json = $1, version_json  = $3 where id = $2 returning id', [record_json, log.id, version_json]);
    }
    catch(e) {
        console.log('Error al registrar record', e);
    }
};

process.on('message', async (cpid, user, stage, host) => {
    await updateHisitory(cpid, user, stage, host); 
    process.send(true);
  });