const jp = require('jsonpath');

// moment format
var moment = require('moment'); // require

function record(db) {
    const _db = db;
    const _cpid = null;

    /**
     * Revisa si existe el record. Si no existe lo genera
     */
    this.checkRecordIfExists = async function(cpid, host) {
        let log = await _db.oneOrNone(`select id,record_json  from logs where contractingprocess_id = $1 limit 1`, [cpid]);
        if(!log || !log.record_json || log.record_json == null){
            let release = require('../io/release')(_db);
            let idlog = await release.checkReleaseIfExists(cpid);
            let record_json= await this.generateRecord(cpid, host);
 
            await _db.one('update logs set record_json = $1 where id = $2 returning id', [record_json, idlog]);
        }
    }

    /**
     *  Genera el record para el id proporcionado
    */
    this.generateRecord = async function(cpid, host) {
        this._cpid = cpid;

        return await generateRecord(host);
    }
    
    /**
     *  Genera el record package
    */
    this.getPackage = async function(version, recordFile, host) {
        let log = await _db.oneOrNone(`select * from logs where version = $1 and release_file = $2 limit 1`, [version, recordFile]);

        if (!log) {
            return { message: 'No se ha generado el record de la contratación' };
        }

        const user = (await _db.oneOrNone('select * from publisher where contractingprocess_id = $1 limit 1', [log.contractingprocess_id])) || {};
        const extensions = await getExtensions();
        const packages = await getPackages(log.id, log.contractingprocess_id, host);
        const contractingprocess = await _db.oneOrNone('select * from contractingprocess where id = $1 limit 1', [log.contractingprocess_id]);

        const package = {
            uri: `${host}/record-package/${log.version}/${log.release_file}`,
            version: '1.1',
            extensions: extensions,
            publisher: clean({
                name: user.name,
                scheme: user.scheme,
                uid: user.uid,
                uri: user.uri
            }),
            license: contractingprocess.license,
            publicationPolicy: contractingprocess.publicationpolicy,
            publishedDate: moment(log.update_date).format(),
            records: [log.record_json]
        };

        if (packages.length > 0) {
            package['packages'] = packages;
        }

        return clean(package);
    }

    this.getPackageForPeriod = async function(ocid, mode, value, host) {
        let startDate, endDate;
        let year = new Date().getFullYear(),
                    month = new Date().getMonth();
        let nameUri = value.toString();
        let value2;
        if(/-/.test(value)){
            // cuando es por trimestre
            value2 = parseInt(value.split('-')[1]);
            value = value.split('-')[0];
        }
        value = parseInt(value);


        if(mode !== 'all' && (isNaN(value) || value === 0)) throw Error('Período incorrecto');
        value = isNaN(value) ? '' :  value;

        switch(mode) {
            case 'day':               
                startDate = new Date(year, month, value);
                endDate = new Date(year, month, value+1);
            break;
            case 'month':
                value = value - 1;
                startDate = new Date(year, value,1);
                endDate = new Date(year, value + 1, 1);
            break;
            case 'trimester':
                value2 = value2 - 1;
                startDate = new Date(value,(value2*3),1);
                endDate = new Date(value, ((value2+1)*3),(value2*3)+1,1);
            break;
            case 'year':
                startDate = new Date(value,0,1);
                endDate = new Date(value+1,0,1);
            break;
            default:
                startDate = new Date(1950,0,1);
                endDate = new Date();
                endDate.setDate(endDate.getDate() + 1);
            break;
        }

        const contractingprocess = await _db.oneOrNone('select * from contractingprocess where ocid = $1 limit 1', [ocid]);

        let logs = await _db.manyOrNone(`select * from logs where contractingprocess_id = $1 and update_date between  $2 and $3 order by id desc`, [contractingprocess.id, startDate, endDate]);

        if (!logs || logs.length === 0) {
            throw Error('No se han encontrado registros en el período seleccionado');
        }

        const user = (await _db.oneOrNone('select * from publisher where contractingprocess_id = $1 limit 1', [logs[0].contractingprocess_id])) || {};
        const extensions = await getExtensions();
        const packages = logs.map(x => `${host}/release/${x.version}/${x.release_file}`);

        const package = {
            uri: `${host}/record-package-period/${ocid}/${mode}/${nameUri}`,
            version: '1.1',
            extensions: extensions,
            publisher: clean({
                name: user.name,
                schema: user.scheme,
                uid: user.uid,
                uri: user.uri
            }),
            license: contractingprocess.license,
            publicationPolicy: contractingprocess.publicationpolicy,
            publishedDate: moment(logs[0].update_date).format(),
            records: logs.map(x => x.record_json)
        };

        if (packages.length > 0) {
            package['packages'] = packages;
        }

        return clean(package);
    }

    /**
     *  Genera las extensiones
    */
    let getExtensions = async function() {
        const extensions = [
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_requestForQuotes_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_clarificationMeetings_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_paymentMethod_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_taxes_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_publicNotices_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_implementationStatus_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_awardRationale_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_nameBreakdown_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_surveillanceMechanisms_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_extendedProcurementCategory_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_contactPointType_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_budgetLines_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_guarantees_extension/master/extension.json",
			"https://raw.githubusercontent.com/contratacionesabiertas/ocds_procurementUnits_extension/master/extension.json",
			"https://raw.githubusercontent.com/open-contracting-extensions/ocds_exchangeRate_extension/master/extension.json",
            "https://raw.githubusercontent.com/open-contracting-extensions/ocds_location_extension/master/extension.json",
            "https://raw.githubusercontent.com/open-contracting-extensions/ocds_additionalContactPoints_extension/master/extension.json",
            "https://raw.githubusercontent.com/open-contracting-extensions/ocds_memberOf_extension/master/extension.json",
            "https://raw.githubusercontent.com/contratacionesabiertas/ocds_budgetBreakdown_extension/master/extension.json" 
        ];

        return extensions;
    }
    
    /**
     *  Genera los paquetes
    */
    let getPackages = async function(id, cpid, host) {
        const packages = [];

        let releases = await _db.manyOrNone('select version, release_file from logs where contractingprocess_id = $1 and id < $2 order by update_date', [cpid, id]);

        if (releases != null) {
            releases.forEach((release) => {
                packages.push(`${host}/release/${release.version}/${release.release_file}`);
            });
        }

        return packages;
    }

    /**
     * Genera un documento con los cambios de la contratacion
     * @param {Integer} cpid Identificador de la contratacion
     * @param {Object} actual Release actual
     */
    this.getChanges = async function(cpid, actual) {
        let changes = {};
        let previous = await _db.oneOrNone(`select record_json, update_date from logs where record_json is not null and contractingprocess_id = $1 order by update_date desc limit 1`, [cpid]);

        if (actual != null && Object.keys(actual).length > 0) {
            
            if (previous != null && previous.record_json != null) {
                changes = compare(actual, previous.record_json, ['ocid', 'id', 'date', 'tag', 'initiationType', 'versionedRelease']);
            } else {
                changes = actual;
            }

            let actualLog =(await _db.oneOrNone("select release_json->'tag' tag, to_char(update_date, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') update_date from logs where release_json is not null and contractingprocess_id = $1 order by update_date desc limit 1", [cpid]));
            
            changes.compiledRelease.tag = actualLog.tag;
            changes.compiledRelease.date = actualLog.update_date;
        }

        
        return clear(changes);
    }

    /**
     * Compara 2 valores y regresa los cambios entre estos
     * @param {*} obj Valor 1
     * @param {*} prevObj Valor 2
     * @param {*} ignore Propiedades a ignorar
     */
    let compare = function(obj, prevObj, ignore) {
        let change = null;

        if (obj != null) {
            // Verifica que ambos valores sean del mismo tipo de objeto
            if (prevObj != null && obj.constructor === prevObj.constructor) {
                if (obj.constructor === Object) { // Verifica si el valor es un objeto
                    change = {};
    
                    Object.keys(obj).forEach((key) => {
                        if(!ignore || ignore.indexOf(key) === -1){
                            if (prevObj[key] != null) {
                                // Si el valor 2 tiene la misma propiedad se llama recursivamente a la funcion para comparar
                                change[key] = compare(obj[key], prevObj[key], key === 'compiledRelease' ? ignore : undefined);
                            } else {
                                change[key] = clear(obj[key]);
                            }
                        } else if(ignore.indexOf(key) !== -1) {
                            change[key] = clear(obj[key]);
                        }
                    });

                } else if (obj.constructor === Array) { // Verifica si el objeto es un arreglo
                    change = [];

                    obj.map((value, index) => {
                        if(value && (value.constructor === Object ||  Array.isArray(value))){
                            change.push(compare(value, prevObj[index]));
                        } else if(value !== prevObj[index]){
                            change.push(value);
                        }
                    });
                } else {
                    if (obj !== prevObj) {
                        change = obj;
                    }
                }
            } else {
                change = obj;
            }
        }

        return clear(change);
    }


    /**
     * Compara 2 valores y ejecuta una funcion al obtener un valor diferente
     * @param {*} obj Valor 1
     * @param {*} prevObj Valor 2
     * @param {*} ignore Propiedades a ignorar
     */
    let compareAndCallback = function(obj, prevObj, ignore, callback, parentObj, parentPrev) {
        let change = null;

        if (obj != null) {
            // Verifica que ambos valores sean del mismo tipo de objeto
            if (prevObj != null && obj.constructor === prevObj.constructor) {
                if (obj.constructor === Object) { // Verifica si el valor es un objeto
                    change = {};
    
                    Object.keys(obj).forEach((key) => {
                        if(!ignore || ignore.indexOf(key) === -1){
                            if (prevObj[key] != null) {
                                // Si el valor 2 tiene la misma propiedad se llama recursivamente a la funcion para comparar
                                change[key] = compareAndCallback(obj[key], prevObj[key], ignore, callback, obj, prevObj);
                            } else {
                                change[key] = clear(obj[key]);
                            }
                        } else if(ignore.indexOf(key) !== -1) {
                            change[key] = clear(obj[key]);
                        }
                    });

                } else if (obj.constructor === Array) { // Verifica si el objeto es un arreglo
                    change = [];

                    obj.map((value, index) => {
                        if(value && (value.constructor === Object ||  Array.isArray(value))){
                            change.push(compareAndCallback(value, prevObj[index], ignore, callback, obj, prevObj));
                        } else if(value !== prevObj[index]){
                            change.push(value);
                        }
                    });
                } else {
                    if (obj !== prevObj) {
                        change = obj;
                        
                    } else {
                        callback(obj, prevObj);
                    }
                }
            } else {
                change = obj;
                
            }
        }

        return clear(change);
    }

    /**
     *  Genera el record
    */
    let generateRecord = async function(host) {
        console.log('generando record...');
        const log = await _db.oneOrNone(`select * from logs where contractingprocess_id = $1 order by id desc limit 1`, [this._cpid]);
        const release = log != null ? log.release_json : null;

        const versionedPlanning = await generateVersionedPlanning(await generateTags(1));
        const versionedTender = await generateVersionedTender(await generateTags(2));
        const versionedAwards = await generateVersionedAwards(await generateTags(3));
        const versionedContracts = await generateVersionedContracts(await generateTags(4), await generateTags(5));
        const versionedBuyer = await generateVersionedBuyer(['buyer']);
        const versionedParties = await generateVersionedParties(['party']);
   
        
        const releases = await generateRecordReleases(host);
        const date = new Date();
        let cp = await _db.one('select ocid from contractingprocess where id = $1', [this._cpid]);

        cp = cp != null ? cp : {
            ocid: ''
        };

        if (release == null) {
            const planning = await generatePlanning();
            const tender = await generateTender();
            const awards = await generateAwards();
            const contracts = await generateContracts();
            const buyer = await generateOrganizationReference('buyer');
            const parties = await generateParties();
           

            release = {
                planning: planning,
                tender: tender,
                awards: awards,
                contracts: contracts,
                buyer: buyer.length > 0 ? buyer[0] : {},
                date: moment(date).format(),
                id: cp.ocid,
                initiationType: 'tender',
                language: 'es-mx',
                ocid: cp.ocid,
                parties: parties,
                tag: ['compiled']
            };
        } else {
            // eliminar campos extra
            jp.value(release, '$.tender.clarificationMeetings[*].attendees[*].identifier.position', undefined)
            jp.value(release, '$.tender.clarificationMeetings[*].officials[*].identifier.position', undefined)

        }

        release.tag = ['compiled'];

        let record = {
            compiledRelease: release,
            ocid: cp.ocid,
            releases: releases,
            versionedRelease: {
                parties: versionedParties,
                buyer: versionedBuyer,
                planning: versionedPlanning,
                tender: versionedTender,
                awards: versionedAwards,
                contracts: versionedContracts,
                language: [{
                    releaseDate: moment(date).format(),
                    releaseID: cp.ocid,
                    releaseTag:  ['tender'],
                    value: 'es-mx'
                }],
                initiationType: [
                    {
                        releaseDate: moment(date).format(),
                        releaseID: cp.ocid,
                        releaseTag: ['tender'],
                        value: 'tender'
                    }
                ],
                ocid: cp.ocid
            }
        };

        record = clear(record);


        // revisar asignacion de tags
        await fixTags(record);
        return  record;
    }

    let fixTags = async (record) => {
        const oldRecord = await _db.oneOrNone(`select record_json from logs where contractingprocess_id = $1 and record_json is not null order by id desc limit 1`, [this._cpid]);
    
        if(oldRecord !== null && oldRecord !== undefined){
            const keysVersioned =  ['releaseDate', 'releaseID', 'releaseTag'];
            let process = (obj, prev) => {
                if(obj) {
                    if( typeof obj === 'object') {
                        Object.keys(obj).forEach(key => {
                            if(keysVersioned.indexOf(key) === -1 &&
                                obj && prev) {
                                if(process(obj[key], prev[key])) {
                                    if(obj.releaseTag && prev.releaseTag) {
                                        obj.releaseTag = prev.releaseTag;
                                    }
                                }
                            }
                        });
                    } else if(Array.isArray(obj)) {
                        obj.forEach(index => {
                            process(obj[index], prev[index]);
                        });
                    } else {
                        if(obj === prev) {
                            return true;
                        } else {
                            return false;
                        }
                    }
                }
                
            }
            
            process(record.versionedRelease, oldRecord.record_json.versionedRelease);

        }
        
    } 


    let addChanges = function(original, change) {
        if(change == null || change == undefined || original == undefined) return;
        Object.keys(change).forEach((key) => {
            if (original[key] && original[key].constructor === Array) {
                if (original[key][original[key].length - 1] && original[key][original[key].length - 1].hasOwnProperty('releaseID') && original[key][original[key].length - 1].hasOwnProperty('value')) {
                    if (original[key][original[key].length - 1].value != change[key][0].value) {
                        original[key].push(change[key][0]);
                    }
                } else {
                    addChanges(original[key][0], change[key][0]);
                }
            } else if (original[key] && typeof(original[key]) === 'object') {
                addChanges(original[key], change[key]);
            }
        });
    }

    let generateVersionedValue = function(obj, result, template, ignore, parent, processTemplate) {

        if(processTemplate) {
            template = processTemplate(template, parent);
        }

        if (obj != null && obj.constructor === Array) {
            if (obj.filter((e) => { return typeof(e) === 'object'}).length > 0) {
                let nObj = [];
                for(let i = 0; i < obj.length; i++){
                    let v= obj[i];
                    if (v != null) {
                        nObj.push(generateVersionedValue(v, (v.constructor === Array ? [] : {}), Object.assign({}, template),undefined, parent, processTemplate));
                    }
                }

                nObj.forEach((v) => {
                    let r = result.find((e) => { 
                        if(typeof e.id !== 'object' &&  e.id == v.id) {
                            return true;
                        } else if(typeof e.id === 'object' &&  ( e.id && v.id && e.id.value == v.id.value)) {
                            return true;
                        } else {
                            return false;
                        }
                     });
                
                    if (r == null) {
                        result.push(v);
                    } else {
                        addChanges(r, v);
                    }
                });
            } else {
                if (result.length == 0 || JSON.stringify(result[result.length - 1].value) != JSON.stringify(obj)) {
                    result.push(Object.assign(template, {
                        value: obj
                    }));
                }
            }

            return result;
        } else if (obj != null && typeof(obj) === 'object') {
            let keys =  Object.keys(obj);
            for(let i = 0; i < keys.length; i++) {
                let key = keys[i];
                // cuando se detecte como parent alguna de estas propiedades
                // el id se pondra como string en lugar de array
                const ids = ['amendments', 'documents', 'items', 'tenderers' , 
                'transactions',  'parties' , 'suppliers', 'milestones', 'contracts', 'awards'];
                if (obj[key] != null) {
                    if (typeof(obj[key]) === 'object') {
                        result[key] = generateVersionedValue(obj[key], result[key] || (obj[key].constructor === Array ? [] : {}), Object.assign({}, template), undefined, key, processTemplate);
                    } else {
                        if (!ignore && key === 'id' && ids.includes(parent)) {
                            // tomar unicamente el valor, en lugar del objeto para ciertos objetos
                            result[key] = obj[key];
                        } else {
                            if (result[key] == null || result[key][result[key].length - 1].value != obj[key]) {
                                let arr = (result[key] = result[key] || []);
                                if(Array.isArray(arr)){
                                    arr.push(generateVersionedValue(obj[key], result[key], Object.assign({}, template),undefined, key, processTemplate));
                                } else {
                                    result[key] = obj[key];
                                }
                               
                            }
                        }
                    }
                }
            }

            return result;
        } else {
            return Object.assign(template, {
                value: obj
            });
        }
    }

    let generatePlanning = async function() {
        let planning = await _db.oneOrNone(`select * from planning where contractingprocess_id = $1`, [this._cpid]);
        let planningUnits = await generatePlanningUnits();
        let budget = await generateBudget();
        let documents = await generateDocuments('planningdocuments');
        let requestsForQuotes = await generateRequestForQuotes();
        let tag = await _db.oneOrNone(`select * from tags where contractingprocess_id = $1 and stage = 1 order by register_date desc limit 1`, [this._cpid]);

        return {
            rationale: planning.rationale,
            hasQuotes: planning.hasquotes,
            requestingUnits: planningUnits.requestingUnits,
            contractingUnits: planningUnits.contractingUnits,
            responsibleUnits: planningUnits.responsibleUnits,
            budget: budget,
            documents: documents,
            requestsForQuotes: requestsForQuotes,
            tag: castTags(tag)
        };
    }

    let generateVersionedPlanning = async function(tags) {
        let result = {};

        try{
            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'planning' as planning from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag: tags.length === 0 ? ['planning'] : tags,
                        value: null
                    };

                    generateVersionedValue(log.planning, result, template, true);

                });
            }
        }catch(e){
            console.log('Error al generar versioned planning', e);
        }

        return result;
    }

    let generateTender = async function() {
        let tender = await _db.oneOrNone(`select * from tender where contractingprocess_id = $1`, [this._cpid]);
        let procuringEntity = await generateOrganizationReference('procuringentity');
        let items = await generateItems('tenderitem');
        let tenderers = await generateOrganizationReference('tenderer');
        let documents = await generateDocuments('tenderdocuments');
        let milestones = await generateMilestones('tendermilestone');
        let amendments = await generateAmendments('tenderamendmentchanges');
        let clarificationMeetings = await generateClarificationMeetings();
        let tag = await _db.oneOrNone(`select * from tags where contractingprocess_id = $1 and stage = 2 order by register_date desc limit 1`, [this._cpid]);

        return {
            id: tender.tenderid,
            title: tender.title,
            description: tender.description,
            status: tender.status,
            procuringEntity: procuringEntity.length > 0 ? procuringEntity[0] : null,
            items: items,
            value: {
                amount: parseFloat(tender.value_amount),
                currency: tender.value_currency
            },
            minValue: {
                amount: parseFloat(tender.minvalue_amount),
                currency: tender.minvalue_currency
            },
            procurementMethod: tender.procurementmethod,
            procurementMethodDetails: tender.procurementmethod_details,
            mainProcurementCategory: tender.mainprocurementcategory,
            additionalProcurementCategories: (() => {
                let croc;
                switch (tender.additionalprocurementcategories){
                    case 'Adquisición de bienes':
                        croc = 'goodsAcquisition';
                        break;
                    case 'Arrendamiento de bienes':
                        croc = 'goodsLease';
                        break;
                    case 'Servicios':
                        croc = 'services';
                        break;
                    case 'Servicios relacionados con obras públicas':
                        croc = 'worksRelatedServices';
                        break;
                    case 'Obras públicas':
                        croc = 'works';
                        break;
                    default:
                        croc = tender.additionalprocurementcategories;
                        break;
                }  
                return [croc]
            })(),
            awardCriteria: tender.awardcriteria,
            awardCriteriaDetails: tender.awardcriteria_details,
            submissionMethod: (() => {
                let jamg;
                switch (tender.submissionmethod) {
                    case 'Electrónica':
                        jamg = 'electronicSubmission';
                        break;
                    case 'Mixto':
                        jamg = 'written';
                        break;
                    case 'Presencial':
                        jamg = 'inPerson';
                        break;
                    case 'Subasta eletrónica':
                        jamg = 'electronicAuction';
                        break;
                    default:
                        jamg = tender.submissionmethod;
                        break;
                }
                if (jamg !== "")
                return [jamg]
            })(),
            submissionMethodDetails: tender.submissionmethod_details,
            tenderPeriod: {
                startDate: tender.tenderperiod_startdate == null ? '' : moment(tender.tenderperiod_startdate).format(),
                endDate: tender.tenderperiod_enddate == null ? '' : moment(tender.tenderperiod_enddate).format()
            },
            enquiryPeriod: {
                startDate: tender.enquiryperiod_startdate == null ? '' : moment(tender.enquiryperiod_startdate).format(),
                endDate: tender.enquiryperiod_enddate == null ? '' : moment(tender.enquiryperiod_enddate).format()
            },
            hasEnquiries: tender.hasenquiries,
            eligibilityCriteria: tender.eligibilitycriteria,
            awardPeriod: {
                startDate: tender.awardperiod_startdate == null ? '' : moment(tender.awardperiod_startdate).format(),
                endDate: tender.awardperiod_enddate == null ? '' : moment(tender.awardperiod_enddate).format()
            },
            numberOfTenderers: tender.numberoftenderers,
            tenderers: tenderers,
            documents: documents,
            milestones: milestones,
            amendments: amendments,
            clarificationMeetings: clarificationMeetings,
            tag: castTags(tag)
        };
    }

    let generateVersionedTender = async function(tags) {
        let result = {};
        try{

            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'tender' as tender from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag: tags.length > 0 ? tags : ['tender'],
                        value: null
                    };
    
                    if(log.tender.items){
                        log.tender.items.forEach((item) => {
                            if (item.unit != null) {
                                item.unit = item.unit;
                            }
                        });
                    }
    
                    generateVersionedValue(log.tender, result, template, true);

                });
            }
        }
        catch(e){
            console.log('Error al generar versioned tender', e);
        }

        return result;
    }

    let generateAwards = async function() {
        const awards = [];

        let nAwards = await _db.manyOrNone(`select * from award where contractingprocess_id = $1`, [this._cpid]);
        let items = await generateItems('awarditem', 'award_id');
        let documents = await generateDocuments('awarddocuments', 'award_id');
        let amendments = await generateAmendments('awardamendmentchanges', 'award_id');
        let suppliers = await _db.manyOrNone(`select parties.identifier_scheme, parties.identifier_id, parties.identifier_legalname, awardsupplier.award_id from parties inner join awardsupplier on awardsupplier.parties_id = parties.id inner join award on award.id = awardsupplier.award_id where award.contractingprocess_id = $1`, [this._cpid]);
        let tag = await _db.oneOrNone(`select * from tags where contractingprocess_id = $1 and stage = 3 order by register_date desc limit 1`, [this._cpid]);
        let tags = castTags(tag);

        if (nAwards != null) {
            nAwards.forEach((award) => {
                awards.push({
                    id: award.awardid,
                    title: award.title,
                    description: award.description,
                    status: award.status,
                    date: award.award_date == null ? '' : moment(award.award_date).format(),
                    value: {
                        amount: parseFloat(award.value_amount),
                        currency: award.value_currency
                    },
                    suppliers: suppliers.filter((e) => e.award_id == award.id)
                                        .map((e) => { return { 
                                            scheme: e.identifier_scheme, 
                                            id: e.identifier_id, 
                                            legalName: e.identifier_legalname
                                        }}),
                    items: items[award.id],
                    contractPeriod: {
                        startDate: award.contractperiod_startdate == null ? '' : moment(award.contractperiod_startdate).format(),
                        endDate: award.contractperiod_enddate == null ? '' : moment(award.contractperiod_enddate).format()
                    },
                    documents: documents[award.id],
                    amendments: amendments[award.id],
                    rationale: award.rationale,
                    tag: tags
                });
            });
        }

        return awards;
    }

    let generateVersionedAwards = async function(tags) {
        let result = [];
        try{

            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'awards' as awards from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag: tags.length > 0 ? tags : ['award'],
                        value: null
                    };
    
                    if (log.awards != null) {
                        log.awards.forEach((award, index) => {
                            if (award.items != null) {
                                award.items.forEach((item) => {
                                    if (item.unit != null) {
                                        item.unit = item.unit;
                                    }
                                });
                            }
    
                            result[index] = generateVersionedValue(award, result[index] || {}, template, undefined, 'awards');
                        });
                    }
                });
            }
        }
        catch(e){
            console.log('Error al generar versioned awards', e);
        }

        return result;
    }

    let generateContracts = async function() {
        const contracts = [];

        let nContracts = await _db.manyOrNone(`select * from contract where contractingprocess_id = $1`, [this._cpid]);
        let awards = await _db.manyOrNone(`select id, awardid from award where contractingprocess_id = $1`, [this._cpid]);
        let items = await generateItems('contractitem', 'contract_id');
        let documents = await generateDocuments('contractdocuments', 'contract_id');
        let amendments = await generateAmendments('contractamendmentchanges', 'contract_id');
        let implementations = await _db.manyOrNone(`select * from implementation where contractingprocess_id = $1`, [this._cpid]);
        let implementationDocuments = await generateDocuments('implementationmilestonedocuments', 'implementation_id');
        let implementationTransactions = await generateTransactions('implementationtransactions', 'implementation_id');
        let implementationMilestones = await generateMilestones('implementationmilestone', 'implementation_id');
        let tag = await _db.oneOrNone(`select * from tags where contractingprocess_id = $1 and stage = 4 order by register_date desc limit 1`, [this._cpid]);
        let tags = castTags(tag);

        if (nContracts != null) {
            nContracts.forEach((contract) => {
                let implementation = implementations.filter((e) => e.contract_id === contract.id)[0];

                contracts.push({
                    id: contract.contractid,
                    awardID: contract.awardid !== null ? awards.find((e) => e.id == contract.awardid).awardid : '',
                    title: contract.title,
                    description: contract.description,
                    status: contract.status,
                    period: {
                        startDate: contract.period_startdate == null ? '' : moment(contract.period_startdate).format(),
                        endDate: contract.period_enddate == null ? '' : moment(contract.period_enddate).format()
                    },
                    value: {
                        netAmount: parseFloat(contract.value_amountnet),
                        amount: parseFloat(contract.value_amount),
                        currency: contract.value_currency,
                        exchangeRates: [{
                            currency: contract.exchangerate_currency,
                            rate: parseFloat(contract.exchangerate_rate),
                            date: contract.exchangerate_date == null ? '' : moment(contract.exchangerate_date).format(),
                            source: contract.exchangerate_source
                        }]
                    },
                    items: items[contract.id],
                    dateSigned: contract.datesigned == null ? '' : moment(contract.datesigned).format(),
                    documents: documents[contract.id],
                    implementation: {
                        transactions: implementation != null ? implementationTransactions[contract.id] : [],
                        milestones: implementation != null ? implementationMilestones[contract.id] : [],
                        documents: implementation != null ? implementationDocuments[contract.id] : []
                    },
                    amendments: amendments[contract.id],
                    surveillanceMechanisms : contract.surveillancemechanisms ? [contract.surveillancemechanisms] : undefined,
                    tag: tags
                });
            });
        }

        return contracts;
    }

    let generateVersionedContracts = async function(tags, tagsImplementation) {
        let result = [];
        try{

            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'contracts' as contracts from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag:  tags.length > 0 ? tags : ['contract'],
                        value: null
                    };
    
                    if (log.contracts != null) {
                        log.contracts.forEach((contract, index) => {
                            if (contract.items != null) {
                                contract.items.forEach((item) => {
                                    if (item.unit != null) {
                                        item.unit = item.unit;
                                    }
                                });
                            }
    
                            result[index] = generateVersionedValue(contract, result[index] || {}, template, undefined, 'contracts', (templ, parent) =>{
                                if(parent === 'implementation'){
                                    templ.releaseTag = tagsImplementation.length > 0 ? tagsImplementation : ['implementation'];
                                } else if(parent === 'contract') {
                                    templ.releaseTag = tags.length > 0 ? tags : ['contract'];
                                }
                                return templ;
                            });
                        });
                    }
                });
            }
        }
        catch(e){
            console.log('Error al generar versioned contracts', e);
        }

        return result;
    }

    let generateRecordReleases = async function(host) {
        const releases = [];
        const validTags = [
            { original: 'planningupdate', valid: 'planningUpdate' },
            { original: 'tenderamendment', valid: 'tenderAmendment' },
            { original: 'tenderupdate', valid: 'tenderUpdate' },
            { original: 'tendercancellation', valid: 'tenderCancellation' },
            { original: 'awardupdate', valid: 'awardUpdate' },
            { original: 'awardcancellation', valid: 'awardCancellation' },
            { original: 'contractupdate', valid: 'contractUpdate' },
            { original: 'contractamendment', valid: 'contractAmendment' },
            { original: 'implementationupdate', valid: 'implementationUpdate' },
            { original: 'contracttermination', valid: 'contractTermination' }
        ];

        let logs = await _db.manyOrNone(`select version, release_file, release_json -> 'date' as date, release_json -> 'tag' as tag
            from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

        if (logs != null) {
            logs.forEach((log) => {
                releases.push({
                    date: moment(log.date).format(),
                    tag: log.tag != null ? log.tag.map((e) => {
                        let nTag = validTags.find(x => x.original == e);
            
                        return nTag != null ? nTag.valid : e;
                    }) : [],
                    url: `${host}/release/${log.version}/${log.release_file}`
                });
            });
        }

        return releases;
    }

    let generateBudget = async function() {
        let budget = await _db.oneOrNone(`select * from budget where contractingprocess_id = $1`, [this._cpid]);
        let budgetBreakdown = await generateBudgetBreakdown();

        return budget != null ? {
            id: budget.budget_budgetid,
            description: budget.budget_description,
            amount: {
                amount: parseFloat(budget.budget_amount),
                currency: budget.budget_currency
            },
            project: budget.budget_project,
            projectID: budget.budget_projectid,
            uri: budget.uri,
            source: budget.budget_source,
            budgetBreakdown: budgetBreakdown
        } : {}
    }

    let generatePlanningUnits = async function() {
        console.log(" ### generatePlanningUnits")
        let planningUnits = await _db.manyOrNone("select * from planning_party_units p where p.contractingprocess_id = $1 order by p.id", [this._cpid]);
        
        if(planningUnits !== null){
            var arrayRequestingUnit = new Array();
            var arrayContractingUnit = new Array();
            var arrayResponsibleUnit = new Array();
            var units = new Object();
            planningUnits.forEach(element => {
                if(element.requesting_unit === true){
                    var objUnit = new Object();
                    objUnit.id = element.party_code;
                    objUnit.name = element.party_name;
                    arrayRequestingUnit.push(objUnit);
                }
                if(element.contracting_unit === true){
                    var objUnit = new Object();
                    objUnit.id = element.party_code;
                    objUnit.name = element.party_name;
                    arrayContractingUnit.push(objUnit);
                }
                if(element.responsible_unit === true){
                    var objUnit = new Object();
                    objUnit.id = element.party_code;
                    objUnit.name = element.party_name;
                    arrayResponsibleUnit.push(objUnit);
                }
            });
        }
        units.requestingUnits = arrayRequestingUnit;
        units.contractingUnits = arrayContractingUnit;
        units.responsibleUnits = arrayResponsibleUnit;
        console.log(" ### generatePlanningUnits UNITS " + JSON.stringify(units))
        return units != null ? units : {}
    }

    let generateItems = async function(table, groupby) {
        function toItem(item) {
            return item != null ? {
                id: item.itemid,
                description: item.description,
                classification: {
                    scheme: item.classification_scheme,
                    id: item.classification_id,
                    description: item.classification_description,
                },
                quantity: item.quantity,
                unit: {
                    name: item.unit_name,
                    amount: parseFloat(item.unit_value_amount),
                    netAmount: parseFloat(item.unit_value_amountnet),
                    currency: item.unit_value_amountnet
                },
                deliveryLocation: {
                    geometry: {
                        type: 'Point',
                        coordinates: item.longitude &&  item.latitude ? [item.longitude, item.latitude] : undefined
                    },
                    gazetteer: {
                        scheme: item.gazetteer_scheme,
                        identifiers: item.gazetteer_identifiers ? [item.gazetteer_identifiers] : undefined
                    },
                    description: item.location_description,
                    url: item.location_url
                },
                deliveryAddress: {
                    streetAddress: item.location_streetaddress,
                    locality: item.location_locality,
                    region: item.location_region,
                    postalCode: item.location_postalcode,
                    countryName: item.location_countryname
                }
            } : {};
        }

        let items = await _db.manyOrNone(`select * from $1~ where contractingprocess_id = $2`, [table, this._cpid]);

        if (groupby != null) {
            return items != null ? items.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toItem(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return items != null ? items.map((item) => { return toItem(item); }) : [];
        }
    }

    let generateDocuments = async function(table, groupby) {
        function toDocument(document) {
            return document != null ? {
                id: document.documentid,
                documentType: document.document_type,
                title: document.title,
                description: document.description,
                url: document.url,
                datePublished: document.date_published == null ? '' : moment(document.date_published).format(),
                dateModified: document.date_modified == null ? '' : moment(document.date_modified).format(),
                format: document.format,
                language: document.language
            } : {};
        }

        let documents = await _db.manyOrNone(`select * from $1~ where contractingprocess_id = $2`, [table, this._cpid]);

        if (groupby != null) {
            return documents != null ? documents.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toDocument(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return documents != null ? documents.map((document) => { return toDocument(document); }) : [];
        }
    }

    let generateAmendments = async function(table, groupby) {
        function toAmendment(amendment) {
            return amendment != null ? {
                date: amendment.amendments_date == null ? '' : moment(amendment.amendments_date).format(),
                rationale: amendment.amendments_rationale,
                id: amendment.amendments_id,
                description: amendment.amendments_description
            } : {};
        }

        let amendments = await _db.manyOrNone(`select * from $1~ where contractingprocess_id = $2`, [table, this._cpid]);

        if (groupby != null) {
            return amendments != null ? amendments.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toAmendment(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return amendments != null ? amendments.map((amendment) => { return toAmendment(amendment); }) : [];
        }
    }

    let generateMilestones = async function(table, groupby) {
        function toMilestone(milestone) {
            return milestone != null ? {
                id: milestone.milestoneid,
                title: milestone.title,
                type: milestone.type,
                description: milestone.description,
                dueDate: milestone.duedate == null ? '' : moment(milestone.duedate).format(),
                dateModified: milestone.date_modified == null ? '' : moment(milestone.date_modified).format(),
                status: milestone.status
            } : {};
        }

        let milestones = await _db.manyOrNone(`select * from $1~ where contractingprocess_id = $2`, [table, this._cpid]);

        if (groupby != null) {
            return milestones != null ? milestones.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toMilestone(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return milestones != null ? milestones.map((milestone) => { return toMilestone(milestone); }) : [];
        }
    }

    let generateTransactions = async function(table, groupby) {
        function toTransaction(transaction, payers, payee) {
            return transaction != null ? {
                id: transaction.transactionid,
                source: transaction.source,
                date: transaction.implementation_date == null ? '' : moment(transaction.implementation_date).format(),
                value: {
                    amount: parseFloat(transaction.value_amount),
                    currency: transaction.value_currency
                },
                payer: payers.find((e) => e.id === transaction.payer_id),
                payee: payee.find((e) => e.id === transaction.payee_id)
            } : {};
        }

        let transactions = await _db.manyOrNone(`select * from $1~ where contractingprocess_id = $2`, [table, this._cpid]);
        let payers = await generateOrganizationReference('payer');
        let payee = await generateOrganizationReference('payee');

        if (groupby != null) {
            return transactions != null ? transactions.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toTransaction(cv, payers, payee));
                
                return pv;
            }, {}) : {};
        } else {
            return transactions != null ? transactions.map((transaction) => { return toTransaction(transaction, payers, payee); }) : [];
        }
    }

    let generateClarificationMeetings = async function() {
        function toOrganizationsReference(party) {
            return party != null ? {
                name: party.name,
                id: party.partyid,
                identifier: {
                    scheme: party.identifier_scheme,
                    id: party.identifier_id,
                    legalName: party.identifier_legalname
                }
            } : {};
        }

        let meetings = await _db.manyOrNone(`select * from clarificationmeeting where contractingprocess_id = $1`, [this._cpid]);
        let attenders = await _db.manyOrNone(`select parties.*, clarificationmeeting.id as clarificationmeeting from clarificationmeetingactor inner join parties on parties.id = clarificationmeetingactor.parties_id inner join clarificationmeeting on clarificationmeeting.id = clarificationmeetingactor.clarificationmeeting_id where clarificationmeeting.contractingprocess_id = $1 and clarificationmeetingactor.attender = true`, [this._cpid]);
        let officials = await _db.manyOrNone(`select parties.*, clarificationmeeting.id as clarificationmeeting from clarificationmeetingactor inner join parties on parties.id = clarificationmeetingactor.parties_id inner join clarificationmeeting on clarificationmeeting.id = clarificationmeetingactor.clarificationmeeting_id where clarificationmeeting.contractingprocess_id = $1 and clarificationmeetingactor.official = true`, [this._cpid]);

        return meetings != null ? meetings.map((meeting) => {
            return {
                id: meeting.clarificationmeetingid,
                date: meeting.date == null ? '' : moment(meeting.date).format(),
                attendees: attenders != null && attenders.filter((x) => x.clarificationmeeting == meeting.id).length > 0 ? 
                    attenders.filter((x) => x.clarificationmeeting == meeting.id).map((x) => { return toOrganizationsReference(x); }) : [],
                officials: officials != null && officials.filter((x) => x.clarificationmeeting == meeting.id).length > 0 ? 
                    officials.filter((x) => x.clarificationmeeting == meeting.id).map((x) => { return toOrganizationsReference(x); }) : []
            };
        }) : [];
    }

    let generateRequestForQuotes = async function() {
        function toOrganizationsReference(party) {
            return party != null ? {
                name: party.name,
                id: party.partyid,
                identifier: {
                    scheme: party.identifier_scheme,
                    id: party.identifier_id,
                    legalName: party.identifier_legalname
                }
            } : {};
        }

        let requests = await _db.manyOrNone(`select * from requestforquotes where contractingprocess_id = $1`, [this._cpid]);
        let items = await generateRequestForQuotesItems('requestforquotes_id');
        let quotes = await generateQuotes('requestforquotes_id');
        let suppliers = await _db.manyOrNone(`select parties.*, requestforquotes.id as request from requestforquotesinvitedsuppliers inner join parties on parties.id = requestforquotesinvitedsuppliers.parties_id inner join requestforquotes on requestforquotes.id = requestforquotesinvitedsuppliers.requestforquotes_id where requestforquotes.contractingprocess_id = $1`, [this._cpid]);

        return requests != null ? requests.map((request) => {
            return {
                id: request.requestforquotes_id,
                title: request.title,
                description: request.description,
                period: {
                    startDate: request.period_startdate == null ? '' : moment(request.period_startdate).format(),
                    endDate: request.period_enddate == null ? '' : moment(request.period_enddate).format()
                },
                items: items[request.id],
                invitedSuppliers: suppliers != null && suppliers.filter((x) => x.request == request.id).length > 0 ? 
                    suppliers.filter((x) => x.request == request.id).map((x) => { return toOrganizationsReference(x); }) : [],
                quotes: quotes[request.id]
            };
        }) : [];
    }

    let generateQuotes = async function(groupby) {
        function toOrganizationsReference(party) {
            return party != null ? {
                name: party.name,
                id: party.partyid,
                identifier: {
                    scheme: party.identifier_scheme,
                    id: party.identifier_id,
                    legalName: party.identifier_legalname
                }
            } : {};
        }

        function toQuote(quote, items, suppliers) {
            return quote != null ? {
                id: quote.quotes_id,
                description: quote.description,
                date: quote.date == null ? '' : moment(quote.date).format(),
                items: items[quote.id],
                value: {
                    amount: parseFloat(quote.value)
                },
                period: {
                    startDate: quote.quoteperiod_startdate == null ? '' : moment(quote.quoteperiod_startdate).format(),
                    endDate: quote.quoteperiod_enddate == null ? '' : moment(quote.quoteperiod_enddate).format()
                },
                issuingSupplier: suppliers != null && suppliers.filter((x) => x.quote == quote.id).length > 0 ? 
                    suppliers.filter((x) => x.quote == quote.id).map((x) => { return toOrganizationsReference(x); }) : []
            } : {};
        }

        let quotes = await _db.manyOrNone(`select quotes.* from quotes inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id where requestforquotes.contractingprocess_id = $1`, [this._cpid]);
        let items = generateQuotesItems('quotes_id');
        let suppliers = await _db.manyOrNone(`select parties.*, quotes.id as quote from quotes inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id inner join parties on parties.id = quotes.issuingsupplier_id where requestforquotes.contractingprocess_id = $1`, [this._cpid]);

        if (groupby != null) {
            return quotes != null ? quotes.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toQuote(cv, items, suppliers));
                
                return pv;
            }, {}) : {};
        } else {
            return quotes != null ? quotes.map((quote) => { return toQuote(quote, items, suppliers); }) : [];
        }
    }

    let generateRequestForQuotesItems = async function(groupby) {
        function toItem(item) {
            return item != null ? {
                id: item.itemid,
                description: item.item,
                quantity: parseFloat(item.quantity)
            } : {};
        }

        let items = await _db.manyOrNone(`select requestforquotesitems.* from requestforquotesitems inner join requestforquotes on requestforquotes.id = requestforquotesitems.requestforquotes_id where requestforquotes.contractingprocess_id = $1`, [this._cpid]);

        if (groupby != null) {
            return items != null ? items.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toItem(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return items != null ? items.map((item) => { return toItem(item); }) : [];
        }
    }

    let generateQuotesItems = async function(groupby) {
        function toItem(item) {
            return item != null ? {
                id: item.itemid,
                description: item.item,
                quantity: parseFloat(item.quantity)
            } : {};
        }

        let items = await _db.manyOrNone(`select quotesitems.* from quotesitems inner join quotes on quotes.id = quotesitems.quotes_id inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id where requestforquotes.contractingprocess_id = $1`, [this._cpid]);

        if (groupby != null) {
            return items != null ? items.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toItem(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return items != null ? items.map((item) => { return toItem(item); }) : [];
        }
    }

    let generateBudgetBreakdown = async function() {
        let breakdowns = await _db.manyOrNone(`select * from budgetbreakdown where contractingprocess_id = $1`, [this._cpid]);
        let classifications = await generateBudgetClassifications('budgetbreakdown_id');

        return breakdowns != null ? breakdowns.map((breakdown) => {
            return {
                period: {
                    startDate: breakdown.budgetbreakdownperiod_startdate == null ? '' : moment(breakdown.budgetbreakdownperiod_startdate).format(),
                    endDate: breakdown.budgetbreakdownperiod_enddate == null ? '' : moment(breakdown.budgetbreakdownperiod_enddate).format()
                },
                id: breakdown.budgetbreakdown_id,
                description: breakdown.description,
                amount: {
                    amount: parseFloat(breakdown.amount),
                    currency: breakdown.currency
                },
                origin: breakdown.origin, 
                fundType: breakdown.fund_type, 
                budgetLines: classifications[breakdown.id]
            };
        }) : [];
    }

    let generateBudgetClassifications = async function(groupby) {
        function toClassification(classification) {
            var components = [];
            var measures = [];

            Object.keys(classification).forEach((key) => {
                if (['approved', 'modified', 'executed', 'committed', 'reserved'].indexOf(key) > -1) {
                    measures.push({
                        id: key,
                        value: {
                            amount: classification[key],
                            currency: classification['currency']
                        }
                    });
                } else if (['id', 'budgetbreakdown_id', 'currency'].indexOf(key) == -1) {
                    components.push({
                        name: key,
                        level: components.length + 1,
                        code: classification[key],
                        description: classification[key]
                    });
                }
            });


            return classification != null ? {
                components: components,
                measures: measures
            } : {};
        }

        let classifications = await _db.manyOrNone(`select budgetclassifications.*, budgetbreakdown.currency from budgetclassifications inner join budgetbreakdown on budgetbreakdown.id = budgetclassifications.budgetbreakdown_id where budgetbreakdown.contractingprocess_id = $1`, [this._cpid]);

        if (groupby != null) {
            return classifications != null ? classifications.reduce((pv, cv) => {
                (pv[cv[groupby]] = pv[cv[groupby]] || []).push(toClassification(cv));
                
                return pv;
            }, {}) : {};
        } else {
            return classifications != null ? classifications.map((classification) => { return toClassification(classification); }) : [];
        }
    }

    let generateOrganizationReference = async function(role) {
        let actors = await _db.manyOrNone(`select parties.* from parties inner join roles on roles.parties_id = parties.id
            where parties.contractingprocess_id = $1 and $2~ = true`, [this._cpid, role]);

        return actors != null ? actors.map((e) => {
            return {
                name: e.name,
                id: e.partyid,
                identifier: { 
                    scheme: e.identifier_scheme,
                    id: e.identifier_id,
                    legalName: e.identifier_legalname
                }
            };
        }) : [];
    }

    let generateVersionedBuyer = async function() {
        let result = {};
        try{
            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'buyer' as buyer from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag: ['buyer'],
                        value: null
                    };

                    generateVersionedValue(log.buyer, result, template);

                });
            }
        }catch(e){
            console.log('Error al generar versioned buyer',e);
        }

        return result;
    }

    let generateParties = async function() {
        let parties = await _db.manyOrNone(`select * from parties where contractingprocess_id = $1`, [this._cpid]);
        let roles = await generateRoles();

        return parties.map((party) => {
            return {
                name: party.name,
                id: party.partyid,
                identifier: { 
                    scheme: party.identifier_scheme,
                    id: party.identifier_id,
                    legalName: party.identifier_legalname,
                    legalPersonality: party.naturalperson ? 'naturalPerson' : 'legalPerson',
                    givenName: party.givenname,
                    patronymicName: party.surname,
                    matronymicName: party.additionalsurname
                },
                address: {
                    streetAddress: party.address_streetaddress,
                    locality: party.address_locality,
                    region: party.address_region,
                    postalCode: party.address_postalcode,
                    countryName: party.address_countryname
                },
                contactPoint: {
                    name: party.contactpoint_name,
                    email: party.contactpoint_email,
                    telephone: party.contactpoint_telephone,
                    faxNumber: party.contactpoint_faxnumber,
                    url: party.contactpoint_url,
                    type: party.contactpoint_type,
                    givenName: party.contactpoint_givenname,
                    patronymicName: party.contactpoint_surname,
                    matronymicName: party.contactpoint_additionalsurname,
                    availableLanguage: party.contactpoint_language ? party.contactpoint_language.split(',') : undefined
                },
                roles: roles[party.id]
            };
        });
    }

    let generateRoles = async function() {
        let roles = await _db.manyOrNone(`select * from roles where contractingprocess_id = $1`, [this._cpid]);

        return roles != null ? roles.reduce((pv, cv) => {
            pv[cv['parties_id']] = Object.keys(cv).filter((key) => cv[key] === true);
            
            return pv;
        }, {}) : {};
    }

    let generateVersionedParties = async function() {
        let result = [];
        try{

            let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'parties' as parties from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

            if (logs != null) {
                logs.forEach((log) => {
                    let template = {
                        releaseDate: moment(log.update_date).format(),
                        releaseID: log.ocid,
                        releaseTag: ['party'],
                        value: null
                    };
    
                    if (log.parties != null) {
                        log.parties.forEach((party, index) => {
                            result[index] = generateVersionedValue(party, result[index] || {}, template, undefined , 'parties');
                        });
                    }
                });
            }
        }
        catch(e){
            console.log('Error al generar versioned parties',e);
        }

        return result;
    }

    let generateTags = async function(stage) {
        let tags = await _db.oneOrNone(`select * from tags where contractingprocess_id = $1 and stage = $2
            order by register_date desc limit 1`, [this._cpid, stage]);
        return castTags(tags);
    }

    let generateVersionedTags = async function() {
        let result = [];
        let logs = await db.manyOrNone(`select update_date, release_json -> 'ocid' as ocid, release_json -> 'tags' as tags from logs where contractingprocess_id = $1 order by update_date`, [this._cpid]);

        if (logs != null) {
            logs.forEach((log) => {
                let template = {
                    releaseDate: moment(log.update_date).format(),
                    releaseID: log.ocid,
                    releaseTag: ['tag'],
                    value: null
                };

                if (log.tags != null) {
                    log.tags.forEach((tag, index) => {
                        result[index] = generateVersionedValue(tag, result[index] || [], template);
                    });
                }
            });
        }

        return result;
    }

    let castTags = function(tags) {
        const validTags = [
            { original: 'planningupdate', valid: 'planningUpdate' },
            { original: 'tenderamendment', valid: 'tenderAmendment' },
            { original: 'tenderupdate', valid: 'tenderUpdate' },
            { original: 'tendercancellation', valid: 'tenderCancellation' },
            { original: 'awardupdate', valid: 'awardUpdate' },
            { original: 'awardcancellation', valid: 'awardCancellation' },
            { original: 'contractupdate', valid: 'contractUpdate' },
            { original: 'contractamendment', valid: 'contractAmendment' },
            { original: 'implementationupdate', valid: 'implementationUpdate' },
            { original: 'contracttermination', valid: 'contractTermination' }
        ];
        let nTags = [];

        if(tags !== null){
            Object.keys(tags).filter((key) => tags[key] === true).forEach((v) => {
                if (nTags.indexOf(v) == -1) {
                    nTags.push(v);
                }
            });
        }

        return nTags.map((e) => {
            let nTag = validTags.find(x => x.original == e);

            return nTag != null ? nTag.valid : e;
        });
    }

    let clear = function(data) {
        if(data){
            Object.keys(data).forEach((key) => {
                if (data[key] == null || data[key] == '' || (data[key].constructor === Object && Object.keys(data[key]).length === 0) || (data[key].constructor === Array && data[key].length === 0)) {
                    delete data[key];
                } else {
                    if (data[key].constructor == Array) {
                        data[key].forEach((v) => {
                            clear(v);
                        });

                        data[key] = data[key].filter((x) => !(x == null || x == '' || (x.constructor === Object && Object.keys(x).length === 0) || (x.constructor === Array && x.length === 0)));

                        if (data[key].length === 0) {
                            delete data[key];
                        }
                    } else if (typeof(data[key]) === 'object') {
                        let result = clear(data[key]);

                        if (result == null || result == '' || (result.constructor === Object && Object.keys(result).length === 0) || (result.constructor === Array && result.length === 0)) {
                            delete data[key];
                        }
                    }
                }
            });
        }

        return data;
    }

    return this;
}



    /**
     * Limpiar propiedades vacias
     * @param {Object} obj Objeto a limpiar de propiedades vacias
     */
    let clean = obj => {
        Object.keys(obj).map(key => {
            if (obj[key] === undefined ||
                obj[key] === null ||
                (Array.isArray(obj[key]) && obj[key].length === 0) ||
                (typeof obj[key] === 'object' && !(obj[key] instanceof Date) && Object.keys(obj[key]).length === 0) ||
                (typeof obj[key] === 'string' && obj[key].trim() === '') ||
                (typeof obj[key] === 'number' && isNaN(obj[key]))) {
                delete obj[key];
            }
        });
        return obj;
    }
module.exports = record;