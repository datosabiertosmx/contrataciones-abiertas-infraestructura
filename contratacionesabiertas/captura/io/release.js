var User = require('../models/user');
// moment format
var moment = require('moment'); // require 

/**
 * Generación del release 
 *
 * @param {IDBDatabase} db Instancia de la base de datos
 */
function release(db) {
    const _db = db;
    let _cpid;
    let _ocidname;

    const _extensions = [
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

    this.extensions = _extensions;

    /**
     * Genera un documento con los cambios de la contratacion
     * @param {Integer} cpid Identificador de la contratacion
     * @param {Object} actual Release actual
     */
    this.getChanges = async function(cpid, actual) {
        let changes = {};
        let previous = await _db.oneOrNone(`select release_json from logs where contractingprocess_id = $1 order by update_date desc limit 1`, [cpid]);

        if (actual != null && Object.keys(actual).length > 0) {
            if (previous != null && previous.release_json != null) {
                changes = compare(actual, previous.release_json, ['ocid', 'id', 'date', 'tag', 'initiationType', 'language']);
            } else {
                changes = actual;
            }
        }

        return clear(changes);
    }

    this.checkReleaseIfExists = async function (cpid) {
        let log = await _db.oneOrNone(`select id, release_json from logs where contractingprocess_id = $1 limit 1`, [cpid]);
        if (!log || !log.release_json || log.release_json === null) {
            let { ocid } = await _db.oneOrNone('select ocid from contractingprocess where id = $1', [cpid]);
            let ocidname = `${ocid}`;
            let json = await this.generateRelease(cpid, ocidname)
            log = await _db.one(`insert into logs (version, update_date, publisher, release_file, contractingProcess_id, release_json)
                                values ($1, clock_timestamp(), $2, $3, $4, $5) returning id`, [
                    0,
                    null,
                    ocidname,
                    cpid,
                    json
                ]);
        }

        return log.id;
    }

    /**
     * Genera release de una contratación
     * @param {Integer} cpid ID de la contratación
     * @param {String} ocidname Nombre del archivo
     */
    this.generateRelease = async function (cpid, ocidname) {
        // se establece el id de la contratación a utilizar en todo el proceso
        this._cpid = cpid;
        this._ocidname = ocidname;

        return await generateRelease();
    }

    /**
     * Generar package de una contratación
     * @param {String} version Numero de version
     * @param {String} releasefile Nombre del archivo
     * @param {String} host Url del host
     */
    this.getPackage = async function (version, releasefile, host) {
        let log = await _db.oneOrNone(`select id,publisher,update_date,release_file,version,release_json,contractingprocess_id from logs where version = $1 and release_file =$2 limit 1`, [version, releasefile]);

        if (!log) return { message: 'No se ha generado el release de la contratación' };

        let user = (await _db.oneOrNone('select * from publisher where contractingprocess_id = $1', [log.contractingprocess_id])) || {};

        if (host.endsWith('/')) host = host.substring(0, host.length - 1);

        let { uri, license, publicationpolicy } = await _db.oneOrNone('select uri, license, publicationpolicy from contractingprocess where id = $1', [log.contractingprocess_id]);
        
        var obj = new Object();
        var objPublisher = new Object();
        obj.uri = `${host}/release-package/${log.version}/${log.release_file}`;
        obj.version = '1.1';
        obj.extensions = _extensions;
        obj.publishedDate = moment(log.update_date).format(),
        obj.releases = [log.release_json];
        objPublisher.name = user.name;
        objPublisher.scheme = user.scheme;
        objPublisher.uid = user.uid;
        if(uri !== '')
        objPublisher.uri = uri;
        obj.publisher = objPublisher;
        if(license !== '')
        obj.license = license;
        if(publicationpolicy !== '')
        obj.publicationPolicy = publicationpolicy;
        return obj;
    }

    /**
     * Generar package con todos los releases de una contratación
     * @param {String} ocid OCID
     * @param {String} host Url del host
     */
    this.getPackageAll = async function (ocid, host) {
        let logs = await _db.manyOrNone(`select contractingprocess_id, release_json, publisher, update_date  from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1) order by id desc`, [ocid]);

        if (!logs || logs.length === 0) return { message: 'No se ha generado el release de la contratación' };

        let user = (await _db.oneOrNone('select * from publisher where contractingprocess_id = $1', [logs[0].contractingprocess_id])) || {};

        let { license, publicationpolicy } = await _db.oneOrNone('select uri, license, publicationpolicy from contractingprocess where id = $1', [logs[0].contractingprocess_id]);

        return {
            uri: `${host}/release-package-all/${ocid}`,
            version: '1.1',
            publishedDate: moment(logs[0].update_date).format(),
            releases: logs.map(x => x.release_json),
            publisher: clean({
                name: user.name,
                scheme: user.scheme,
                uid: user.uid,
                uri: user.uri
            }),
            license: license,
            publicationPolicy: publicationpolicy,
        };
    }

    /**
     * Generar open contracting release
     */
    let generateRelease = async function () {
        console.log('generando release');
        let cp = await one('contractingprocess', 'id', this._cpid);

        if (!cp) throw new Error('No se ha podido encontrar la contratación');

        cp.date_modified = new Date();

        cp = clean({
            ocid: cp.ocid,
            id: this._ocidname,
            date: moment(cp.date_modified).format(),
            tag: await generateTags(),
            initiationType: 'tender',
            parties: await generateParties(),
            planning: await generatePlanning(),
            tender: await generateTender(),
            buyer: await generateOrganizationReference('buyer'),
            awards: await generateAwards(),
            contracts: await generateContracts(),
            relatedProcesses: await generateRelatedProcesses(),
            language: 'es'
        });

        return cp;
    }

    /**
     * Genera los tags de la contatación
     */
    let generateTags = async function () {
        // se obtienen los tags mas actuales de cada etapa de la contratacion
        let sql = 'select * from tags where contractingprocess_id = $1 order by id desc limit 1';
        let tags1 = await _db.oneOrNone(sql, [this._cpid])

        let tags = [];

        let add = (t) => {
            if (t != null) {
                Object.keys(t).map(x => {
                    if (t[x] === true && tags.indexOf(x) === -1) tags.push(x);
                });
            }
        }

        if (!tags1) return;

        add(tags1);

        // corregir nombre de tags
        tags = tags.map(x => {
            switch (x) {
                case 'planningupdate':
                    x = 'planningUpdate';
                    break;
                case 'tenderamendment':
                    x = 'tenderAmendment';
                    break;
                case 'tenderupdate':
                    x = 'tenderUpdate';
                    break;
                case 'tendercancellation':
                    x = 'tenderCancellation';
                    break;
                case 'awardupdate':
                    x = 'awardUpdate';
                    break;
                case 'awardcancellation':
                    x = 'awardCancellation';
                    break;
                case 'contractupdate':
                    x = 'contractUpdate';
                    break;
                case 'contractamendment':
                    x = 'contractAmendment';
                    break;
                case 'implementationupdate':
                    x = 'implementationUpdate';
                    break;
                case 'contracttermination':
                    x = 'contractTermination';
                    break;
            }
            return x;
        });

        if (tags.length === 0) {
            switch (tags1.stage) {
                case 1: tags = ['planningUpdate']; break;
                case 2: tags = ['tenderUpdate']; break;
                case 3: tags = ['awardUpdate']; break;
                case 4: tags = ['contractUpdate']; break;
                case 5: tags = ['implementationUpdate']; break;
            }
        }

        return tags;
    }

    /**
     * Generar lista de actores
     */
    let generateParties = async function () {
        let parties = await many('parties', 'contractingprocess_id', this._cpid);
        let roles = await generateRoles();
        let members = await generateMembers();
        let additionalsContacts = await generateAdditionalContactPoints();

        return parties.map(p => clean({
            name: p.name,
            id: p.partyid,
            identifier: clean({
                scheme: p.identifier_scheme,
                id: p.identifier_id,
                legalName: p.identifier_legalname,
                legalPersonality: p.naturalperson ? 'naturalPerson' : 'legalPerson',
                givenName: p.givenname,
                patronymicName: p.surname,
                matronymicName: p.additionalsurname
            }),
            address: clean({
                streetAddress: p.address_streetaddress + ' ' + p.address_outdoornumber,
                locality: p.address_locality,
                region: p.address_region,
                postalCode: p.address_postalcode,
                countryName: p.address_countryname,
            }),
            contactPoint: clean({
                name: p.contactpoint_name,
                email: p.contactpoint_email,
                telephone: p.contactpoint_telephone,
                faxNumber: p.contactpoint_faxnumber,
                url: p.contactpoint_url,
                type: p.contactpoint_type,
                givenName: p.contactpoint_givenname,
                patronymicName: p.contactpoint_surname,
                matronymicName: p.contactpoint_additionalsurname,
                availableLanguage: p.contactpoint_language ? p.contactpoint_language.split(',') : undefined
            }),
            roles: roles[p.id] || [],
            memberOf: members[p.id] || [],
            additionalContactPoints: additionalsContacts[p.id] || [],
            position: p.position
        }));
    }

    /**
     * Genera la etapa de planeación
     */
    let generatePlanning = async function () {
        let planning = await one('planning', 'contractingprocess_id', this._cpid);
        let planningUnits = await generatePlanningUnits();
        if (!planning) return {};

        return clean({
            rationale: planning.rationale,
            hasQuotes: planning.hasquotes,
            requestingUnits: planningUnits.requestingUnits,
            contractingUnits: planningUnits.contractingUnits,
            responsibleUnits: planningUnits.responsibleUnits,
            budget: await generateBudget(),
            documents: await generateDocuments('planningdocuments'),
            requestsForQuotes: await generateRequestForQuotes()
        });
    }


    /**
     * Generar etapa de licitación
     */
    let generateTender = async function () {
        let tender = await one('tender', 'contractingprocess_id', this._cpid);

        if (!tender) return {};

        return clean({
            id: tender.tenderid,
            title: tender.title,
            description: tender.description,
            status: tender.status,
            procuringEntity: await generateOrganizationReference('procuringentity'),
            items: await generateItems('tenderitem'),
            value: clean({
                amount: parseFloat(tender.value_amount),
                currency: tender.value_currency
            }),
            minValue: clean({
                amount: parseFloat(tender.minvalue_amount),
                currency: tender.minvalue_currency
            }),
            procurementMethod: tender.procurementmethod,
            procurementMethodDetails: tender.procurementmethod_details,
            procurementMethodRationale: tender.procurementmethod_rationale,
            mainProcurementCategory: tender.mainprocurementcategory,
            additionalProcurementCategories: (() => {
                let croc;
                switch (tender.additionalprocurementcategories) {
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
            tenderPeriod: clean({
                startDate: tender.tenderperiod_startdate == null ? '' : moment(tender.tenderperiod_startdate).format(),
                endDate: tender.tenderperiod_enddate == null ? '' : moment(tender.tenderperiod_enddate).format()
            }),
            enquiryPeriod: clean({
                startDate: tender.enquiryperiod_startdate == null ? '' : moment(tender.enquiryperiod_startdate).format(),
                endDate: tender.enquiryperiod_enddate == null ? '' : moment(tender.enquiryperiod_enddate).format()
            }),
            hasEnquiries: tender.hasenquiries,
            eligibilityCriteria: tender.eligibilitycriteria,
            awardPeriod: clean({
                startDate: tender.awardperiod_startdate == null ? '' : moment(tender.awardperiod_startdate).format(),
                endDate: tender.awardperiod_enddate == null ? '' : moment(tender.awardperiod_enddate).format()
            }),
            numberOfTenderers: tender.numberoftenderers,
            tenderers: await generateOrganizationsReference('tenderer'),
            items: await generateItems('tenderitem'),
            documents: await generateDocuments('tenderdocuments'),
            milestones: await generateMilestones('tendermilestone'),
            amendments: await generateAmendments('tenderamendmentchanges'),
            clarificationMeetings: await generateClarificationMeetings()
        });
    }

    /**
     * Generar etapa de adjudicación
     */
    let generateAwards = async function () {
        let awards = await many('award', 'contractingprocess_id', this._cpid);

        if (awards[0].awardid !== '' && awards[0].awardid !== null){
            let items = await generateItems('awarditem', 'award_id'),
            documents = await generateDocuments('awarddocuments', 'award_id'),
            amendments = await generateAmendments('awardamendmentchanges', 'award_id'),
            suppliers = await _db.manyOrNone(`select p.*, a.award_id awardid 
                                              from parties p
                                              join awardsupplier a on a.parties_id = p.id
                                              where p.contractingprocess_id = $1 and 
                                              p.id in (select parties_id from roles where supplier = true)`, [this._cpid]);

            return awards.map(award => clean({
                id: award.awardid,
                title: award.title,
                description: award.description,
                status: award.status,
                date: award.award_date == null ? '' : moment(award.award_date).format(),
                value: clean({
                    netAmount: parseFloat(award.value_amountnet),
                    amount: parseFloat(award.value_amount),
                    currency: award.value_currency
                }),
                suppliers: suppliers.filter(s => s.awardid === award.id).map(s => clean({
                    name: s.name,
                    id: s.partyid,
                })),
                items: items[award.id] || [],
                contractPeriod: clean({
                    startDate: award.contractperiod_startdate == null ? '' : moment(award.contractperiod_startdate).format(),
                    endDate: award.contractperiod_enddate == null ? '' : moment(award.contractperiod_enddate).format()
                }),
                documents: documents[award.id] || [],
                amendments: amendments[award.id] || [],
                rationale: award.rationale
            }));
        } 

        
    }

    /**
     * Generar etapa de contrato
     */
    let generateContracts = async function () {
        let contracts = await many('contract', 'contractingprocess_id', this._cpid);

        if (contracts[0].contractid !== '' && contracts[0].contractid !== null){
            let items = await generateItems('contractitem', 'contract_id'),
            documents = await generateDocuments('contractdocuments', 'contract_id'),
            amendments = await generateAmendments('contractamendmentchanges', 'contract_id'),
            awards = await _db.manyOrNone('select id, awardid from award where contractingprocess_id = $1', [this._cpid]),
            guarantees = await generateGuarantees();

        let implementations = await many('implementation', 'contractingprocess_id', this._cpid),
            documentsImplementation = await generateDocuments('implementationdocuments', 'implementation_id'),
            transactionsImplementation = await generateTransactions(),
            milestoneImplementation = await generateMilestones('implementationmilestone', 'implementation_id');

        return contracts.map(contract => {
            let exchange = clean({
                currency: contract.exchangerate_currency,
                rate: parseFloat(contract.exchangerate_rate),
                date: contract.exchangerate_date == null ? '' : moment(contract.exchangerate_date).format(),
                source: contract.exchangerate_source
            });

            let award = awards.find(x => (x.id == contract.awardid) || (x.awardid == contract.awardid));
            
            return clean({
                id: contract.contractid,
                awardID: award? award.awardid : '',
                title: contract.title,
                description: contract.description,
                status: contract.status,
                period: clean({
                    startDate: contract.period_startdate == null ? '' : moment(contract.period_startdate).format(),
                    endDate: contract.period_enddate == null ? '' : moment(contract.period_enddate).format()
                }),
                value: clean({
                    netAmount: parseFloat(contract.value_amountnet),
                    amount: parseFloat(contract.value_amount),
                    currency: contract.value_currency,
                    exchangeRates: Object.keys(exchange).length > 0 ? [exchange] : []
                }),
                items: items[contract.id],
                dateSigned: contract.datesigned == null ? '' : moment(contract.datesigned).format(),
                documents: documents[contract.id],
                implementation: implementations.filter(i => i.contract_id === contract.id).map(i => {
                    return clean({
                        status: i.status,
                        transactions: transactionsImplementation[i.id],
                        milestones: milestoneImplementation[i.id],
                        documents: documentsImplementation[i.id]
                    })
                })[0],
                amendments: amendments[contract.id],
                surveillanceMechanisms: contract.surveillancemechanisms ? [contract.surveillancemechanisms] : undefined,
                guarantees: guarantees[contract.id]
            })
        });
        }
    }

    let generatePlanningUnits = async function() {
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
        return units != null ? units : {}
    }
    /**
     * Obtiene lista de role
     */
    let generateRoles = async function () {
        let roles = await many('roles', 'contractingprocess_id', this._cpid);
        let result = {}
        roles.map(rol => {
            result[rol.parties_id] = Object.keys(rol).filter(key => rol[key] === true).map(rol => {
                switch (rol) {
                    case 'procuringentity': rol = 'procuringEntity'; break;
                    case 'attendee': rol = 'attendee'; break;
                    case 'official': rol = 'official'; break;
                    case 'invitedsupplier': rol = 'invitedSupplier'; break;
                    case 'issuingsupplier': rol = 'issuingSupplier'; break;
                    case 'reviewbody': rol = 'reviewBody'; break;
                    case 'contractingunit': rol = 'contractingUnit'; break;
                    case 'requestingunit': rol = 'requestingUnit'; break;
                    case 'technicalunit': rol = 'technicalUnit'; break;
                    case 'responsibleunit': rol = 'responsibleUnit'; break;
                }
                return rol;
            });
        });
        return result;
    }

    /**
     * Generar lista de miembros
     */
    let generateMembers = async function () {
        let members = await _db.manyOrNone('select p.name, p.partyid, m.principal_parties_id principal from memberof m join parties p on p.id = m.parties_id where contractingprocess_id = $1', [this._cpid]);
        if (!members || members.length === 0) return [];
        let result = {};
        members.map(x => {
            if (!result[x.principal]) result[x.principal] = [];
            result[x.principal].push(clean({
                id: x.partyid,
                name: x.name
            }));
        });
        return result;
    }

    /**
     * Generar puntos de contacto adicionales
     */
    let generateAdditionalContactPoints = async function () {
        let contacts = await _db.manyOrNone('select * from additionalcontactpoints where party_id in (select id from parties where contractingprocess_id = $1)', [this._cpid]);
        if (!contacts || contacts.length === 0) return [];
        let result = {};
        contacts.map(x => {
            if (!result[x.party_id]) result[x.party_id] = [];
            result[x.party_id].push(clean({
                type: x.type,
                name: x.name,
                givenName: x.givenname,
                patronymicName: x.surname,
                matronymicName: x.additionalsurname,
                email: x.email,
                telephone: x.telephone,
                faxNumber: x.faxnumber,
                url: x.url,
                availableLanguage: x.language ? x.language.split(',') : undefined
            }));
        });
        return result;
    }

    /**
     * Obtiene lista de puntos de contacto adicionales
     */
    let generateAdditionalIdentifiers = async function () {
        let parties = await many('partiesadditionalidentifiers', 'contractingprocess_id', this._cpid);
        let result = {}
        parties.map(p => {
            result[p.parties_id] = clean({
                scheme: p.scheme,
                id: p.id,
                legalName: p.legalName
            });
        });
        return result;
    }

    /**
     * Genera referencia de organizacion
     * @param {String} role Rol del actor
     */
    let generateOrganizationReference = async function (role) {
        let actor = await _db.oneOrNone(`select * 
                                              from parties 
                                              where contractingprocess_id = $1 and
                                              id in (select parties_id from roles where ${role} = true)
                                              limit 1`, [this._cpid]);

        if (!actor) return {};

        return clean({
            name: actor.name,
            id: actor.partyid
        });
    }

    /**
     * Genera referencia de organizaciones
     * @param {String} role Rol del actor
     */
    let generateOrganizationsReference = async function (role) {
        let actores = await _db.manyOrNone(`select * 
                                              from parties 
                                              where contractingprocess_id = $1 and
                                              id in (select parties_id from roles where ${role} = true)`, [this._cpid]);

        if (!actores || actores.length === 0) return [];

        return actores.map(actor => clean({
            name: actor.name,
            id: actor.partyid
        }));
    }

    /**
     * Genera referencia de organizaciones
     * @param {Array} parties Id de los actores a cargar
     * @param {boolean} addPositon Agregar cargo 
     */
    let buildOrganizationsReference = async function (parties, addPosition) {
        if (!parties || parties.length === 0) return [];

        let actores = await _db.manyOrNone(`select * 
                                              from parties 
                                              where contractingprocess_id = $1 and id in ($2:csv)`, [this._cpid, parties]);

        if (!actores || actores.length === 0) return [];

        return actores.map(actor => clean({
            name: actor.name,
            id: actor.partyid
        }));
    }

    /**
     * Generar presupuesto
     */
    let generateBudget = async function () {
        let budget = await one('budget', 'contractingprocess_id', this._cpid);

        if (!budget) return {};

        let budgetbreakdown = await generateBudgetBreakdown();

        return clean({
            id: budget.budget_budgetid,
            description: budget.budget_description,

            amount: clean({
                amount: parseFloat(budget.budget_amount),
                currency: budget.budget_currency
            }),
            project: budget.budget_project,
            projectID: budget.budget_projectid,
            uri: budget.budget_uri,
            budgetBreakdown: budgetbreakdown || []
        });
    }

    let generateBudgetBreakdown = async function () {
        let budgets = await many('budgetbreakdown', 'contractingprocess_id', this._cpid);
        if (!budgets || budgets.length === 0) return [];
        let classifications = await generateBudgetClassifications();

        for (let i = 0, budget = budgets[i]; i < budgets.length; i++ , budget = budgets[i]) {
            budgets[i] = clean({
                period: clean({
                    startDate: budget.budgetbreakdownperiod_startdate == null ? '' : moment(budget.budgetbreakdownperiod_startdate).format(),
                    endDate: budget.budgetbreakdownperiod_enddate == null ? '' : moment(budget.budgetbreakdownperiod_enddate).format()
                }),
                id: budget.budgetbreakdown_id,
                description: budget.description,
                //name: budget.description || 'N/A',
                amount: clean({
                    amount: parseFloat(budget.amount),
                    currency: budget.currency
                }),
                origin: budget.origin, //
                fundType: budget.fund_type, //
                uri: budget.url,
                sourceParty: budget.source_id ? (await buildOrganizationsReference([budget.source_id]))[0] : undefined,
                budgetLines: classifications[budget.id] || []
            });
        }
        return budgets;
    }

    let generateBudgetClassifications = async function () {
        let classfitications = await _db.manyOrNone('select bc.*, bd.currency from budgetclassifications bc join budgetbreakdown bd on bd.id = bc.budgetbreakdown_id where bd.contractingprocess_id = $1', [this._cpid]);
        if (!classfitications || classfitications.length === 0) return [];

        let uniqueAdministrativeUnit = classfitications.map(x => x.requestingunit).filter(onlyUnique),
            uniqueMirs = classfitications.map(x => x.specificactivity).filter(onlyUnique),
            uniqueDepartures = classfitications.map(x => x.spendingobject).filter(onlyUnique);

        // obtener detalles
        let programaticStructure = await _db.manyOrNone('select * from programaticstructure where requestingunit in ($1:csv) and specificactivity in ($2:csv) and spendingobject in ($3:csv) order by year, trimester asc', [uniqueAdministrativeUnit, uniqueMirs, uniqueDepartures]);

        let addComponent = (name, origin, components) => {
            if (origin && origin[name.toLowerCase()]) {
                components.push({
                    name: name,
                    level: components.length + 1,
                    code: origin[name.toLowerCase()],
                    description: origin[`${name.toLowerCase()}_desc`]
                });
            }
        }

        let buildMeasures = (measure, currency) => {
            let ms = [];
            let trimesters = ['Primer Trimestre', 'Segundo Trimestre', 'Tercer Trimestre', 'Cuarto Trimestre'];
            if (!measure) return ms;
            if (measure.approvedamount && parseFloat(measure.approvedamount) > 0) ms.push({
                id: 'approved',
                value: {
                    amount: parseFloat(measure.approvedamount) || 0,
                    currency: currency
                },
                update: trimesters[measure.trimester - 1]
            });
            if (measure.modifiedamount && parseFloat(measure.modifiedamount) > 0) ms.push({
                id: 'modified',
                value: {
                    amount: parseFloat(measure.modifiedamount) || 0,
                    currency: currency
                },
                update: trimesters[measure.trimester - 1]
            });
            if (measure.executedamount && parseFloat(measure.executedamount) > 0) ms.push({
                id: 'executed',
                value: {
                    amount: parseFloat(measure.executedamount) || 0,
                    currency: currency
                },
                update: trimesters[measure.trimester - 1]
            });
            if (measure.committedamount && parseFloat(measure.committedamount) > 0) ms.push({
                id: 'committed',
                value: {
                    amount: parseFloat(measure.committedamount) || 0,
                    currency: currency
                },
                update: trimesters[measure.trimester - 1]
            });
            if (measure.reservedamount && parseFloat(measure.reservedamount) > 0) ms.push({
                id: 'reserved',
                value: {
                    amount: parseFloat(measure.reservedamount) || 0,
                    currency: currency
                },
                update: trimesters[measure.trimester - 1]
            });
            return ms;
        }

        let result = {};
        classfitications.map(x => {
            if (!result[x.budgetbreakdown_id]) result[x.budgetbreakdown_id] = [];
            let components = [];
            let ps = programaticStructure.find(m => m.year === x.year && m.requestingunit === x.requestingunit && m.specificactivity === x.specificactivity && m.spendingobject === x.spendingobject);
            addComponent('branch', ps, components);
            addComponent('responsibleUnit', ps, components);
            addComponent('finality', ps, components);
            addComponent('function', ps, components);
            addComponent('subFunction', ps, components);
            addComponent('institutionalActivity', ps, components);
            addComponent('budgetProgram', ps, components);
            addComponent('strategicObjective', ps, components);
            addComponent('requestingUnit', ps, components);
            addComponent('specificActivity', ps, components);
            addComponent('spendingObject', ps, components);
            addComponent('spendingType', ps, components);
            addComponent('budgetSource', ps, components);
            addComponent('region', ps, components);
            let ms = clean({
                components: components,
                measures: buildMeasures(ps, x.currency)
            });
            if (ms.components || ms.measures) result[x.budgetbreakdown_id].push(ms);
        });
        return result;
    }

    /**
     * Generar documentos
     * @param {String} table Nombre de la tabla
     * @param {String} groupby Nombre de la propiedad por la cual se van agrupar los resultados
     */
    let generateDocuments = async function (table, groupby) {
        let documents = await many(table, 'contractingprocess_id', this._cpid);

        let gendoc = document => clean({
            id: document.documentid,
            documentType: document.document_type,
            title: document.title,
            description: document.description,
            url: document.url,
            datePublished: document.date_published == null ? '' : moment(document.date_published).format(),
            dateModified: document.date_modified == null ? '' : moment(document.date_modified).format(),
            format: document.format,
            language: document.language
        });

        if (!documents || documents.length === 0) return [];

        if (groupby) {
            let group = {};
            documents.map(doc => {
                if (!group[doc[groupby]]) group[doc[groupby]] = [];
                group[doc[groupby]].push(gendoc(doc));
            });
            return group;
        } else {
            return documents.map(doc => gendoc(doc));
        }
    }
    
    let generateGuarantees = async () => {
        let guarantees = await many('guarantees', 'contractingprocess_id', this._cpid);

        let gen = async guarantee => clean({
            id: guarantee.guarantee_id,
            type: guarantee.type,
            date: guarantee.date == null ? '' : moment(guarantee.date).format(),
            obligations: guarantee.obligations,
            value: {
                amount: parseFloat(guarantee.value),
                currency: guarantee.currency
            },
            guarantor: guarantee.guarantor ? (await buildOrganizationsReference([guarantee.guarantor]))[0] : undefined,
            period: {
                startDate: guarantee.guaranteeperiod_startdate == null ? '' : moment(guarantee.guaranteeperiod_startdate).format(),
                endDate: guarantee.guaranteeperiod_enddate == null ? '' : moment(guarantee.guaranteeperiod_enddate).format()
            }
        });

        if (!guarantees || guarantees.length === 0) return [];

        let group = {};
        for (let i = 0; i < guarantees.length; i++) {
            if (!group[guarantees[i].contract_id]) group[guarantees[i].contract_id] = [];
            group[guarantees[i].contract_id].push(await gen(guarantees[i]));
        }

        return group;
    }

    /**
     * Generar hitos
     * @param {String} table Nombre de la tabla de hitos
     * @param {String} groupby Nombre del campo por el que se va agrupar el resultado
     */
    let generateMilestones = async function (table, groupby) {
        let milestones = await many(table, 'contractingprocess_id', this._cpid);

        let genmil = mil => clean({
            id: mil.milestoneid,
            title: mil.title,
            type: mil.type,
            description: mil.description,
            dueDate: mil.duedate == null ? '' : moment(mil.duedate).format(),
            dateModified: mil.date_modified == null ? '' : moment(mil.date_modified).format(),
            status: mil.status
        });

        if (!milestones || milestones.length === 0) return [];

        if (groupby) {
            let group = {};
            milestones.map(mil => {
                if (!group[mil[groupby]]) group[mil[groupby]] = [];
                group[mil[groupby]].push(genmil(mil));
            });
            return group;
        } else {
            return milestones.map(mil => genmil(mil));
        }
    }

    /**
     * Generar items
     * @param {String} table Nombre de la tabla de items
     * @param {String} groupby Nombre del campo por el que se va agrupar el resultado
     */
    let generateItems = async function (table, groupby) {
        let items = await many(table, 'contractingprocess_id', this._cpid);

        let genitem = item => clean({
            id: item.itemid,
            description: item.description,
            classification: clean({
                scheme: item.classification_scheme,
                id: item.classification_id,
                description: item.classification_description,
                //uri: item.classification_uri ??
            }),
            quantity: item.quantity,
            unit: clean({
                name: item.unit_name,
                value: clean({
                    amount: parseFloat(item.unit_value_amount),
                    netAmount: parseFloat(item.unit_value_amountnet),
                    currency: item.unit_value_currency
                })
            }),
            deliveryLocation: clean({
                geometry: {
                    type: 'Point',
                    coordinates: item.longitude && item.latitude ? [item.longitude, item.latitude] : undefined
                },
                gazetteer: clean({
                    scheme: item.gazetteer_scheme,
                    identifiers: item.gazetteer_identifiers ? [item.gazetteer_identifiers] : undefined
                }),
                description: item.location_description,
                url: item.location_url
            }),
            deliveryAddress: clean({
                streetAddress: item.location_streetaddress,
                locality: item.location_locality,
                region: item.location_region,
                postalCode: item.location_postalcode,
                countryName: item.location_countryname,
            })
        });

        if (!items || items.length === 0) return [];

        if (groupby) {
            let group = {};
            items.map(item => {
                if (!group[item[groupby]]) group[item[groupby]] = [];
                group[item[groupby]].push(genitem(item));
            });
            return group;
        } else {
            return items.map(item => genitem(item));
        }
    }

    /**
     * Generar modificaciones
     * @param {String} table Nombre de la tabla de modificaciones
     * @param {String} groupby Nombre del campo por el que se va agrupar el resultado
     */
    let generateAmendments = async function (table, groupby) {
        let amendments = await many(table, 'contractingprocess_id', this._cpid);

        let genamendment = amendment => clean({
            date: amendment.amendments_date == null ? '' : moment(amendment.amendments_date).format(),
            rationale: amendment.amendments_rationale,
            id: amendment.amendments_id,
            description: amendment.amendments_description,
        });

        if (!amendments || amendments.length === 0) return [];

        if (groupby) {
            let group = {};
            amendments.map(amendment => {
                if (!group[amendment[groupby]]) group[amendment[groupby]] = [];
                group[amendment[groupby]].push(genamendment(amendment));
            });
            return group;
        } else {
            return amendments.map(amendment => genamendment(amendment));
        }
    }

    /**
     * Generar transacciones de implementacion
     */
    let generateTransactions = async function () {
        let transactions = await many('implementationtransactions', 'contractingprocess_id', this._cpid);

        if (!transactions) return {};

        let payers = await generateOrganizationsReference('payer'),
            payee = await generateOrganizationsReference('payee');

        let result = {};

        transactions.map(t => {
            if (!result[t.implementation_id]) result[t.implementation_id] = [];
            result[t.implementation_id].push(clean({
                id: t.transactionid,
                source: t.source,
                date: t.implementation_date == null ? '' : moment(t.implementation_date).format(),
                value: clean({
                    netAmount: parseFloat(t.value_amountnet),
                    amount: parseFloat(t.value_amount),
                    currency: t.value_currency
                }),
                payer: payers.find(x => x.id === t.payer_id),
                payee: payee.find(x => x.id === t.payee_id),
                paymentMethod: t.payment_method
            }))
        });

        return result;
    }

    /**
     * Generar solicitudes de cotización
     */
    let generateRequestForQuotes = async function () {
        let requests = await many('requestforquotes', 'contractingprocess_id', this._cpid);

        if (!requests || requests.length === 0) return [];

        let requestSuppliers = requests.map(x => x.id).length > 0 ? await _db.manyOrNone('select requestforquotes_id, parties_id from requestforquotesinvitedsuppliers where requestforquotes_id in ($1:csv)', [requests.map(x => x.id)]) : [];

        let items = await generateRequestItems(),
            quotes = await generateQuotes(),
            suppliers = {};

        for (let i = 0, x = requestSuppliers[i]; i < requestSuppliers.length; i++ , x = requestSuppliers[i]) {
            if (!suppliers[x.requestforquotes_id]) suppliers[x.requestforquotes_id] = [];
            let org = await buildOrganizationsReference([x.parties_id]);
            if (org) suppliers[x.requestforquotes_id].push(org[0]);
        };

        return requests.map(request => clean({
            id: request.requestforquotes_id,
            title: request.title,
            description: request.description,
            period: clean({
                startDate: request.period_startdate == null ? '' : moment(request.period_startdate).format(),
                endDate: request.period_enddate == null ? '' : moment(request.period_enddate).format()
            }),
            items: items[request.id],
            invitedSuppliers: suppliers[request.id],
            quotes: quotes[request.id],
        }));
    }

    /**
     * Generar cotizaciones
     */
    let generateQuotes = async function () {
        let quotes = await _db.manyOrNone('select * from quotes where requestforquotes_id in (select id from requestforquotes where contractingprocess_id = $1)', [this._cpid]);
        if (!quotes || quotes.length === 0) return [];
        let result = {},
            items = await generateQuotesItems(),
            suppliers = {};

            try{
                for (let i = 0, x = quotes[i]; i < quotes.length; i++ , x = quotes[i]) {
                    if (!suppliers[x.id]) suppliers[x.id] = [];
                    let org = await buildOrganizationsReference([x.issuingsupplier_id]);
                    if (org && suppliers[x.id]) suppliers[x.id].push(org[0]);
                };
            }
            catch(e) {
                console.log('Error obtener issuingSupplier');
            }
       

        quotes.map(quote => {
            if (!result[quote.requestforquotes_id]) result[quote.requestforquotes_id] = [];
            result[quote.requestforquotes_id].push(clean({
                id: quote.quotes_id,
                description: quote.description,
                date: quote.date == null ? '' : moment(quote.date).format(),
                items: items[quote.id] || [],
                value: clean({
                    amount: parseFloat(quote.value)
                }),
                period: clean({
                    startDate: quote.quoteperiod_startdate == null ? '' : moment(quote.quoteperiod_startdate).format(),
                    endDate: quote.quoteperiod_enddate == null ? '' : moment(quote.quoteperiod_enddate).format()
                }),
                issuingSupplier: suppliers[quote.id] ? suppliers[quote.id][0] : undefined
            }));
        });
        return result;
    }


    /**
     * Generar items de solicitud de cotizacion
     */
    let generateRequestItems = async function () {
        let items = await _db.manyOrNone('select * from requestforquotesitems where requestforquotes_id in (select id from requestforquotes where contractingprocess_id = $1)', [this._cpid]);
        if (!items || items.length === 0) return [];

        let classfitications = await _db.manyOrNone('select *  from item where classificationid in ($1:csv)', items.map(x => x.itemid));

        let result = {};



        items.map(x => {
            let item = classfitications.find(c => c.classificationid === x.itemid);
            if(!result[x.requestforquotes_id]){
                result[x.requestforquotes_id] = [];
            }
            result[x.requestforquotes_id].push(clean({
                id: x.itemid,
                description: x.item,
                quantity: parseFloat(x.quantity),
                classification: item ? clean( {
                    id: item.classificationid,
                    description: item.description
                }) : undefined,
                unit: clean({ name: item ? item.unit : undefined}),
                name: item ? item.name : undefined
            }));
        });

        return result;
    }


	/**
	* Generar items de cotizaciones
	*/
	let generateQuotesItems = async function () {
		let items = await _db.manyOrNone('select * from quotesitems where quotes_id  in (select id from quotes where requestforquotes_id  in (select id from requestforquotes where contractingprocess_id = $1))', [this._cpid]);
		if (!items || items.length === 0) return [];
		let result = {};
		let classfitications = await _db.manyOrNone('select classificationid, unit, description from item where classificationid in ($1:csv)', items.map(x => x.itemid));

		items.map(x => {
			if (!result[x.quotes_id]) result[x.quotes_id] = [];
			let item = classfitications.find(c => c.classificationid === x.itemid || c.classificationid === x.item)
			result[x.quotes_id].push(clean({
				id: x.itemid,
				description: x.item,
				classification: item ? clean({
					id: item.classificationid,
					description: item.description
				}) : undefined,
				unit: clean({
					name: item ? item.unit : undefined,
					value: {
						amount: parseFloat(x.quantity)
					}
				}),
				name: item ? item.name : undefined
			}));
		});
		return result;
	}
	
	
	
    /**
     * Generar juntas de aclaraciones
     */
    let generateClarificationMeetings = async function () {
        let positions = await many('clarificationmeeting', 'contractingprocess_id', this._cpid);

        if (!positions || positions.length === 0) return [];

        let actores = positions.map(x => x.id).length > 0 ? await _db.manyOrNone('select * from clarificationmeetingactor where clarificationmeeting_id in ($1:csv)', [positions.map(x => x.id)]) : [],
            attenders = actores.filter(x => x.attender === true),
            officials = actores.filter(x => x.official === true);

        attenders = await buildOrganizationsReference(attenders.map(x => x.parties_id), true);
        officials = await buildOrganizationsReference(officials.map(x => x.parties_id), true);

        return positions.map(pos => clean({
            id: pos.clarificationmeetingid,
            date: pos.date == null ? '' : moment(pos.date).format(),
            attendees: attenders,
            officials: officials
        }));
    }


    /**
     * Generar procedimientos relacionados
     */
    let generateRelatedProcesses = async function () {
        let rp = await many('relatedprocedure', 'contractingprocess_id', this._cpid);

        if (!rp || rp.length === 0) return [];

        return rp.map(r => {
            return clean({
                id: r.relatedprocedure_id,
                relationship: [r.relationship_type],
                title: r.title,
                scheme: r.identifier_scheme,
                identifier: r.relatedprocedure_identifier,
                uri: r.url
            });
        });
    }

    /**
     * Ejecutar una consulta para obtener un solo resultado
     * @param {String} table Nombre de la tabla
     * @param {String} field Nombre del campo por el que se va a filtrar
     * @param {String} value Valor por el que se va a filtrar
     */
    let one = async function (table, field, value) {
        return await _db.oneOrNone('select * from $1~ where $2~ = $3 limit 1', [table, field, value]);
    };

    /**
     * Ejecutar una consulta para obtener varios resultados
     * @param {String} table Nombre de la tabla
     * @param {String} field Nombre del campo por que el se va a filtrar
     * @param {String} value Valor por el que se va a filtrar
     */
    let many = async function (table, field, value) {
        return await _db.manyOrNone('select * from $1~ where $2~ = $3 order by id', [table, field, value]);

    };

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
                        if (prevObj[key] != null && (ignore == null || ignore.indexOf(key) === -1)) {
                            // Si el valor 2 tiene la misma propiedad se llama recursivamente a la funcion para comparar
                            change[key] = compare(obj[key], prevObj[key]);
                        } else {
                            change[key] = obj[key];
                        }
                    });
                } else if (obj.constructor === Array) { // Verifica si el objeto es un arreglo
                    change = [];

                    obj.forEach((value, index) => {
                        if (value != null) {
                            // Verifica si el valor del arreglo es un objeto
                            if (value.constructor === Object) {
                                // Busca una propiedad base del objeto para la busqueda
                                let prop = value.hasOwnProperty('id') ? 'id' : value.hasOwnProperty('name') ? 'name' : Object.keys(value).find((prop) => value[prop].constructor === String);

                                // Busca si el arreglo 2 tiene un objeto parecido al valor
                                let prevValue = prevObj.find((x) => x[prop] === value[prop]);

                                if (prevValue != null) {
                                    // Si encontro un objeto similar al valor se llama recursivamente a la funcion para comparar
                                    change.push(compare(value, prevValue));
                                } else {
                                    change.push(value);
                                }
                            } else {
                                // Busca si el arreglo 2 tiene el valor actual
                                if (prevObj.indexOf(value) === -1) {
                                    change.push(value);
                                }
                            }
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

        return change;
    }

    let clear = function(data) {
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

        return data;
    }

    return this;
}

let onlyUnique = (value, index, self) => {
    return self.indexOf(value) === index;
}


module.exports = release;