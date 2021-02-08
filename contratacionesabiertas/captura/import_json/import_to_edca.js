/**
 * imports JSON (release package) data into EDCA PostgreSQL database
 */

var db_conf = require('../db_conf');
var fs = require('fs');
let file_path = process.argv[2];

function getValue( obj ){
    if ( typeof obj !== 'undefined'){
        return obj
    }

    return null;
}

function parseNumber(x) {
    return isNaN(x)?null:Number(x);
}

function parseDate(d) {
    return isNaN(Date.parse(d))?null:d;
}

function parseBoolean(b){
    switch (b) {
        case true:
            return 1;
        case false:
            return 0;
        case 'True':
            return 1;
        case 'true':
            return 1;
        case 'False':
            return 0;
        case 'false':
            return 0;
        default:
            return null
    }
}

if ( typeof file_path === 'undefined'){
    console.log("Usage: node import_to_edca.js <json_path>");
    process.exit(0);
}


if ( fs.existsSync(file_path) ){

    let contracting_process = require(file_path);
    let release = contracting_process.releases[0];

    //parties
    if (typeof release.parties === 'undefined'){
        release.parties = [];
    }

    //planning
    if ( typeof release.planning === 'undefined'){
        release.planning = {};
        release.planning.budget = {};
    }

    if (typeof release.planning.budget === 'undefined'){
        release.planning.budget = {};
    }

    if (typeof release.planning.budget.amount === 'undefined'){
        release.planning.budget.amount = {};
    }

    //planning -> documents
    if ( typeof release.planning.documents === 'undefined'){ release.planning.documents = []}

    //planning -> milestones
    if ( typeof release.planning.milestones === 'undefined'){ release.planning.milestones = []}

    //tender
    if ( typeof release.tender === 'undefined'){
        release.tender = {};
    }
    //tender -> value, minValue, tenderPeriod, awardPeriod
    if ( typeof release.tender.value === 'undefined'){ release.tender.value ={ }}
    if ( typeof release.tender.minValue === 'undefined'){ release.tender.minValue ={ }}
    if ( typeof release.tender.tenderPeriod === 'undefined'){ release.tender.tenderPeriod ={ }}
    if ( typeof release.tender.awardPeriod === 'undefined'){ release.tender.awardPeriod ={ }}
    if ( typeof release.tender.enquiryPeriod === 'undefined'){ release.tender.enquiryPeriod = { }}

    //tender -> documents items tenderers
    if ( typeof release.tender.documents === 'undefined'){ release.tender.documents = []}
    if ( typeof release.tender.items === 'undefined'){ release.tender.items =[]}
    if ( typeof release.tender.tenderers === 'undefined'){ release.tender.tenderers =[]}
    if ( typeof release.tender.milestones === 'undefined'){ release.tender.milestones =[]}


    let procuringEntity = {};
    //procuringEntity
    if ( typeof release.procuringEntity !== 'undefined'){
        procuringEntity = findPartiesById( release.tender.procuringEntity.id ,release.parties );
    }

    //procuringEntity -> address identifier contactPoint
    if (typeof procuringEntity.address === 'undefined'){ procuringEntity.address = {}}
    if (typeof procuringEntity.identifier === 'undefined'){ procuringEntity.identifier = {}}
    if (typeof procuringEntity.contactPoint === 'undefined'){ procuringEntity.contactPoint = {}}

    //publisher
    if (typeof contracting_process.publisher === 'undefined'){
        contracting_process.publisher = {};
    }

    //awards
    let award = {};
    if ( typeof release.awards !== 'undefined'){
        award = release.awards[0];
    }

    //awards -> contractperiod value amendment
    if (typeof award.contractPeriod === 'undefined'){ award.contractPeriod = {}}
    if (typeof award.value === 'undefined'){ award.value = {}}

    //awards -> items documents suppliers
    if ( typeof award.items === 'undefined'){ award.items =[]}
    if ( typeof award.documents === 'undefined'){ award.documents =[]}
    if ( typeof award.suppliers === 'undefined'){ award.suppliers =[]}

    //contracts
    let contract = {};
    if ( typeof release.contracts !== 'undefined'){
        contract = release.contracts[0];
    }

    //contracts -> period, value, amendment
    if (typeof contract.period === 'undefined'){ contract.period = {}}
    if (typeof contract.value === 'undefined'){ contract.value = {}}

    //contracts -> items documents
    if ( typeof contract.items === 'undefined'){ contract.items = []}
    if ( typeof contract.documents === 'undefined'){ contract.documents =[]}

    //contracts -> implementation -> documents, transactions, milestones
    if( typeof contract.implementation === 'undefined'){ contract.implementation = {}}
    if( typeof contract.implementation.documents === 'undefined'){ contract.implementation.documents = []}
    if( typeof contract.implementation.transactions === 'undefined'){ contract.implementation.transactions = []}
    if( typeof contract.implementation.milestones === 'undefined'){ contract.implementation.milestones = []}

    db_conf.edca_db.tx(function (t) {
        return t.one("insert into ContractingProcess (fecha_creacion, hora_creacion, ocid, stage ) values (current_date, current_time, $1, null) returning id", [
            //release.ocid,
            release.id
        ]).then(function (process) {

            return t.batch([
                process = { id : process.id },
                t.one("insert into Planning (ContractingProcess_id, rationale) values ($1, $2) returning id as planning_id", [
                    process.id,
                    getValue(release.planning.rationale)
                ]),
                t.one("insert into Tender (ContractingProcess_id," +
                    "tenderid,"+
                    "title,"+
                    "description,"+
                    "status,"+
                    "minvalue_amount,"+
                    "minvalue_currency,"+
                    "value_amount,"+
                    "value_currency,"+
                    "procurementmethod,"+
                    "procurementmethod_rationale,"+
                    "procurementmethod_details,"+
                    "mainprocurementcategory,"+
					"additionalprocurementcategories,"+
                    "awardcriteria,"+
                    "awardcriteria_details,"+
                    "submissionmethod,"+
                    "submissionmethod_details,"+
                    "tenderperiod_startdate,"+
                    "tenderperiod_enddate,"+
                    "enquiryperiod_startdate,"+
                    "enquiryperiod_enddate,"+
                    "hasenquiries,"+
                    "eligibilitycriteria,"+
                    "awardperiod_startdate,"+
                    "awardperiod_enddate,"+
                    "numberoftenderers,"+
                    "amendment_date,"+
                    "amendment_rationale"+
                    ") values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29) returning id as tender_id", [
                    process.id,
                    getValue(release.tender.id),
                    getValue(release.tender.title),
                    getValue(release.tender.description),
                    getValue(release.tender.status),
                    parseNumber(getValue(release.tender.minValue.amount)), //parse Number
                    getValue(release.tender.minValue.currency),
                    parseNumber(getValue(release.tender.value.amount)), //parse Number
                    getValue(release.tender.value.currency),
                    getValue(release.tender.procurementMethod),
                    getValue(release.tender.procurementMethodRationale),
                    getValue(release.tender.procurementMethodDetails),
                    getValue(release.tender.mainProcurementCategory),
                    getValue(release.tender.additionalProcurementCategories),
                    getValue(release.tender.awardCriteria),
                    getValue(release.tender.awardCriteriaDetails),
                    getValue(release.tender.submissionMethod),
                    getValue(release.tender.submissionMethodDetails),
                    parseDate(getValue(release.tender.tenderPeriod.startDate)), //parse Date
                    parseDate(getValue(release.tender.tenderPeriod.endDate)), //parse Date
                    parseDate(getValue(release.tender.enquiryPeriod.startDate)), //parse Date
                    parseDate(getValue(release.tender.enquiryPeriod.endDate)), //parse Date
                    getValue(release.tender.hasEnquiries), //parse Number (boolean)
                    getValue(release.tender.eligibilityCriteria),
                    parseDate(getValue(release.tender.awardPeriod.startDate)), //parse Date
                    parseDate(getValue(release.tender.awardPeriod.endDate)),  //parse Date
                    parseNumber(getValue(release.tender.numberOfTenderers)), //parse Number
                    null, //release.tender.amendment.date, //parse Date
                    null //release.tender.amendment.rationale
                ]),
                t.one("insert into Award (ContractingProcess_id," +
                    "awardid," +
                    "title," +
                    "description," +
                    "status," +
                    "award_date," +
                    "value_amount," +
                    "value_currency," +
                    "contractperiod_startdate," +
                    "contractperiod_enddate," +
                    "amendment_date," +
                    "amendment_rationale) " +
                    "values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id as award_id", [
                    process.id,
                    getValue(award.id),
                    getValue(award.title),
                    getValue(award.description),
                    getValue(award.status),
                    parseDate(getValue(award.date)),//date
                    parseNumber(getValue(award.value.amount)),// numeric
                    getValue(award.value.currency),
                    parseDate(getValue(award.contractPeriod.startdate)), //date
                    parseDate(getValue(award.contractPeriod.enddate)),   //date
                    null,//award.amendments[0].date, // date
                    null//award.amendments[0].rationale
                ]),
                t.one("insert into Contract (ContractingProcess_id," +
                    "awardid,"+
                    "contractid,"+
                    "title,"+
                    "description,"+
                    "status,"+
                    "period_startdate,"+
                    "period_enddate,"+
                    "value_amount,"+
                    "value_currency,"+
                    "datesigned,"+
                    "amendment_date,"+
                    "amendment_rationale) "+
                    " values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) returning id as contract_id", [
                    process.id,
                    getValue(contract.awardID),
                    getValue(contract.id),
                    getValue(contract.title),
                    getValue(contract.description),
                    getValue(contract.status),
                    parseDate(getValue(contract.period.startDate)), // timestamp without time zone
                    parseDate(getValue(contract.period.endDate)), // timestamp without time zone
                    parseNumber(getValue(contract.value.amount)), // numeric
                    getValue(contract.value.currency),
                    parseDate(getValue(contract.dateSigned)), // timestamp without time zone
                    null,//contract.amendments[0].date, // timestamp without time zone
                    null//contract.amendments[0].rationale
                ]),
                t.one("insert into Publisher (ContractingProcess_id, name, scheme, uid, uri) values ($1,$2,$3,$4,$5) returning id as publisher_id", [
                    process.id,
                    getValue(contracting_process.publisher.name),
                    getValue(contracting_process.publisher.scheme),
                    getValue(contracting_process.publisher.uid),
                    getValue(contracting_process.publisher.uri)
                ]),
                t.one("insert into links(contractingprocess_id,xlsx,json,pdf) values ($1,$2,$3,$4) returning id as links_id",[process.id,null,null,null])
            ]);

        }).then(function (info) {
            return t.batch([
                //process, planning, tender, award, contract, publisher
                { contractingprocess : { id: info[0].id }},
                { planning : { id: info[1].planning_id }},
                { tender : { id: info[2].tender_id }},
                { award: { id:info[3].award_id }},
                { contract: { id:info[4].contract_id }},
                { publisher: { id: info[5].publisher_id }},
                t.one("insert into Budget (ContractingProcess_id, Planning_id, " +
                    "budget_source,"+
                    "budget_budgetid,"+
                    "budget_description,"+
                    "budget_amount,"+
                    "budget_currency,"+
                    "budget_project,"+
                    "budget_projectid,"+
                    "budget_uri) "+
                    "values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) returning id as budget_id", [
                    info[0].id,
                    info[1].planning_id,
                    getValue(release.planning.budget.source),         // text
                    getValue(release.planning.budget.id),             // text
                    getValue(release.planning.budget.description),    // text
                    parseNumber(getValue(release.planning.budget.amount.amount)),         // Parse Number
                    getValue(release.planning.budget.amount.currency),       // text
                    getValue(release.planning.budget.project),        // text
                    getValue(release.planning.budget.projectID),      // text
                    getValue(release.planning.budget.uri)             // text
                ]),
                t.one("insert into Implementation (ContractingProcess_id, Contract_id ) values ($1, $2) returning id as implementation_id", [
                    info[0].id, info[4].contract_id
                ])
            ]);
        });

    }).then(function (data) {
        console.log(data);

        return db_conf.edca_db.tx(function (t) {
            //parties
            let queries = [];

            for (let party of release.parties){
                if (typeof party.identifier ==='undefined'){party.identifier={}}
                if (typeof party.address==='undefined'){party.address={}}
                if (typeof party.contactPoint==='undefined'){party.contactPoint={}}

                let roles = {
                    buyer: false,
                    procuringEntity: false ,
                    supplier: false ,
                    tenderer: false ,
                    guarantor: false ,
                    enquirer: false,
                    payer: false ,
                    payee: false ,
                    reviewBody: false ,
                    attendee: false,
                    official: false,
                    invitedSupplier: false ,
                    issuingSupplier: false,
                    contractingunit: false,
                    requestingunit: false,
                    technicalunit: false,
                    responsibleunit: false
                };

                if (!Array.isArray(party.roles)){
                    party.roles = []
                }

                for (let r of party.roles){

                    if (r === null){
                        r = "";
                    }

                    switch (r.toLowerCase()){
                        case "buyer":
                            roles.buyer = true;
                            break;
                        case "procuringentity":
                            roles.procuringEntity = true;
                            break;
                        case "supplier":
                            roles.supplier = true;
                            break;
                        case "tenderer":
                            roles.tenderer = true;
                            break;
                        case "guarantor":
                            roles.guarantor = true;
                            break;
                        case "enquirer":
                            roles.enquirer = true;
                            break;
                        case "payer":
                            roles.payer = true;
                            break;
                        case "payee":
                            roles.payee = true;
                            break;
                        case "reviewbody":
                            roles.reviewBody = true;
                            break;
                        case "attendee":
                            roles.attendee = true;
                            break;
                        case "official":
                            roles.official = true;
                            break;
                        case "invitedsupplier":
                            roles.invitedSupplier = true;
                            break;
                        case "issuingsupplier":
                            roles.issuingSupplier = true;
                            break;
                        case "contractingunit":
                            roles.contractingunit = true;
                            break;
                        case "requestingunit":
                            roles.requestingunit = true;
                            break;
                        case "technicalunit":
                            roles.technicalunit = true;
                            break;
                        case "responsibleunit":
                            roles.responsibleunit = true;
                            break;
                    }


                }


                queries.push(t.one('insert into parties(contractingprocess_id,partyid,' +
                    "identifier_scheme,"+
                    "identifier_id,"+
                    "identifier_legalname,"+
                    "identifier_uri,"+
                    "name,"+
                    "address_streetaddress,"+
                    "address_locality,"+
                    "address_region,"+
                    "address_postalcode,"+
                    "address_countryname,"+
                    "contactpoint_name,"+
                    "contactpoint_email,"+
                    "contactpoint_telephone,"+
                    "contactpoint_faxnumber,"+
                    "contactpoint_url) "+
                    " values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,17) returning id as party_id",[
                    data[0].contractingprocess.id,
                    getValue(party.id),
                    getValue(party.identifier.scheme),
                    getValue(party.identifier.id),
                    getValue(party.identifier.legalName),
                    getValue(party.identifier.uri),
                    getValue(party.name),
                    getValue(party.address.streetAddress),
                    getValue(party.address.locality),
                    getValue(party.address.region),
                    getValue(party.address.postalCode),
                    getValue(party.address.countryName),
                    getValue(party.contactPoint.name),
                    getValue(party.contactPoint.email),
                    getValue(party.contactPoint.telephone),
                    getValue(party.contactPoint.faxNumber),
                    getValue(party.contactPoint.url)
                ]).then(function (inserted_row) {
                    return t.one("insert into roles (contractingprocess_id, parties_id, buyer, procuringEntity,supplier,tenderer,guarantor,enquirer," +
                        "payer,payee,reviewBody, attendee, official, " +
                        "invitedSupplier, issuingSupplier, requestingunit, " +
						"contractingunit, technicalunit, responsibleunit) values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19) returning id as rol_id", [
                        data[0].contractingprocess.id,
                        inserted_row.party_id,
                        roles.buyer,
                        roles.procuringEntity,
                        roles.supplier,
                        roles.tenderer,
                        roles.guarantor,
                        roles.enquirer,
                        roles.payer,
                        roles.payee,
                        roles.reviewBody,
                        roles.attendee,
                        roles.official,
                        roles.invitedSupplier,
                        roles.issuingSupplier,
						roles.requestingunit,
						roles.contractingunit, 
                        roles.technicalunit,
                        roles.responsibleunit
                    ])
                }));
            }


            // planning -> documents
            for (let document of release.planning.documents) {
                queries.push(t.one('insert into planningdocuments(contractingprocess_id, planning_id,' +
                    "documentid,"+
                    "document_type,"+
                    "title,"+
                    "description,"+
                    "url,"+
                    "date_published,"+
                    "date_modified,"+
                    "format,"+
                    "language) "+
                    'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id as document_id', [
                    data[0].contractingprocess.id,
                    data[1].planning.id,
                    getValue(document.id),
                    getValue(document.type),
                    getValue(document.title),
                    getValue(document.description),
                    getValue(document.url),
                    parseDate(getValue(document.datePublished)),
                    parseDate(getValue(document.dateModified)),
                    getValue(document.format),
                    getValue(document.language)
                ]))
            }

            //planning -> milestones

            // tender -> items
            for (let item of release.tender.items ){

                if (typeof item.classification === 'undefined'){ item.classification = {}}
                if (typeof item.unit === 'undefined'){ item.unit={}}
                if (typeof item.unit.value === 'undefined'){item.unit.value={}}

                queries.push(t.one('insert into tenderitem(contractingprocess_id, tender_id,' +
                    "itemid,"+
                    "description," +
                    "classification_scheme," +
                    "classification_id," +
                    "classification_description," +
                    "classification_uri," +
                    "quantity," +
                    "unit_name," +
                    "unit_value_amount,"+    // numeric
                    "unit_value_currency) "+
                    ' values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id as item_id',[
                    data[0].contractingprocess.id,
                    data[2].tender.id,
                    getValue(item.id),
                    getValue(item.description),
                    getValue(item.classification.scheme),
                    getValue(item.classification.id),
                    getValue(item.classification.description),
                    getValue(item.classification.uri),
                    parseNumber(getValue(item.quantity)),   // integer
                    getValue(item.unit.name),
                    parseNumber(getValue(item.unit.value.amount)),// numeric
                    getValue(item.unit.value.currency)
                ]));
            }

            // tender -> documents
            for (let document of release.tender.documents) {
                queries.push(t.one('insert into tenderdocuments(contractingprocess_id, tender_id,' +
                    "documentid,"+
                    "document_type,"+
                    "title,"+
                    "description,"+
                    "url,"+
                    "date_published,"+
                    "date_modified,"+
                    "format,"+
                    "language) "+
                    'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id as document_id', [
                    data[0].contractingprocess.id,
                    data[2].tender.id,
                    getValue(document.id),
                    getValue(document.type),
                    getValue(document.title),
                    getValue(document.description),
                    getValue(document.url),
                    parseDate(getValue(document.datePublished)),
                    parseDate(getValue(document.dateModified)),
                    getValue(document.format),
                    getValue(document.language)
                ]));
            }

            //tender -> milestones
            for (let milestone of release.tender.milestones){
                queries.push(t.one('insert into tendermilestone( contractingprocess_id,' +
                    'contract_id,' +
                    'milestoneid,' +
                    'title,' +
                    'description,' +
                    'duedate,' +
                    'date_modified,' +
                    'status) values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id as milestone_id',[
                    data[0].contractingprocess.id,
                    data[4].contract.id,
                    getValue(milestone.id),
                    getValue(milestone.title),
                    getValue(milestone.description),
                    parseDate(getValue(milestone.dueDate)), // timestamp without time zone
                    parseDate(getValue(milestone.dateModified)), //  timestamp without time zone
                    getValue(milestone.status)
                ]));
            }

            // awards -> items
            for (let item of award.items ){

                if (typeof item.classification === 'undefined'){ item.classification = {}}
                if (typeof item.unit === 'undefined'){ item.unit={}}
                if (typeof item.unit.value === 'undefined'){item.unit.value={}}

                queries.push(t.one('insert into awarditem(contractingprocess_id, award_id,' +
                    "itemid,"+
                    "description," +
                    "classification_scheme," +
                    "classification_id," +
                    "classification_description," +
                    "classification_uri," +
                    "quantity," +
                    "unit_name," +
                    "unit_value_amount,"+    // numeric
                    "unit_value_currency) "+
                    ' values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id as item_id',[
                    data[0].contractingprocess.id,
                    data[2].tender.id,
                    getValue(item.id),
                    getValue(item.description),
                    getValue(item.classification.scheme),
                    getValue(item.classification.id),
                    getValue(item.classification.description),
                    getValue(item.classification.uri),
                    parseNumber(getValue(item.quantity)),   // integer
                    getValue(item.unit.name),
                    parseNumber(getValue(item.unit.value.amount)),// numeric
                    getValue(item.unit.value.currency)
                ]));
            }

            // awards -> documents
            for (let document of award.documents){
                queries.push(t.one('insert into awarddocuments(' +
                    'contractingprocess_id, ' +
                    'award_id,' +
                    'documentid,'+
                    'document_type,'+
                    'title,'+
                    'description,'+
                    'url,'+
                    'date_published,'+
                    'date_modified,'+
                    'format,'+
                    'language) '+
                    'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id as document_id', [
                    data[0].contractingprocess.id,
                    data[3].award.id,
                    getValue(document.id),
                    getValue(document.type),
                    getValue(document.title),
                    getValue(document.description),
                    getValue(document.url),
                    parseDate(getValue(document.datePublished)),
                    parseDate(getValue(document.dateModified)),
                    getValue(document.format),
                    getValue(document.language)
                ]))
            }

            // contract -> items
            for (let item of contract.items ){

                if (typeof item.classification === 'undefined'){ item.classification = {}}
                if (typeof item.unit === 'undefined'){ item.unit={}}
                if (typeof item.unit.value === 'undefined'){item.unit.value={}}

                queries.push(t.one('insert into contractitem(contractingprocess_id, contract_id,' +
                    "itemid,"+
                    "description," +
                    "classification_scheme," +
                    "classification_id," +
                    "classification_description," +
                    "classification_uri," +
                    "quantity," +
                    "unit_name," +
                    "unit_value_amount,"+    // numeric
                    "unit_value_currency) "+
                    ' values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id as item_id',[
                    data[0].contractingprocess.id,
                    data[2].tender.id,
                    getValue(item.id),
                    getValue(item.description),
                    getValue(item.classification.scheme),
                    getValue(item.classification.id),
                    getValue(item.classification.description),
                    getValue(item.classification.uri),
                    parseNumber(getValue(item.quantity)),   // integer
                    getValue(item.unit.name),
                    parseNumber(getValue(item.unit.value.amount)),// numeric
                    getValue(item.unit.value.currency)
                ]));
            }

            // contract -> documents
            for (let document of contract.documents){
                queries.push(t.one('insert into contractdocuments(contractingprocess_id, ' +
                    'contract_id,' +
                    "documentid,"+
                    "document_type,"+
                    "title,"+
                    "description,"+
                    "url,"+
                    "date_published,"+
                    "date_modified,"+
                    "format,"+
                    "language) "+
                    'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id as document_id', [
                    data[0].contractingprocess.id,
                    data[4].contract.id,
                    getValue(document.id),
                    getValue(document.type),
                    getValue(document.title),
                    getValue(document.description),
                    getValue(document.url),
                    parseDate(getValue(document.datePublished)),
                    parseDate(getValue(document.dateModified)),
                    getValue(document.format),
                    getValue(document.language)
                ]));
            }

            //contract -> implementation documents
            for (let document of contract.implementation.documents){
                queries.push(t.one('insert into implementationdocuments(contractingprocess_id, ' +
                    'contract_id,' +
                    'implementation_id,'+
                    "documentid,"+
                    "document_type,"+
                    "title,"+
                    "description,"+
                    "url,"+
                    "date_published,"+
                    "date_modified,"+
                    "format,"+
                    "language) "+
                    'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) returning id as document_id', [
                    data[0].contractingprocess.id,
                    data[4].contract.id,
                    data[7].implementation_id,
                    getValue(document.id),
                    getValue(document.type),
                    getValue(document.title),
                    getValue(document.description),
                    getValue(document.url),
                    parseDate(getValue(document.datePublished)),
                    parseDate(getValue(document.dateModified)),
                    getValue(document.format),
                    getValue(document.language)
                ]));
            }

            //contract -> implementation milestones
            for (let milestone of contract.implementation.milestones){
                queries.push(t.one('insert into implementationmilestone( contractingprocess_id,' +
                    'contract_id,' +
                    'implementation_id,' +
                    'milestoneid,' +
                    'title,' +
                    'description,' +
                    'duedate,' +
                    'date_modified,' +
                    'status) values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id as milestone_id',[
                    data[0].contractingprocess.id,
                    data[4].contract.id,
                    data[7].implementation_id,
                    getValue(milestone.id),
                    getValue(milestone.title),
                    getValue(milestone.description),
                    parseDate(getValue(milestone.dueDate)), // timestamp without time zone
                    parseDate(getValue(milestone.dateModified)), //  timestamp without time zone
                    getValue(milestone.status)
                ]));
            }

            //contract -> implementation transactions
            for (let transaction of contract.implementation.transactions){

                if( typeof transaction.providerOrganization === 'undefined'){ transaction.providerOrganization = {}}
                if( typeof transaction.receiverOrganization === 'undefined'){ transaction.receiverOrganization = {}}
                if( typeof transaction.value === 'undefined'){ transaction.value = {}}

                queries.push(t.one('insert into implementationtransactions(' +
                    'contractingprocess_id,'+
                    'contract_id,'+
                    'implementation_id,'+
                    'transactionid,'+
                    'source,'+
                    'implementation_date,'+
                    'value_amount,'+
                    'value_currency,'+
                    'providerorganization_scheme,'+
                    'providerorganization_id,'+
                    'providerorganization_legalname,'+
                    'providerorganization_uri,'+
                    'receiverorganization_scheme,'+
                    'receiverorganization_id,'+
                    'receiverorganization_legalname,'+
                    'receiverorganization_uri,'+
                    'uri) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) returning id as transaction_id ',[
                    data[0].contractingprocess.id,
                    data[4].contract.id,
                    data[7].implementation_id,
                    getValue(transaction.id),
                    getValue(transaction.source),
                    parseDate(getValue(transaction.date)),            // timestamp without time zone
                    parseNumber(getValue(transaction.value.amount)),                 // numeric
                    getValue(transaction.value.currency),
                    getValue(transaction.providerOrganization.scheme),
                    getValue(transaction.providerOrganization.id),
                    getValue(transaction.providerOrganization.legalName),
                    getValue(transaction.providerOrganization.uri),
                    getValue(transaction.receiverOrganization.scheme),
                    getValue(transaction.receiverOrganization.id),
                    getValue(transaction.receiverOrganization.legalName),
                    getValue(transaction.receiverOrganization.uri),
                    getValue(transaction.uri)
                ]));
            }

            return t.batch(queries);

        })

    }).then(function (data) {
        console.log(data);
        db_conf.pgp.end();
    }).catch(function (error) {
        console.log(error);
        db_conf.pgp.end();
    });

    //console.log(JSON.stringify(contracting_process));

} else {
    console.log('Error: file does not exists');
}
