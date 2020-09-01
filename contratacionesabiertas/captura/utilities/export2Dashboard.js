const db = require('../db_conf');
let dbPublic = db.edca_db;
let dbDashboard = db.dashboard;
let dash_user = db.dash_user;
let cpid;

const tables = {
    'contractingprocess': {
        id: 'id'
    },
    'parties': { id: 'contractingprocess_id'},
    'roles': { id: 'contractingprocess_id'},
    'planning': { 
        id: 'contractingprocess_id'
    },
    'budget': { id: 'contractingprocess_id'},
    'tender': { id: 'contractingprocess_id'},
    'award': { 
        id: 'contractingprocess_id',
        childrens: {
            'awardsupplier': { query: 'select * from awardsupplier where award_id = $1'},
        }
    },
    'contract': { id: 'contractingprocess_id'},
    'implementation': { id: 'contractingprocess_id'},
    'budgetbreakdown': { id: 'contractingprocess_id'},
    'requestforquotes': { 
        id: 'contractingprocess_id',
        childrens:{
            'quotes': { 
                id: 'requestforquotes_id',
                childrens: {
                    'quotesitems': { id: 'quotes_id'},
                }
            },
        }
    },
    
    'planningdocuments': { id: 'contractingprocess_id'},
    'tenderitem': { id: 'contractingprocess_id'},
    'tendermilestone': { id: 'contractingprocess_id'},
    'tenderdocuments': { id: 'contractingprocess_id'},
    'tenderamendmentchanges': { id: 'contractingprocess_id'},
    'awarditem': { id: 'contractingprocess_id'},
    'awarddocuments': { id: 'contractingprocess_id'},
    'awardamendmentchanges': { id: 'contractingprocess_id'},
    'contractitem': { id: 'contractingprocess_id'},
    'contractdocuments': { id: 'contractingprocess_id'},
    'contractamendmentchanges': { id: 'contractingprocess_id'},
    'implementationmilestone': { id: 'contractingprocess_id'},
    'implementationtransactions': { id: 'contractingprocess_id'},
    'implementationdocuments': { id: 'contractingprocess_id'},
    'links': { id: 'contractingprocess_id'}
};


const export2Dashboard = async (id) => {

    cpid = id;
    await dbDashboard.none('ALTER ROLE '+dash_user+' SET search_path TO dashboard;');
    await deleteRows();
    await copyRecords();
    return this;
}


const deleteRows = async () => {

    for(let table in tables) {
        try{
            await dbDashboard.none('DELETE FROM $1~ WHERE $2~ = $3', [table, tables[table].id, cpid])

        }catch(e) {
            console.log('Error al vaciar tabla en dashboard',  table, e.message);
        }
        
    }
}

const getSchema = async table => {
    return dbPublic.many("select distinct column_name, data_type from INFORMATION_SCHEMA.COLUMNS where table_name = $1 and table_schema = 'public';", [table]);
}

const copyRecords = async () => {

    for(let table in tables) {
        try{
            await processTable(table, tables[table]);
        }catch(e) {
            console.log('Error al llenar tabla en dashboard', table, e.message);
        }
        
    }
}


const processTable = async (table, options, parent) => {
    const schema = await getSchema(table);
    const fields = schema.map(x => x.column_name).join(',');
    const formatFields = schema.map( (x) => '${' + x.column_name  + '}').join(',');
    const sqlSelect = `SELECT ${fields} FROM ${table} WHERE $1~ = $2`;
    const sqlInsert = `INSERT INTO ${table}(${fields}) VALUES(${formatFields})`;

    let records = [];

    
    if(options.id) {
        // procesar cuando se tiene el id de la contratacion en la tabla
        records = await dbPublic.manyOrNone(sqlSelect, [options.id, parent || cpid]);
    } else if(options.query){
        // procesar cuando es un query en especifico y se utiliza otra fk
        records = await dbPublic.manyOrNone(options.query, [parent]);
    }

    if(records.length === 0) return;


    // proceder a insertar a dashboard de 1 en 1
    for(let i = 0; i < records.length; i++){
        await dbDashboard.oneOrNone(sqlInsert, records[i]);
        // si tiene dependencias se procede a insertarlas
        if(options.childrens) {
            for(let child in options.childrens) {
                await processTable(child, options.childrens[child], records[i].id);
            }
        }
    }

}

module.exports = export2Dashboard