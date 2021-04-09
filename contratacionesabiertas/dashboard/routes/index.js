var express = require('express');
var router = express.Router();

var pgp = require('pg-promise')();
var fs = require('fs');
var ejs = require('ejs');
var pdf = require('html-pdf');
////////////////////////////////////
const db = require('../dash_config');
var edca_db = db.dashboard;
//////////////////////////////////
var isAuthenticated = function (req, res, next) {
    // if user is authenticated in the session, call the next() to call the next request handler
    // Passport adds this method to request object. A middleware is allowed to add properties to
    // request and response objects
    if (req.isAuthenticated())
        return next();
    // if the user is not authenticated then redirect him to the login page
    console.log('Error', 'No esta logeado')
    res.redirect('/');
};
/* URL para del cdn de datos.gob.mx usado para cargar navbar y footer */

process.env.CDN_URL = 'https://cdn.datos.gob.mx/qa';

if (process.env.EDCA_DB){
    //console.log("EDCA_DB: ", process.env.EDCA_DB);
    edca_db = pgp( process.env.EDCA_DB );
} else {
    //console.log("Warning, no hay variable de ambiente declarada \n");
    edca_db = edca_db;
}

/* GET home page. */
router.get('/', function(req, res, next) {
    
    edca_db.task(function (t) {
        return this.batch([
        this.one('select count(*) as total from (select distinct partyid from contractingprocess, parties, roles where parties.contractingprocess_id = contractingprocess.id and parties.id = roles.parties_id and roles.supplier = true ) as t ;'),
        this.one('select count(*) as total from contractingprocess'),
        this.one('select count(*) as total from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id and contract.exchangerate_amount > 0 '),
        this.one('select sum(contract.exchangerate_amount) as total from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id ')
        ]);
    }).then(function (data) {
        res.render('index',{ title: 'Contrataciones Abiertas',
            metadata : {
                supplier_count: data[0].total,
                cp_count: data[1].total,
                contract_count: data[2].total,
                contract_exchangerate_amount_total: data[3].total
            }
        });
    }).catch(function (error) {
        console.log("ERROR: ", error);
    });

});

/* dashboard contract list (1st page) */
/* Lista de contrataciones */

router.get('/contratos/:year?',function (req, res) {
    var where = ' ';
    var where2 = ' ';

    if (req.params.year != null) {
        where += " and date_part('year', contract.datesigned) = " + req.params.year;
        where2 += " and (select id from contract where contractingprocess_id = contractingprocess.id and date_part('year', datesigned) = " + req.params.year + " limit 1) is not null";
    }

    edca_db.task(function (t) {
        return this.batch([
            this.one('select count(*) as total from (select distinct partyid from contractingprocess, contract, parties, roles where contract.contractingprocess_id = contractingprocess.id and parties.contractingprocess_id = contractingprocess.id and parties.id = roles.parties_id and roles.supplier = true' + where + ') as t;'), 
            this.one('select count(*) as total from (select distinct contractingprocess.id from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id' + where + ') t'),
            this.one('select count(*) as total from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id and contract.exchangerate_amount > 0' + where),
            this.one('select sum((select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id)) as total from contractingprocess where 1 = 1' + where2),
            this.manyOrNone(`select t.procurementmethod_details, count(*) as conteo, sum(t.total) as total
                from (select tender.procurementmethod_details,
                    (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as total
                    from contractingprocess
                    inner join tender on tender.contractingprocess_id = contractingprocess.id
                    where tender.procurementmethod_details is not null and tender.procurementmethod_details != ''${where2}) as t 
                group by t.procurementmethod_details order by total desc`),
            this.manyOrNone(`select t.additionalprocurementcategories, count(*) as conteo, sum(t.total) as total
                from (select tender.additionalprocurementcategories,
                    (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as total
                    from contractingprocess
                    inner join tender on tender.contractingprocess_id = contractingprocess.id
                    where tender.additionalprocurementcategories is not null and tender.additionalprocurementcategories != ''${where2}) as t 
                group by t.additionalprocurementcategories order by total desc`)
        ]);
    }).then(function (data) {
        res.render('dashboard',{ title: 'Contrataciones Abiertas',
            metadata : {
                year: req.params.year,
                supplier_count: +data[0].total,
                cp_count: +data[1].total,
                contract_count: +data[2].total,
                contract_exchangerate_amount_total: data[3].total,
                total_procedimiento: data[4],
                total_destino: data[5]
            }
        });

    }).catch(function (error) {
        console.log("ERROR: ", error);
        res.send('No se ha podido cargar la pagina');
    });
});

//PAGINATION
router.post('/pagination', function (req, res) {
    //contracts per page
    var limit = 6;

    var npage = 1;
    if ( !isNaN( +(req.body.npage) )){
        npage = Math.abs(req.body.npage);
    }

    edca_db.task(function (t) {
        var where = ` 1=1 `; 
        var whereExterno = ' where 1=1 ';
        if (req.body.year !== "" && req.body.year !== undefined) {
            where += " and (select id from contract where contractingprocess_id = contractingprocess.id and date_part('year', datesigned) = $5 limit 1) is not null";
        }

        if (req.body.keyword !== "" && req.body.keyword !== undefined) {
            where += " and (tender.title ilike '%$1#%' or contractingprocess.ocid ilike '%$1#%' or parties.name ilike '%$1#%' or parties.identifier_legalname ilike '%$1#%')";
        }

        if (req.body.process !== "" && req.body.process !== undefined) {
            where += " and tender.procurementmethod_details = $2";
        }

        if (req.body.stage !== "" && req.body.stage !== undefined) {
            switch(req.body.stage){
                case '5':
                whereExterno += ` and ((t.implementation_status in ('concluded') )
                 or (t.contract_status in ('active') and t.implementation_status not in ('concluded')) )`;
                break;
                case '4':
                whereExterno += ` and t.contract_status not in ('active') and t.award_status in ('active')
                and  (t.implementation_status is null or t.implementation_status not in ('concluded'))`;
                break;
                case '3':
                whereExterno += ` and t.award_status not in ('active')
                                  and t.tender_status in ('complete')
                                  and  (t.contract_status is null or t.contract_status  not in ('concluded'))
                                and  (t.implementation_status is null or t.implementation_status not in ('concluded'))`;
                break;
                case '2':
                whereExterno += ` and (t.tender_status is null or t.tender_status not in ('complete'))
                                and  (t.award_status is null or t.award_status not in ('active'))
                                and  (t.contract_status is null or t.contract_status  not in ('concluded'))
                                and  (t.implementation_status is null or t.implementation_status not in ('concluded'))`;
                break;
                case '1':
                whereExterno += ` and 1=0`; // nunca hay en esta etapa
                break;
            }
        }

        if (req.body.status !== "" && req.body.status !== undefined) {
            switch (req.body.stage) {
                case "2":
                    where += " and tender.status = $4";
                    break;
                case "3":
                    where += " and (select status from award where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) = $4";
                    break;
                case "4":
                    where += " and (select status from contract where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) = $4";
                    break;
                case "5":
                    where += " and (select status from implementation where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) = $4";
                    break;
            }
        }

        var query1 = `select * from (select distinct contractingprocess.id as localid, contractingprocess.uri, contractingprocess.ocid, contractingprocess.stage, contractingprocess.description,
            (select datesigned from contract where contractingprocess_id = contractingprocess.id order by datesigned limit 1) as datesigned,
            (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as exchangerate_amount,
            planning.hasquotes is not null as planning_active,
            tender.procurementmethod_details, tender.status as tender_status, tender.title,
            (select name
                from parties
                join roles r on r.parties_id = parties.id
                where parties.contractingprocess_id = contractingprocess.id and r.requestingunit = true limit 1) as name,
            (select status from award where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as award_status,
            (select status from contract where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as contract_status,
            (select status from implementation where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as implementation_status,
            (select string_agg(parties.name, '; ')                            
                from parties
                inner join roles on roles.parties_id = parties.id
                where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as name_supplier,
            (select string_agg(parties.identifier_legalname, '; ')
                from parties
                inner join roles on roles.parties_id = parties.id
                where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as identifier_legalname_supplier,
            (select count(*)
                from parties
                inner join roles on roles.parties_id = parties.id
                where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as nsuppliers
            from contractingprocess
            inner join planning on planning.contractingprocess_id = contractingprocess.id
            inner join tender on tender.contractingprocess_id = contractingprocess.id
            inner join parties on parties.contractingprocess_id = contractingprocess.id
            inner join roles as rod on rod.parties_id = parties.id
            where (rod.supplier = true or rod.buyer = true or rod.requestingunit = true) and` + where + ') t ' + whereExterno;

        var query2 = "select count(*) as total from (" + query1 + ") as q";
        
        if (req.body.orderby === undefined) {
            req.body.orderby = 'exchangerate_amount';
        }

        query1 += " order by $6~" + (req.body.orderby === 'exchangerate_amount' || req.body.orderby === 'datesigned' ? " desc" : "");
        query1 += " limit $7 offset $8";

        var params = [
            req.body.keyword,
            req.body.process,
            req.body.stage,
            req.body.status,
            req.body.year,
            req.body.orderby,
            limit,
            ( +( npage ) -1 )* limit
        ];

        return this.batch([
            this.manyOrNone(query1, params),
            this.one(query2, params)
        ]);
    }).then(function (data) {
        res.render('contracts', {
            contracts : data[0],
            cmetadata : {
                current_page: + npage,
                page_count: parseInt(( +data[1].total + +limit -1 ) / limit )
            }
        });
    }).catch(function (error) {
        res.send('ERROR');
        console.log("ERROR: ", error);
    });
});

let translateHito = hito => {
    switch(hito){
        case 'met': return 'Cumplido';
        case 'notMet': return 'No cumplido';
        case 'partiallyMet': return 'Parcialmente cumplido';
        case 'scheduled': return 'Programado';
    }
}

/* GET download contract details */
router.get('/contrato/:cpid/download', function (req, res) {
    var ocid = '';
    var result = {
        planning: {},
        tender: {},
        awards: [],
        contracts: [],
        implementations: [],
        header: {}
    };

    var planningQuery = `select 'Planeación' as stage, planning.hasquotes, planning.rationale,
        (select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = planning.contractingprocess_id and roles.buyer = true limit 1) as buyer,
		(select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = planning.contractingprocess_id and roles.requestingunit = true limit 1) as requestingunit       
        from planning
        where planning.contractingprocess_id = $1 order by id`;

    var tenderQuery = `select 'Licitación' as stage, tender.status, tender.tenderid, tender.title, tender.value_amount, tender.value_currency, tender.description, tender.procurementmethod_details, tender.additionalprocurementcategories,
        (date_part('day', tender.tenderperiod_startdate) || '/' || date_part('month', tender.tenderperiod_startdate) || '/' || date_part('year', tender.tenderperiod_startdate)) as tender_startdate,
        (date_part('day', tender.tenderperiod_enddate) || '/' || date_part('month', tender.tenderperiod_enddate) || '/' || date_part('year', tender.tenderperiod_enddate)) as tender_enddate,
        (select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = tender.contractingprocess_id and roles.buyer = true limit 1) as buyer,
		(select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = tender.contractingprocess_id and roles.requestingunit = true limit 1) as requestingunit
        from tender
        where tender.contractingprocess_id = $1 order by id`;

    var awardQuery = `select 'Adjudicación' as stage, award.id, award.status, award.awardid, award.title, award.value_amount, award.value_currency, award.rationale,
        (date_part('day', award.award_date) || '/' || date_part('month', award.award_date) || '/' || date_part('year', award.award_date)) as award_date,
        (select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = award.contractingprocess_id and roles.buyer = true limit 1) as buyer,
		(select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = award.contractingprocess_id and roles.requestingunit = true limit 1) as requestingunit
        from award
        where award.contractingprocess_id = $1 order by id`;

    var contractQuery = `select 'Contratación' as stage, contract.id, contract.status, contract.contractid, contract.title, contract.value_amount, contract.value_currency, contract.description,
        (date_part('day', contract.datesigned) || '/' || date_part('month', contract.datesigned) || '/' || date_part('year', contract.datesigned)) as datesigned,
        (select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = contract.contractingprocess_id and roles.buyer = true limit 1) as buyer,
		(select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = contract.contractingprocess_id and roles.requestingunit = true limit 1) as requestingunit
        from contract
        where contract.contractingprocess_id = $1 order by id`;

    var implementationQuery = `select 'Ejecución' as stage, implementation.id, implementation.status,
        (select contract.contractid from contract where contract.id = implementation.contract_id order by datelastupdate desc limit 1) as contractid,
        (select (date_part('day', contract.datesigned) || '/' || date_part('month', contract.datesigned) || '/' || date_part('year', contract.datesigned)) from contract where contract.id = implementation.contract_id order by datelastupdate desc limit 1) as datesigned,
        (select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = implementation.contractingprocess_id and roles.buyer = true limit 1) as buyer,
		(select parties.identifier_legalname from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = implementation.contractingprocess_id and roles.requestingunit = true limit 1) as requestingunit
        from implementation
        where implementation.contractingprocess_id = $1 order by id`;

    var headerQuery = `select contractingprocess.id as localid, contractingprocess.uri, contractingprocess.ocid, contractingprocess.stage, contractingprocess.description,
                                        (select datesigned from contract where contractingprocess_id = contractingprocess.id order by datesigned limit 1) as datesigned,
                                        (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as exchangerate_amount,
                                        planning.hasquotes is not null as planning_active,
                                        tender.procurementmethod_details, tender.status as tender_status, tender.title,
                                        (select name
                                            from parties
                                            where contractingprocess_id = contractingprocess.id limit 1) as name,
                                        (select status from award where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as award_status,
                                        (select status from contract where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as contract_status,
                                        (select status from implementation where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as implementation_status,
                                        (select string_agg(parties.name, '; ')                            
                                            from parties
                                            inner join roles on roles.parties_id = parties.id
                                            where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as name_supplier,
                                        (select string_agg(parties.identifier_legalname, '; ')
                                            from parties
                                            inner join roles on roles.parties_id = parties.id
                                            where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as identifier_legalname_supplier,
										(select string_agg(parties.identifier_legalname, '; ')
                                            from parties
                                            inner join roles on roles.parties_id = parties.id
                                            where roles.requestingunit = true and parties.contractingprocess_id = contractingprocess.id) as identifier_legalname_requestingunit,
                                        (select count(*)
                                            from parties
                                            inner join roles on roles.parties_id = parties.id
                                            where roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as nsuppliers
                                        from contractingprocess
                                        inner join planning on planning.contractingprocess_id = contractingprocess.id
                                        inner join tender on tender.contractingprocess_id = contractingprocess.id
                                        where contractingprocess.id = $1 limit 1`;

    edca_db.one('select id, ocid from contractingprocess where id = $1', [req.params.cpid]).then(function (data) {
        ocid = data.ocid;
        
        edca_db.task(function (t) {
            return t.batch([
                t.task(function (t2) {
                    return t2.oneOrNone(planningQuery, [data.id]).then(function (e) {
                        return t2.batch([
                            t2.manyOrNone("select budgetbreakdown.budgetbreakdown_id, budgetbreakdown.description, budgetbreakdown.amount, budgetbreakdown.currency, parties.name as source from budgetbreakdown inner join parties on parties.id = budgetbreakdown.source_id where budgetbreakdown.contractingprocess_id = $1", [data.id]), // presupuesto planeacion
                            t2.task(function (t3) {
                                return t3.map("select quotes.id, quotes.quotes_id, quotes.description, parties.name as supplier, parties.identifier_id as supplier_rfc, to_char(period_enddate, 'DD/MM/YYYY') period_enddate,  to_char(period_startdate, 'DD/MM/YYYY') period_startdate, to_char(date, 'DD/MM/YYYY') date, value from quotes inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id inner join parties on parties.id = quotes.issuingsupplier_id where requestforquotes.contractingprocess_id = $1", [data.id], function (e2) { // cotizacion planeacion
                                    return t3.batch([
                                        t3.manyOrNone("select quotesitems.quantity, item.description as item, item.unit from quotesitems inner join item on item.classificationid = quotesitems.itemid where quotesitems.quotes_id = $1", [e2.id]) // items cotizacion
                                    ]).then(function (data) {
                                        e2['items'] = data[0];
                                        return e2;
                                    });
                                }).then(t3.batch)
                            }),
                            t2.manyOrNone('select documentid, title, description, url from planningdocuments where contractingprocess_id = $1', [data.id]) // documentos planeacion
                        ]).then(function (data) {
                            e['budgetBreakdown'] = data[0];
                            e['quotes'] = data[1];
                            e['documents'] = data[2];

                            return e;
                        });
                    });
                }), // planeacion
                t.task(function (t2) {
                    return t2.oneOrNone(tenderQuery, [data.id]).then(function (e) {
                        return t2.batch([
                            t2.manyOrNone('select itemid, description, classification_description, unit_name, quantity from tenderitem where contractingprocess_id = $1', [data.id]), // items licitacion
                            t2.manyOrNone("select parties.name, parties.identifier_id from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.tenderer = true", [data.id]), // licitantes licitacion
                            t2.manyOrNone("select title, description, (date_part('day', duedate) || '/' || date_part('month', duedate) || '/' || date_part('year', duedate)) as duedate, (date_part('day', date_modified) || '/' || date_part('month', date_modified) || '/' || date_part('year', date_modified)) as date_modified, status from tendermilestone where contractingprocess_id = $1", [data.id]), // hitos licitacion
                            t2.manyOrNone('select documentid, title, description, url from tenderdocuments where contractingprocess_id = $1', [data.id]), // documentos licitacion
                            t2.manyOrNone("select (date_part('day', amendments_date) || '/' || date_part('month', amendments_date) || '/' || date_part('year', amendments_date)) as amendments_date, amendments_rationale, amendments_id, amendments_description from tenderamendmentchanges where contractingprocess_id = $1", [data.id]) // modificaciones licitacion
                        ]).then(function (data) {
                            e['items'] = data[0];
                            e['tenderers'] = data[1];
                            e['milestones'] = data[2];
                            e['documents'] = data[3];
                            e['changes'] = data[4];

                            switch (e.status) {
                                case 'planning':
                                    e.status = 'En planeación';
                                    break;
                                case 'planned':
                                    e.status = 'Planeada';
                                    break;
                                case 'active':
                                    e.status = 'Activa';
                                    break;
                                case 'cancelled':
                                    e.status = 'Cancelada';
                                    break;
                                case 'unsuccessful':
                                    e.status = 'No exitosa';
                                    break;
                                case 'complete':
                                    e.status = 'Concluida';
                                    break;
                                case 'withdrawn':
                                    e.status = 'Retirada';
                                    break;
                                default:
                                    e.status = '';
                                    break;
                            }

                            e['milestones'].map(x => x.status = translateHito(x.status));

                            return e;
                        });
                    });
                }), // licitacion
                t.task(function (t2) {
                    return t2.map(awardQuery, [data.id], function (e) {
                        return t2.batch([
                            t2.manyOrNone('select distinct parties.name, parties.identifier_legalname, parties.identifier_id, parties.address_streetaddress, parties.address_locality, parties.address_region, parties.address_postalcode, parties.address_countryname , naturalperson from parties inner join roles on roles.parties_id = parties.id join awardsupplier on awardsupplier.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.supplier = true and awardsupplier.award_id = $2 ', [data.id, e.id]), // proveedores adjudicacion
                            t2.manyOrNone('select itemid, description, classification_description , unit_name, quantity from awarditem where contractingprocess_id = $1 and award_id = $2', [data.id, e.id]), // items adjudicacion
                            t2.manyOrNone('select documentid, title, description, url from awarddocuments where contractingprocess_id = $1 and award_id = $2', [data.id, e.id]), // documentos adjudicacion
                            t2.manyOrNone("select (date_part('day', amendments_date) || '/' || date_part('month', amendments_date) || '/' || date_part('year', amendments_date)) as amendments_date, amendments_rationale, amendments_id, amendments_description from awardamendmentchanges where contractingprocess_id = $1 and award_id = $2", [data.id, e.id]) // modificaciones adjudicacion
                        ]).then(function (data) {
                            e['suppliers'] = data[0];
                            e['items'] = data[1];
                            e['documents'] = data[2];
                            e['changes'] = data[3];

                            switch (e.status) {
                                case 'pending':
                                    e.status = 'Pendiente';
                                    break;
                                case 'active':
                                    e.status = 'Activo';
                                    break;
                                case 'cancelled':
                                    e.status = 'Cancelado';
                                    break;
                                case 'unsuccessful':
                                    e.status = 'No exitoso';
                                    break;
                                default:
                                    e.status = '';
                                    break;
                            }

                            return e;
                        });
                    }).then(t2.batch);
                }), // adjudicacion
                t.task(function (t2) {
                    return t2.map(contractQuery, [data.id], function (e) {
                        return t2.batch([
                            t2.manyOrNone('select itemid, description,classification_description, unit_name, quantity from contractitem where contractingprocess_id = $1 and contract_id = $2', [data.id, e.id]), // items contratacion
                            t2.manyOrNone('select documentid, title, description, url from contractdocuments where contractingprocess_id = $1 and contract_id = $2', [data.id, e.id]), // documentos contratacion
                            t2.manyOrNone("select (date_part('day', amendments_date) || '/' || date_part('month', amendments_date) || '/' || date_part('year', amendments_date)) as amendments_date, amendments_rationale, amendments_id, amendments_description from contractamendmentchanges where contractingprocess_id = $1 and contract_id = $2", [data.id, e.id]) // modificaciones contratacion
                        ]).then(function (data) {
                            e['items'] = data[0];
                            e['documents'] = data[1];
                            e['changes'] = data[2];

                            switch (e.status) {
                                case 'pending':
                                    e.status = 'Pendiente';
                                    break;
                                case 'active':
                                    e.status = 'Activo';
                                    break;
                                case 'cancelled':
                                    e.status = 'Cancelado';
                                    break;
                                case 'terminated':
                                    e.status = 'Terminado';
                                    break;
                                default:
                                    e.status = '';
                                    break;
                            }

                            return e;
                        });
                    }).then(t2.batch);
                }), // contratacion
                t.task(function (t2) {
                    return t2.map(implementationQuery, [data.id], function (e) {
                        return t2.batch([
                            t2.manyOrNone("select title, description, (date_part('day', duedate) || '/' || date_part('month', duedate) || '/' || date_part('year', duedate)) as duedate, (date_part('day', date_modified) || '/' || date_part('month', date_modified) || '/' || date_part('year', date_modified)) as date_modified, status from implementationmilestone where contractingprocess_id = $1 and implementation_id = $2", [data.id, e.id]), // hitos ejecucion
                            t2.manyOrNone("select transactionid, (date_part('day', implementation_date) || '/' || date_part('month', implementation_date) || '/' || date_part('year', implementation_date)) as implementation_date, value_amount, value_currency from implementationtransactions where contractingprocess_id = $1 and implementation_id = $2", [data.id, e.id]), // transacciones ejecucion
                            t2.manyOrNone('select documentid, title, description, url from implementationdocuments where contractingprocess_id = $1 and implementation_id = $2', [data.id, e.id]) // documentos ejecucion
                        ]).then(function (data) {
                            e['milestones'] = data[0];
                            e['transactions'] = data[1];
                            e['documents'] = data[2];

                            e['milestones'].map(x => x.status = translateHito(x.status));

                            switch (e.status) {
                                case 'planning':
                                    e.status = 'En planeación';
                                    break;
                                case 'ongoing':
                                    e.status = 'En progreso';
                                    break;
                                case 'concluded':
                                    e.status = 'En finiquito';
                                    break;
                                default:
                                    e.status = '';
                                    break;
                            }

                            return e;
                        });
                    }).then(t2.batch);
                }), // ejecucion
                t.task(function(t2){
                    return t2.oneOrNone(headerQuery, [data.id]);
                }) // cabecera
            ]);
        }).then(function (data) {
            Object.assign(result.planning, data[0]);
            Object.assign(result.tender, data[1]);
            Object.assign(result.awards, data[2]);
            Object.assign(result.contracts, data[3]);
            Object.assign(result.implementations, data[4]);
            Object.assign(result.header, data[5]);

              fs.readFile('contracting_form.html', 'utf8', (err, html) => {

                var options = { format: 'Letter' };

                if (err) {
                    html = '';
                }

                if (html != '') {
                    var compiled = ejs.compile(html);
                    html = compiled(result);
                }
        
                pdf.create(html, options).toStream((err, stream) => {
                    var buffers = [];
        
                    try{
                        stream.on('data', buffers.push.bind(buffers));
            
                        stream.on('end', () => {
                            var data = Buffer.concat(buffers);
            
                            res.writeHead(200, {
                                'Content-Type': 'application/pdf',
                                'Content-disposition': `attachment;filename=record_${ocid}.pdf`,
                                'Content-Length': data.byteLength
                            });
                
                            res.end(data);
                        });
                    }catch(e){
                        console.log(e);
                    }
                });
            });
        }).catch(function (error) {
            res.send(result);
        });
    }).catch(function (error) {
        res.send(result);
    });
});

function convertDate(inputFormat) {
    function pad(s) { return (s < 10) ? '0' + s : s; }
    var d = new Date(inputFormat);
    return [pad(d.getDate()), pad(d.getMonth()+1), d.getFullYear()].join('/');
  }

/* GET contract details */
router.get('/contrato/:cpid/:stage',function (req, res) {
    var stage = req.params.stage ;

    var cpid = 1;

    if ( !isNaN( parseInt(req.params.cpid) )){
        cpid = Math.abs( req.params.cpid );
    }


    //buscar cpid
    edca_db.one('select id from contractingprocess where id = $1',[cpid]).then(function (data) {

        var qinfo = `select tender.contractingprocess_id as cpid, tender.procurementmethod_details, title
            from tender
            where tender.contractingprocess_id = $1 order by id`;

        var q1 = `select * from $1~ where contractingprocess_id = $2 order by id`;

        var qstatus = `
            select planning.hasquotes is not null as planning, tender.status as tender,
            (select status from award where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as award,
            (select status from contract where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as contract,
            (select status from implementation where implementation.contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as implementation
            from contractingprocess
            inner join planning on planning.contractingprocess_id = contractingprocess.id
            inner join tender on tender.contractingprocess_id = contractingprocess.id
            where contractingprocess.id = $1
        `;

        switch ( stage ){
            case 'licitacion':
                edca_db.task( function (t) {
                    return this.batch([
                        //información general
                        this.one(qinfo, [ cpid ]),
                        this.oneOrNone( "select * from parties, roles where parties.id = roles.parties_id and roles.buyer=true and parties.contractingprocess_id=$1 limit 1",[ cpid ]), //cambia
						this.one(q1,[ 'tender', cpid ]),
                        this.manyOrNone(q1,[ 'tenderitem', cpid ]),
                        this.manyOrNone(q1,[ 'tendermilestone', cpid ]),
                        this.manyOrNone(q1,[ 'tenderdocuments', cpid ]),
                        this.manyOrNone(q1,[ 'tenderamendmentchanges', cpid ]),
                        this.oneOrNone("select * from contractingprocess where id = $1",[ cpid ]),
                        this.oneOrNone("select * from links where contractingprocess_id = $1",[ cpid ]),
                        this.one(qstatus, [ cpid ]),
                        this.manyOrNone("select parties.name, parties.identifier_id from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.tenderer = true", [cpid]),
						this.oneOrNone( "select * from parties, roles where parties.id = roles.parties_id and roles.requestingunit=true and parties.contractingprocess_id=$1 limit 1",[ cpid ])
                    ]);
                }).then(function (data) {

                    data[4].map(x => {
                        x.status = translateHito(x.status);
                        x.date = convertDate(x.date);
                        x.duedate = convertDate(x.duedate);
                        x.date_modified = convertDate(x.date_modified);
                    });

                    data[6].map(x => x.amendments_date = convertDate(x.amendments_date));

                    res.render('contract',{
                        current_stage: stage,
                        info: data[0],
                        buyer: data[1],
                        tender: data[2],
                        items: data[3],
                        milestones: data[4],
                        documents: data[5],
                        changes: data[6],
                        contractingprocess: data[7],
                        links: data[8],
                        status: data[9],
                        tenderers: data[10],
						requestingunit: data[11]
                    });
                }).catch(function (error) {
                    console.log("ERROR: ", error);
                    res.render('error', { message: 'Proceso de contratación inexistente', error: error });
                });
                break;
            case 'adjudicacion':
                edca_db.task( function (t) {
                    return this.batch([
                        //información general
                        this.one(qinfo, [ cpid ]),
                        this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.buyer=true and parties.contractingprocess_id=$1 limit 1",[cpid ]),
                        this.manyOrNone(q1 ,[ 'award', cpid ]),
                        this.manyOrNone("select distinct parties.*, roles.*, award_id from parties, roles, awardsupplier where awardsupplier.parties_id =  parties.id  and parties.id = roles.parties_id and roles.supplier=true and parties.contractingprocess_id=$1" ,[ cpid ]),
                        this.manyOrNone(q1 ,[ 'awarditem', cpid ]),
                        this.manyOrNone(q1 ,[ 'awarddocuments', cpid ]),
                        this.manyOrNone(q1 ,[ 'awardamendmentchanges', cpid ]),
                        this.oneOrNone("select * from contractingprocess where id = $1",[ cpid ]),
                        this.oneOrNone("select * from links where contractingprocess_id = $1",[ cpid ]),
                        this.one(qstatus, [ cpid ]),
					    this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.requestingunit=true and parties.contractingprocess_id=$1 limit 1",[cpid ])
                    ]);
                }).then(function (data) {

                    let awards = data[2].map(a => {
                        a.suppliers = data[3].filter(x => x.award_id == a.id);
                        a.items =  data[4].filter(x => x.award_id == a.id);
                        a.documents =  data[5].filter(x => x.award_id == a.id);
                        a.changes =  data[6].filter(x => x.award_id == a.id);
                        a.changes.map(x => x.amendments_date = convertDate(x.amendments_date));
                        return a;
                    });


                    res.render('contract',{
                        current_stage: stage,
                        info: data[0],
                        buyer: data[1],
                        results: awards,
                        contractingprocess: data[7],
                        links: data[8],
                        status: data[9],
						requestingunit: data[10]
                    });
                }).catch(function (error) {
                    console.log("ERROR: ", error);
                    res.render('error', { message: 'Proceso de contratación inexistente', error: error });
                });
                break;
            case 'contratacion':
                edca_db.task( function (t) {
                    return this.batch([
                        //información general
                        this.one(qinfo, [ cpid ]),
                        this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.buyer=true and parties.contractingprocess_id=$1 limit 1",[ cpid ]),
                        this.manyOrNone(q1 ,[ 'contract', cpid ]),
                        this.manyOrNone(q1 ,[ 'contractitem', cpid ]),
                        this.manyOrNone(q1 ,[ 'contractdocuments', cpid ]),
                        this.manyOrNone(q1 ,[ 'contractamendmentchanges', cpid ]),
                        this.oneOrNone("select * from contractingprocess where id = $1",[ cpid ]),
                        this.oneOrNone("select * from links where contractingprocess_id = $1",[ cpid ]),
                        this.one(qstatus, [ cpid ]),
					    this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.requestingunit=true and parties.contractingprocess_id=$1 limit 1",[ cpid ])
                    ]);
                }).then(function (data) {
                    data[5].map(x => x.amendments_date = convertDate(x.amendments_date));
                    res.render('contract',{
                        current_stage: stage,
                        info: data[0],
                        buyer: data[1],
                        results: data[2],
                        items : data[3],
                        documents : data[4],
                        changes : data[5],
                        contractingprocess : data[6],
                        links: data[7],
                        status: data[8],
						requestingunit: data[9]
                    });
                }).catch(function (error) {
                    console.log("ERROR: ", error);
                    res.render('error', { message: 'Proceso de contratación inexistente', error: error });
                });
                break;
            case 'implementacion':
                edca_db.task( function (t) {
                    return this.batch([
                        //Información general
                        this.one(qinfo, [ cpid ]),
                        this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.buyer=true and parties.contractingprocess_id=$1 limit 1",[cpid ]),
                        this.manyOrNone('select implementation.*, contract.contractid, contract.datesigned from implementation inner join contract on contract.id = implementation.contract_id where implementation.contractingprocess_id = $1', [cpid]),
                        this.manyOrNone(q1, ['implementationtransactions', cpid ]),
                        this.manyOrNone(q1, ['implementationmilestone', cpid ]),
                        this.manyOrNone(q1, ['implementationdocuments', cpid ]),
                        this.oneOrNone("select * from contractingprocess where id = $1",[ cpid ]),
                        this.oneOrNone("select * from links where contractingprocess_id = $1",[ cpid ]),
                        this.one(qstatus, [ cpid ]),
						this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.requestingunit=true and parties.contractingprocess_id=$1 limit 1",[cpid ])
                    ]);
                }).then(function (data) {
                    data[4].map(x => {
                        x.status = translateHito(x.status);
                        x.duedate = convertDate(x.duedate);
                        x.date_modified = convertDate(x.date_modified);
                    });
                    data[3].map(x =>  x.implementation_date = convertDate(x.implementation_date));
                    res.render('contract',{
                        current_stage: stage,
                        info: data[0],
                        buyer: data[1],
                        results: data [2],
                        transactions: data[3],
                        milestones: data[4],
                        documents: data[5],
                        contractingprocess : data[6],
                        links: data[7],
                        status: data[8],
						requestingunit: data[9]
                    });
                }).catch(function (error) {
                    console.log("ERROR: ", error);
                    res.render('error', { message: 'Proceso de contratación inexistente', error: error });
                });
                break;
            default:
                edca_db.task( function (t) {
                    return this.batch([
                        //información general
                        this.oneOrNone(qinfo, [cpid]),
                        this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.buyer=true and parties.contractingprocess_id=$1 limit 1", [cpid]),
                        this.oneOrNone(q1 ,['budget', cpid]),
                        this.manyOrNone(q1,['planningdocuments', cpid]),
                        this.oneOrNone("select * from contractingprocess where id = $1",[ cpid ]),
                        this.oneOrNone("select * from links where contractingprocess_id = $1",[ cpid ]),
                        this.oneOrNone("select * from planning where contractingprocess_id = $1", [ cpid ]),
                        this.oneOrNone(qstatus, [ cpid ]),
                        this.manyOrNone("select quotes.*, to_char(period_enddate, 'DD/MM/YYYY') period_enddate,  to_char(period_startdate, 'DD/MM/YYYY') period_startdate, parties.name as supplier, parties.identifier_id as supplier_rfc, to_char(date, 'DD/MM/YYYY'), value from quotes inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id inner join parties on parties.id = quotes.issuingsupplier_id where requestforquotes.contractingprocess_id = $1", [cpid]),
                        this.manyOrNone("select quotesitems.*, item.description as item, item.unit from quotesitems inner join quotes on quotes.id = quotesitems.quotes_id inner join requestforquotes on requestforquotes.id = quotes.requestforquotes_id inner join item on item.classificationid = quotesitems.itemid where requestforquotes.contractingprocess_id = $1", [cpid]),
                        this.manyOrNone("select budgetbreakdown.*, parties.name as source from budgetbreakdown inner join parties on parties.id = budgetbreakdown.source_id where budgetbreakdown.contractingprocess_id = $1", [cpid]),
						this.oneOrNone("select * from parties, roles where parties.id = roles.parties_id and roles.requestingunit=true and parties.contractingprocess_id=$1 limit 1", [cpid])
                    ]);
                }).then(function (data) {

                    data[8].map(x => x.date = convertDate(x.date));
                    
                    res.render('contract',{
                        current_stage: stage,
                        info: data[0],
                        buyer: data[1],
                        budget : data[2],
                        documents: data[3],
                        contractingprocess: data[4],
                        links: data[5],
                        results: data[6],
                        status: data[7],
                        quotes: data[8],
                        items: data[9],
                        budgetBreakdown: data[10],
						requestingunit: data[11]
                    });
                }).catch(function (error) {
                    console.log("ERROR: ", error);
                    res.render('error', { message: 'Proceso de contratación inexistente', error: error });
                });
                break;
        }


    }).catch(function (error) {
        res.send("Atención: <b>Proceso no registrado</b>");
        console.log(error);
    });

});


/* supplier details & statistics */

/* Gráfica: Contrataciones en el tiempo */

router.post('/bubble-chart-data', function (req, res) {

    var query = `select t.*
        from (select contractingprocess.id, tender.procurementmethod_details, tender.title as title, tender.status as estatus_tender,
                (select datesigned from contract where contractingprocess_id = contractingprocess.id order by datesigned limit 1) as datesigned,
                (select period_enddate - period_startdate from contract where contractingprocess_id = contractingprocess.id order by datesigned limit 1) as vigencia,
                (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as exchangerate_amount,
                (select status from contract where contractingprocess_id = contractingprocess.id limit 1) as estatus_con,
				(select status from implementation where contractingprocess_id = contractingprocess.id limit 1) as estatus_imp
            from contractingprocess
            inner join tender on tender.contractingprocess_id = contractingprocess.id
            
        ) t
        where t.datesigned is not null and t.vigencia is not null`

    if (req.body.year !== "" && req.body.year !== undefined) {
        query += " and (select id from contract where contractingprocess_id = t.id and date_part('year', datesigned) = $1 limit 1) is not null";
    }

    edca_db.manyOrNone(query, [req.body.year]).then(function (data) {
        res.send(data);
    }).catch(function (error) {
        res.send(error);
        console.log("ERROR: ",error)
    });
});

/* Gráfica: Procedimiento de la contratación */

router.post('/donut-chart-data', function (req, res) {

    var query = `select t.procurementmethod_details, count(*) as conteo, concat(round(sum(t.percentage), 1), '%') as percentage, sum(t.sum) as sum
    from (select tender.procurementmethod_details,
        (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as sum,
        (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id)/(select sum(exchangerate_amount) from contract) * 100 as percentage
        from contractingprocess
        inner join tender on tender.contractingprocess_id = contractingprocess.id
        where tender.procurementmethod_details is not null and tender.procurementmethod_details != ''`;

    if (req.body.year !== "" && req.body.year !== undefined) {

        query += " and (select id from contract where contractingprocess_id = contractingprocess.id and date_part('year', datesigned) = $1 limit 1) is not null";
    }

    query += ") as t group by t.procurementmethod_details order by t.procurementmethod_details";

    edca_db.manyOrNone(query, [req.body.year]).then(function (data) {
        res.json (data);
    }).catch(function (error) {
        console.log("ERROR: ", error)
    });
});

/* Gráfica: Destino de la contratación */

router.post('/donut-chart2-data', function (req, res) {

    var query = `select t.additionalprocurementcategories, count(*) as conteo, concat(round(sum(t.percentage), 1), '%') as percentage, sum(t.sum) as sum
    from (select tender.additionalprocurementcategories,
        (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as sum,
        (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id)/(select sum(exchangerate_amount) from contract) * 100 as percentage
        from contractingprocess
        inner join tender on tender.contractingprocess_id = contractingprocess.id
        where tender.additionalprocurementcategories is not null and tender.additionalprocurementcategories != ''`;

    if (req.body.year !== "" && req.body.year !== undefined) {

        query += " and (select id from contract where contractingprocess_id = contractingprocess.id and date_part('year', datesigned) = $1 limit 1) is not null";
    }

    query += ") as t group by t.additionalprocurementcategories order by t.additionalprocurementcategories";

    edca_db.manyOrNone(query, [req.body.year]).then(function (data) {
        res.json (data);
    }).catch(function (error) {
        console.log("ERROR: ", error)
    });
});

/* Gráfica: Procedimientos por etapas */

router.post('/stage-chart-data', function (req, res) {
    var query = `select tender.procurementmethod_details as process, contractingprocess.stage, count(*) as total
        from contractingprocess
        inner join tender on tender.contractingprocess_id = contractingprocess.id
        where 1 = 1`;

    if (req.body.year !== "" && req.body.year !== undefined) {
        query += " and (select id from contract where contractingprocess_id = contractingprocess.id and date_part('year', datesigned) = $1 limit 1) is not null";
    }

    query += ` group by tender.procurementmethod_details, contractingprocess.stage order by tender.procurementmethod_details, contractingprocess.stage`;

    edca_db.manyOrNone(query, [req.body.year]).then(function (data) {
          res.json (data);
    }).catch(function (error) {
          console.log("ERROR: ", error)
    });
});

/* Gráfica: Información general de contratos y proveedores */

router.post('/d3-bubble-chart-data', function (req, res) {
    var query = `select
    (select string_agg(partyid, '; ') from parties, roles where parties.id = roles.parties_id and roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as partyid,
    (select string_agg(name, '; ') from parties, roles where parties.id = roles.parties_id and roles.supplier = true and parties.contractingprocess_id = contractingprocess.id) as name,
    (select string_agg(identifier_legalname, '; ') from parties, roles where parties.id = roles.parties_id and roles.requestingunit = true and parties.contractingprocess_id = contractingprocess.id) as identifier_legalname,
    ocid, contract.title, tender.procurementmethod_details, tender.additionalprocurementcategories, 
    (tender.status) as estatus_tender,
    (contract.status) as estatus_contract,
    (implementation.status) as estatus_implementation,
    concat(cast((DATE_PART('year', period_enddate) - DATE_PART('year', period_startdate)) * 12 + (DATE_PART('month', period_enddate) - DATE_PART('month', period_startdate)) as integer) / 12, ' año(s)') as vigencia,
    contract.exchangerate_amount, contract.contractingprocess_id as cpid
    from tender, contract, implementation, contractingprocess
    where  contractingprocess.id = implementation.contractingprocess_id and contractingprocess.id = contract.contractingprocess_id and contractingprocess.id = tender.contractingprocess_id
    and tender.procurementmethod_details is not null and tender.procurementmethod_details not like ''
    and tender.additionalprocurementcategories is not null and tender.additionalprocurementcategories not like ''
    and (contract.period_enddate is not null and contract.period_startdate is not null)`;

    if (req.body.year !== "" && req.body.year !== undefined) {
        query += " and date_part('year', contract.datesigned) = $1";
    }

    query += " order by cast ((DATE_PART('year', period_enddate) - DATE_PART('year', period_startdate)) * 12 + (DATE_PART('month', period_enddate) - DATE_PART('month', period_startdate)) as integer) / 12";

    edca_db.manyOrNone(query, [req.body.year]).then(function (data) {
        res.json(data);
    }).catch(function (error) {
        console.log(error);
        res.json(error);
    });
});

/* DISCLAIMER */
router.get('/acerca/', function (req, res ) {
    res.render ('acerca');
});

router.get('/implementa/', function (req, res ) {
    res.render ('implementa');
});

router.get('/datosabiertos/', function (req, res ) {
    res.render ('datosabiertos');
});

router.get('/politicadepublicacion/', function(req,res){
    res.render ('politicadepublicacion');
})

/* API */
router.post('/apiprocurementmethod',async function(req,res){
    console.log(`api_procurementmethod ${JSON.stringify(req.body)}`)
    var query = `select 
        DISTINCT ON(a.contractingprocess_id) a.contractingprocess_id, 
        cast(a.version as int) as version,
        a.id as log_id,a.update_date,a.release_file,
        a.release_json,a.publisher,b.name,b.scheme,b.uid,b.uri,
        c.license,c.publicationpolicy
        from logs as a, publisher as b, contractingprocess as c, tender as d
        where 1 = 1
        and a.contractingprocess_id = b.contractingprocess_id 
        and a.contractingprocess_id = c.id 
        and d.contractingprocess_id = c.id
        and c.published = true 
        and d.procurementmethod_details = '${req.body.procurementmethod}'
        order by a.contractingprocess_id,cast(a.version as int) desc;`;
    console.log("························· query "  + query);    
    let data = await db_conf.edca_db.manyOrNone(query);
    if(data.length !== 0){
        data.forEach(element => {
            var objReleasePackage  = new Object();
            var objPublisher  = new Object();
            objReleasePackage.uri = `${getHost(req)}/release-package/${element.version}/${element.release_file}`;
            objReleasePackage.version = '1.1';
            objReleasePackage.extensions = "_extensions";
            if(element.update_date !== "" && element.update_date !== null)
                objReleasePackage.publishedDate = element.update_date;
            if(element.release_json !== "" && element.release_json !== null)
                objReleasePackage.releases = [element.release_json];
            if(element.name !== "" && element.name !== null)
                objPublisher.name = element.name;
            if(element.scheme !== "" && element.scheme !== null)
                objPublisher.scheme = element.scheme;
            if(element.uid !== "" && element.uid !== null)
                objPublisher.uid = element.uid;
            if(element.uri !== "" && element.uri !== null)
                objPublisher.uri = element.uri;
            if(Object.entries(objPublisher).length !== 0)
                objReleasePackage.publisher = objPublisher;
            if(element.license !== "" && element.license !== null)
                objReleasePackage.license = element.license;
            if(element.publicationpolicy !== "" && element.publicationpolicy !== null)
                objReleasePackage.publicationPolicy = element.publicationpolicy;
            arrayReleasePackage.push(objReleasePackage)
        });
        return res.status(200).json({
                arrayReleasePackage
            }
        );
    }else{
        return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        );
    }
});


module.exports = router;
