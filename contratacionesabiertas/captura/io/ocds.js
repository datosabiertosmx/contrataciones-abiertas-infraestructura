module.exports = {

    getOCDSJSON: function ( localid , type, edca_db ) {

        //queries principales
        return edca_db.task(function (t) {

            return t.one("Select * from contractingprocess where id = $1", [localid]).then(function (cp) { //0

                return t.batch([
                    cp,
                    t.one("select * from planning where contractingprocess_id = $1", [localid]),    //1
                    t.one("select * from budget where contractingprocess_id = $1", [localid]),         //2
                    t.one("select * from tender where contractingprocess_id = $1", [localid]),        //3
                    t.oneOrNone("select * from parties, roles where roles.parties_id = parties.id and roles.requestingunit = true and parties.contractingprocess_id = $1 limit 1", [localid]),    //4
                    t.one("select * from award where contractingprocess_id = $1", [localid]),           //5
                    t.one("select * from contract where contractingprocess_id = $1", [localid]),     //6
                    t.one('select * from implementation where contractingprocess_id = $1', [localid]), //7
                    t.oneOrNone('select * from parties, roles where roles.parties_id = parties.id and roles.procuringentity = true and parties.contractingprocess_id = $1 limit 1', [localid]), //8
                    t.manyOrNone('select * from parties, roles where parties.id = roles.parties_id and parties.contractingprocess_id=$1', [localid]),
                    t.oneOrNone('select * from tags where contractingprocess_id =$1', [localid])
                ]);

            }).then(function (data) {

                var qp = {
                    cp: data[0],
                    planning: data [1],
                    budget: data [2],
                    tender: data[3],
                    buyer: data [4],
                    award: data[5],
                    contract: data[6],
                    implementation: data[7],
                    procuringentity: data[8],
                    parties: data[9],
                    tags: data[10]
                };

                //queries secundarias
                return t.batch(
                    [
                        qp, //0
                        t.manyOrNone("select * from parties, roles where roles.parties_id = parties.id and roles.tenderer = true and parties.contractingprocess_id=$1", [data[0].id]), //1
                        t.manyOrNone("select * from parties, roles where roles.parties_id = parties.id and roles.supplier = true and parties.contractingprocess_id=$1", [data[0].id]), //2: dependen de awards
                        t.one("select * from publisher where contractingprocess_id=$1",[data[0].id]), //3
                        /* Documents */
                        t.manyOrNone('select * from planningdocuments where contractingprocess_id=$1',[data[0].id]),//4
                        t.manyOrNone('select * from tenderdocuments where contractingprocess_id=$1',[data[0].id]), //5
                        t.manyOrNone('select * from awarddocuments where contractingprocess_id=$1',[data[0].id]), //6
                        t.manyOrNone('select * from contractdocuments where contractingprocess_id=$1', [data[0].id]),//7
                        t.manyOrNone('select * from implementationdocuments where contractingprocess_id=$1 ',[data[0].id]), //8
                        /* Items */
                        t.manyOrNone('select * from tenderitem where contractingprocess_id=$1',[data[0].id]),// 9
                        t.manyOrNone('select * from awarditem where contractingprocess_id=$1',[data[0].id]), //10
                        t.manyOrNone('select * from contractitem where contractingprocess_id=$1',[data[0].id]),//11
                        /* Milestones */
                        t.manyOrNone('select * from tendermilestone where contractingprocess_id=$1',[data[0].id]), //12
                        t.manyOrNone('select * from implementationmilestone where contractingprocess_id=$1',[data[0].id]), //13
                        /* Transactions */
                        t.manyOrNone('select * from implementationtransactions where contractingprocess_id=$1', [data[0].id]), //14
                        /* Amendment changes */
                        t.manyOrNone('select * from tenderamendmentchanges where contractingprocess_id=$1',[data[0].id]), //15
                        t.manyOrNone('select * from awardamendmentchanges where contractingprocess_id=$1',[data[0].id]), //16
                        t.manyOrNone('select * from contractamendmentchanges where contractingprocess_id=$1',[data[0].id]) //17
                    ]);

            }).then(function (data) {

                function checkValue( x ) {
                    return ( x !== null && x !== '' && typeof x !== "undefined");
                }

                function dateString( obj ) {
                    return obj instanceof Date ? obj.toISOString() : obj
                }

                function deleteNullProperties(obj, recursive) {

                    if (Array.isArray(obj) ) {

                        for (let i =0; i< obj.length; i++){
                            if ( typeof obj[i] === 'undefined' || obj[i] === null){
                                obj.splice(i,1);
                            }else if (recursive && typeof obj[i] === 'object'){
                                deleteNullProperties(obj[i], recursive);
                            }
                        }
                    }


                    for (let i in obj) {
                        if (JSON.stringify(obj[i]) === JSON.stringify({}) || JSON.stringify(obj[i]) === JSON.stringify([]) ||
                            obj[i] === null || obj[i] === '' || obj[i] === 'N/A'|| obj[i]=== 'No aplica') {
                            delete obj[i];
                        } else if (recursive && typeof obj[i] === 'object') {
                            deleteNullProperties(obj[i], recursive);

                            //retorno
                            if (JSON.stringify(obj[i]) === JSON.stringify({}) || obj[i] === null || typeof obj[i] === 'undefined' ||
                                JSON.stringify(obj[i]) === JSON.stringify([])){
                                delete obj[i];
                            }

                        }
                    }
                }

                function getParties(array) {
                    var parties = [];
                    for(let p of array) {
                        parties.push({
                            name: p.name,
                            id: p.partyid
                        })
                    }
                    return parties;
                }

                function getFullParties(array){
                    //console.log(array);
                    var parties = [];
                                            
                    for ( var i=0; i < array.length; i++){

 			    var party={};
                    	party.name = {};
                    	party.id = {};
                    	party.naturalPerson = {};
                        party.identifier = {};
                        party.address = {};
                        party.contactPoint = {};
                        party.roles = [];
                        var roles = ["buyer","procuringEntity","supplier","tenderer","guarantor", "enquirer",
                            "payer","payee","reviewBody", "attendee", "official", "invitedSupplier", "issuingSupplier",
							"requestingunit", "contractingunit", "technicalunit", "responsibleunit"];

                        if( checkValue(array[i].naturalperson) ){
				        if(array[i].naturalperson == true) { 
                        		if( checkValue(array[i].name) ){party.name = array[i].name;}
                       			if( checkValue(array[i].naturalperson) ){party.naturalPerson = array[i].naturalperson;}
                       			
                       			for (var x of roles){
		                           if (array[i][x.toLocaleLowerCase()] === true){
		                               party.roles.push(x);
		                           }
		                        }
                        
                       	 }}
                       	 
                       	if( checkValue(array[i].naturalperson) ){
					    if(array[i].naturalperson == false || type === "release-package_all") { 
                       	
                        if( checkValue(array[i].name) ){party.name = array[i].name;}
                        if( checkValue(array[i].partyid) ){party.id = array[i].partyid;}
                        if( checkValue(array[i].naturalperson) ){party.naturalPerson = array[i].naturalperson;}
                        
                        if( checkValue(array[i].identifier_scheme)  ){party.identifier.scheme = array[i].identifier_scheme;}
                        if( checkValue(array[i].identifier_id) ){party.identifier.id = array[i].identifier_id;}
                        if( checkValue(array[i].identifier_legalname) ){party.identifier.legalName = array[i].identifier_legalname;}
                        if( checkValue(array[i].identifier_uri) ){party.identifier.uri = array[i].identifier_uri;}
                   
                        if( checkValue(array[i].address_streetaddress) ){party.address.streetAddress = array[i].address_streetaddress;}
                        if( checkValue(array[i].address_locality) ){party.address.locality = array[i].address_locality;}
                        if( checkValue(array[i].address_region) ){party.address.region = array[i].address_region;}
                        if( checkValue(array[i].address_postalcode) ){party.address.postalCode = array[i].address_postalcode;}
                        if( checkValue(array[i].address_countryname) ){party.address.countryName = array[i].address_countryname;}
                     
                        if( checkValue(array[i].contactpoint_name) ){party.contactPoint.name = array[i].contactpoint_name;}
                        if( checkValue(array[i].contactpoint_email) ){party.contactPoint.email = array[i].contactpoint_email;}
                        if( checkValue(array[i].contactpoint_telephone) ){party.contactPoint.telephone = array[i].contactpoint_telephone;}
                        if( checkValue(array[i].contactpoint_faxnumber) ){party.contactPoint.faxNumber = array[i].contactpoint_faxnumber;}
                        if( checkValue(array[i].contactpoint_url) ){party.contactPoint.url = array[i].contactpoint_url;}
                                                                        
                        for (var x of roles){
                           if (array[i][x.toLocaleLowerCase()] === true){
                               party.roles.push(x);
                           }
                        }
                        
			    }} //cerrando else

                        deleteNullProperties(party, true);
                        if ( party !== null ) {
                            parties.push(party);
                        }

                    }
                    return parties;
                }


                function getDocuments(array){
                    var documents =[];
                    for (var i=0; i < array.length; i++ ){
                        var document = { };

                        if(checkValue(array[i].documentid)){document.id = array[i].documentid;}
                        if(checkValue(array[i].document_type)){document.documentType = array[i].document_type;}
                        if(checkValue(array[i].title)){document.title = array[i].title;}
                        if(checkValue(array[i].description)){document.description = array[i].description;}
                        if(checkValue(array[i].url)){document.url = array[i].url;}
                        if(checkValue(array[i].date_published)){document.datePublished = dateString(array[i].date_published);}
                        if(checkValue(array[i].date_modified)){document.dateModified = dateString(array[i].date_modified);}
                        if(checkValue(array[i].format)){document.format = array[i].format;}
                        if(checkValue(array[i].language)){document.language = array[i].language;}

                        deleteNullProperties(document, true);

                        documents.push(document);
                    }
                    return documents;
                }

                function getItems(arr){
                    var items =[];
                    for (var i=0; i < arr.length;i++){
                        var item = { };
                        if(checkValue(arr[i].itemid)){item.id = arr[i].itemid;}
                        if(checkValue(arr[i].description)){item.description = arr[i].description;}
                        //additionalClasifications: [ ],

                        item.classification = { };
                        if(checkValue(arr[i].classification_scheme)){item.classification.scheme = arr[i].classification_scheme;}
                        if(checkValue(arr[i].classification_id)){item.classification.id = arr[i].classification_id;}
                        if(checkValue(arr[i].classification_description)){item.classification.description = arr[i]. classification_description;}
                        if(checkValue(arr[i].classification_uri)){item.classification.uri = arr[i].classification_uri;}

                        if(checkValue(arr[i].quantity)){item.quantity = arr[i].quantity;}

                        item.unit = { };
                        if(checkValue(arr[i].unit_name)){item.unit.name = arr[i].unit_name;}
                        item.unit.value = { };
                        if(checkValue(arr[i].unit_value_amountnet)){item.unit.value.amountnet = Number(arr[i].unit_value_amountnet);}
                        if(checkValue(arr[i].unit_value_amount)){item.unit.value.amount = Number(arr[i].unit_value_amount);}
                        if(checkValue(arr[i].unit_value_currency)){item.unit.value.currency = arr[i].unit_value_currency;}

                        deleteNullProperties(item, true);

                        items.push(item);
                    }
                    return items;
                }

                function getMilestones(arr) {
                    var milestones =[];
                    for (var i=0; i < arr.length;i++){
                        var milestone = { };

                        if(checkValue(arr[i].milestoneid)){milestone.id = arr[i].milestoneid;}
                        if(checkValue(arr[i].title)){milestone.title = arr[i].title;}
                        if(checkValue(arr[i].description)){milestone.description = arr[i].description;}
                        if(checkValue(arr[i].duedate)){milestone.dueDate = dateString(arr[i].duedate);}
                        if(checkValue(arr[i].date_modified)){milestone.dateModified = dateString(arr[i].date_modified);}
                        if(checkValue(arr[i].status)){milestone.status = arr[i].status;}

                        deleteNullProperties(milestone, true);

                        milestones.push(milestone);
                    }
                    return milestones;
                }

                function getTransactions( arr ){
                    var transactions = [];

                    for (var i =0; i< arr.length;i++){
                        var transaction = { };
                        transaction.id = arr[i].transactionid;

                        if(checkValue(arr[i].source)){transaction.source = arr[i].source;}
                        if(checkValue(arr[i].date)){transaction.date = dateString(arr[i].date);}

                        transaction.value = { };
                        if(checkValue(arr[i].value_amountnet)){transaction.value.amountnet = Number(arr[i].value_amountnet);}
                        if(checkValue(arr[i].value_amount)){transaction.value.amount = Number(arr[i].value_amount);}
                        if(checkValue(arr[i].value_currency)){transaction.value.currency = arr[i].value_currency;}
                        
                        if(checkValue(arr[i].payment_method)){transaction.paymentMethod = arr[i].payment_method;}
                   
                        transaction.payer = { };
                        if(checkValue(arr[i].payer_name)){transaction.payer.name = arr[i].payer_name;}
                        if(checkValue(arr[i].payer_id)){transaction.payer.id = arr[i].payer_id;}
                        
                        transaction.payee = { };
                        if(checkValue(arr[i].payee_name)){transaction.payee.name = arr[i].payee_name;}
                        if(checkValue(arr[i].payee_id)){transaction.payee.id = arr[i].payee_id;}
                        
                        if(checkValue(arr[i].uri)){transaction.uri = arr[i].uri;}

                        deleteNullProperties(transaction, true);

                        transactions.push(transaction);
                    }
                    return transactions;
                }

                function getAmendments( arr ){
                    var changes = [];
                    for (var i=0; i < arr.length;i++){
                        changes.push({
                            date: arr[i].amendments_date,
                            rationale: arr[i].amendments_rationale,
                            id: arr[i].amendments_id,
                            description: arr[i].amendments_description
                        });
                    }
                    return changes;
                }

                let tags = [];
                for (var t in data[0].tags){
                    if (data[0].tags[t] === true){
                        switch (t){
                            case "planning":
                                tags.push("planning");
                                break;
                            case "planningupdate":
                                tags.push("planningUpdate");
                                break;
                            case "tender":
                                tags.push("tender");
                                break;
                            case "tenderamendment":
                                tags.push("tenderAmendment");
                                break;
                            case "tenderupdate":
                                tags.push("tenderUpdate");
                                break;
                            case "tendercancellation":
                                tags.push("tenderCancellation");
                                break;
                            case "award":
                                tags.push("award");
                                break;
                            case "awardupdate":
                                tags.push("awardUpdate");
                                break;
                            case "awardcancellation":
                                tags.push("awardCancellation");
                                break;
                            case "contract":
                                tags.push("contract");
                                break;
                            case "contractupdate":
                                tags.push("contractUpdate");
                                break;
                            case "contractamendment":
                                tags.push("contractAmendment");
                                break;
                            case "implementation":
                                tags.push("implementation");
                                break;
                            case "implementationupdate":
                                tags.push("implementationUpdate");
                                break;
                            case "contracttermination":
                                tags.push("contractTermination");
                                break;
                            case "compiled":
                                tags.push("compiled");
                                break;
                        }
                    }
                }

                //RELEASE METADATA
                var release = {
                    registry: data[0].cp.id,
                    ocid: String(data[0].cp.ocid),
                    id: "RELEASE_" + data[0].cp.ocid + "_" + (new Date()).toISOString(),
                    date: dateString( data[0].cp.fecha_creacion ),
                    tag: tags,
                    initiationType: "tender"
                };

                release.parties = getFullParties(data[0].parties);

                //requestingunit antes BUYER
                if (data[0].requestingunit !== null){
                    release.requestingunit = {
                        name: data[0].requestingunit.name,
                        id: data[0].requestingunit.partyid
                    }
                }

                //PLANNING
                release.planning = { };

                release.planning.budget = { };
                if (checkValue(data[0].budget.budget_source)){release.planning.budget.source = data[0].budget.budget_source;}
                if (checkValue(data[0].budget.budget_budgetid)){release.planning.budget.id = data[0].budget.budget_budgetid;}
                if (checkValue(data[0].budget.budget_description)){release.planning.budget.description = data[0].budget.budget_description;}

                release.planning.budget.amount = { };
                if (checkValue(data[0].budget.budget_amount)){release.planning.budget.amount.amount = Number(data[0].budget.budget_amount);}
                if (checkValue(data[0].budget.budget_currency)){release.planning.budget.amount.currency = data[0].budget.budget_currency;}

                if (checkValue(data[0].budget.budget_project)){release.planning.budget.project = data[0].budget.budget_project;}
                if (checkValue(data[0].budget.budget_projectid)){release.planning.budget.projectID = data[0].budget.budget_projectid;}
                if (checkValue(data[0].budget.budget_uri)){release.planning.budget.uri = data[0].budget.budget_uri;}

                if (checkValue(data[0].planning.rationale)){release.planning.rationale = data[0].planning.rationale;}
                if (checkValue(data[0].planning.hasquotes)){release.planning.hasquotes = data[0].planning.hasquotes;}
                if (checkValue(data[0].planning.numberofbeneficiaries)){release.planning.numberofbeneficiaries = data[0].planning.numberofbeneficiaries;}

                //planning documents
                if (data[4].length > 0){
                    release.planning.documents = getDocuments(data[4])
                }

                //Limpia la etapa de planeación
                deleteNullProperties(release.planning, true);

                // planning == {} -> eliminar
                if (JSON.stringify(release.planning) === JSON.stringify({})){
                    delete release['planning'];
                }

                //TENDER
                release.tender = { };
                if(checkValue(data[0].tender.tenderid)){release.tender.id = data[0].tender.tenderid;}
                if(checkValue(data[0].tender.title)){release.tender.title = data[0].tender.title;}
                if(checkValue(data[0].tender.description)){release.tender.description = data[0].tender.description;}
                if(checkValue(data[0].tender.status)){release.tender.status = data[0].tender.status;}

                //Tender -> items
                if (data[9].length > 0) {
                    release.tender.items = getItems(data[9]);
                }

                release.tender.minValue = { };
                if(checkValue(data[0].tender.minvalue_amount)){release.tender.minValue.amount = Number (data[0].tender.minvalue_amount);}
                if(checkValue(data[0].tender.minvalue_currency)){release.tender.minValue.currency = data[0].tender.minvalue_currency;}

                release.tender.value = { };
                if(checkValue(data[0].tender.value_amount)){release.tender.value.amount = Number (data[0].tender.value_amount);}
                if(checkValue(data[0].tender.value_currency)){release.tender.value.currency = data[0].tender.value_currency;}


                function pm ( method ) {

                    var proc ='';

                    switch (method){

                        case 'Licitación pública':
                            proc = 'Licitación pública';
                            break;
                        case 'Invitación a cuando menos tres personas':
                            proc = 'Invitación a cuando menos tres personas';
                            break;
                        case 'Adjudicación directa':
                            proc = 'Adjudicación directa';
                            break;
                    }

                    return proc;

                }

		//metodo de adquisición
                if(checkValue(data[0].tender.procurementmethod)){release.tender.procurementMethod = data[0].tender.procurementmethod;}
                if(checkValue(data[0].tender.procurementmethod_details)){release.tender.procurementMethodDetails = pm(data[0].tender.procurementmethod_details);}
                
                if(checkValue(data[0].tender.procurementmethod_rationale)){release.tender.procurementMethodRationale = data[0].tender.procurementmethod_rationale;}
        
        
        function apc ( method ) {

                    var croc ='';

                    switch (method){
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
                    }
                    return croc;
                }
                       
		//Destino de contratación
                if(checkValue(data[0].tender.mainprocurementcategory)){release.tender.mainProcurementCategory = data[0].tender.mainprocurementcategory;}
                if(checkValue(data[0].tender.additionalprocurementcategories)){release.tender.additionalProcurementCategories = [ apc (data[0].tender.additionalprocurementcategories) ];}
          
                if(checkValue(data[0].tender.awardcriteria)){release.tender.awardCriteria = data[0].tender.awardcriteria;}
                if(checkValue(data[0].tender.awardcriteria_details)){release.tender.awardCriteriaDetails = data[0].tender.awardcriteria_details;}

                if(checkValue(data[0].tender.submissionmethod)){release.tender.submissionMethod = [ data[0].tender.submissionmethod ];}
                if(checkValue(data[0].tender.submissionmethod_details)){release.tender.submissionMethodDetails = data[0].tender.submissionmethod_details;}

                release.tender.tenderPeriod = { };
                if(checkValue(data[0].tender.tenderperiod_startdate)){release.tender.tenderPeriod.startDate = dateString(data[0].tender.tenderperiod_startdate);}
                if(checkValue(data[0].tender.tenderperiod_enddate)){release.tender.tenderPeriod.endDate = dateString(data[0].tender.tenderperiod_enddate);}

                release.tender.enquiryPeriod = { };
                if(checkValue(data[0].tender.enquiryperiod_startdate)){release.tender.enquiryPeriod.startDate = dateString(data[0].tender.enquiryperiod_startdate);}
                if(checkValue(data[0].tender.enquiryperiod_enddate)){release.tender.enquiryPeriod.endDate = dateString(data[0].tender.enquiryperiod_enddate);}

                if(checkValue(data[0].tender.hasenquiries)){release.tender.hasEnquiries = data[0].tender.hasenquiries;}
                if(checkValue(data[0].tender.eligibilitycriteria)){release.tender.eligibilityCriteria = data[0].tender.eligibilitycriteria;}

                release.tender.awardPeriod = { };
                if(checkValue(data[0].tender.tenderperiod_startdate)){release.tender.awardPeriod.startDate = dateString(data[0].tender.tenderperiod_startdate);}
                if(checkValue(data[0].tender.tenderperiod_enddate)){release.tender.awardPeriod.endDate = dateString(data[0].tender.tenderperiod_enddate);}

                if(checkValue(data[0].tender.numberoftenderers)){release.tender.numberOfTenderers = data[0].tender.numberoftenderers;}

                if (data[1].length > 0) {
                    release.tender.tenderers = getParties(data[1]);
                }

                // Tender -> procuring entity
             if (data[0].procuringentity !== null) {
                 release.tender.procuringEntity = {
                     name: data[0].procuringentity.name,
                     id: data[0].procuringentity.partyid
                 };
             }


                if( data[5].length > 0) {
                    release.tender.documents = getDocuments(data[5]);
                }
                if (data[12].length > 0 ) {
                    release.tender.milestones = getMilestones(data[12]);
                }

                release.tender.amendments=[];
                let tender_amendment = { };
                if(checkValue(data[0].tender.amendment_date)){tender_amendment.date = dateString(data[0].tender.amendment_date);}


                if( data[15].length > 0 ) {
                    tender_amendment.changes = getAmendmentChanges(data[15]);
                }

                if (checkValue(data[0].tender.amendment_rationale)){tender_amendment.rationale = data[0].tender.amendment_rationale;}

                if (JSON.stringify(tender_amendment)!==JSON.stringify({})){
                    release.tender.amendments.push(tender_amendment);
                }else{
                    delete release.tender.amendments;
                }

                //limpia la etapa de licitación
                deleteNullProperties( release.tender, true );

                if (JSON.stringify(release.tender) === JSON.stringify({})){
                    delete release.tender;
                }

                //AWARDS
                var award =  { };
                if(checkValue(data[0].award.awardid)){award.id = data[0].award.awardid;}
                if(checkValue(data[0].award.title)){award.title = data[0].award.title;}
                if(checkValue(data[0].award.description)){award.description = data[0].award.description;}
                if(checkValue(data[0].award.status)){award.status = data[0].award.status;}
                if(checkValue(data[0].award.award_date)){award.date = dateString(data[0].award.award_date);}

                award.value = { };
                if(checkValue(data[0].award.value_amountnet)){award.value.amountnet = Number(data[0].award.value_amountnet);}
                if(checkValue(data[0].award.value_amount)){award.value.amount = Number(data[0].award.value_amount);}
                if(checkValue(data[0].award.value_currency)){award.value.currency = data[0].award.value_currency;}


                if (data[2].length > 0) {
                    award.suppliers = getParties(data[2]); //pueden pertenecer a diferentes awards
                }

                if (data[10].length > 0) {
                    award.items = getItems(data[10]);
                }

                award.contractPeriod = { };
                if(checkValue(data[0].award.contractperiod_startdate)){award.contractPeriod.startDate = dateString(data[0].award.contractperiod_startdate);}
                if(checkValue(data[0].award.contractperiod_enddate)){award.contractPeriod.endDate = dateString(data[0].award.contractperiod_enddate);}

                if (data[6].length > 0) {
                    award.documents = getDocuments(data[6]);
                }

                award.amendments = [];
                    let award_amendment = { };
                if(checkValue(data[0].award.amendment_date)){award_amendment.date = dateString(data[0].award.amendment_date);}


                if (data[16].length > 0) {
                    award_amendment.changes = getAmendmentChanges(data[16]);
                }

                if(checkValue(data[0].award.amendment_rationale)){award_amendment.rationale = data[0].award.amendment_rationale;}

                if (JSON.stringify(award_amendment) !== JSON.stringify({})){
                    award.amendments.push(award_amendment);
                }else{
                    delete award.amendments;
                }

                //limpia la adjudicación
                deleteNullProperties( award, true );

                if (JSON.stringify(award) !== JSON.stringify({})){
                    release.awards = [ award ];
                }

                //CONTRACTS
                var contract = { };//pueden ser varios

                if(checkValue(data[0].contract.contractid)){contract.id = data[0].contract.contractid;}
                if(checkValue(data[0].contract.awardid)){contract.awardID = String(data[0].contract.awardid);}
                if(checkValue(data[0].contract.title)){contract.title = data[0].contract.title;}
                if(checkValue(data[0].contract.description)){contract.description = data[0].contract.description;}
                if(checkValue(data[0].contract.status)){contract.status = data[0].contract.status;}

                contract.period = { };
                if(checkValue(data[0].contract.period_startdate)){contract.period.startDate = dateString(data[0].contract.period_startdate);}
                if(checkValue(data[0].contract.period_enddate)){contract.period.endDate = dateString(data[0].contract.period_enddate);}

                contract.value = { };
                if(checkValue(data[0].contract.value_amountnet)){contract.value.amountnet = Number(data[0].contract.value_amountnet);}
                if(checkValue(data[0].contract.value_amount)){contract.value.amount = Number(data[0].contract.value_amount);}
                if(checkValue(data[0].contract.value_currency)){contract.value.currency = data[0].contract.value_currency;}
				
				contract.exchangeRate = { };
				if(checkValue(data[0].contract.exchangerate_rate)){contract.exchangeRate.rate = Number(data[0].contract.exchangerate_rate);}
				if(checkValue(data[0].contract.exchangerate_currency)){contract.exchangeRate.currency = data[0].contract.exchangerate_currency;}
				if(checkValue(data[0].contract.exchangerate_date)){contract.exchangeRate.date = dateString(data[0].contract.exchangerate_date);}
                if(checkValue(data[0].contract.exchangerate_source)){contract.exchangeRate.source = data[0].contract.exchangerate_source;}
                
                if (data[11].length > 0) {
                    contract.items = getItems(data[11]);
                }

                if(checkValue(data[0].contract.datesigned)){contract.dateSigned = dateString(data[0].contract.datesigned);}

                if (data[7].length > 0) {
                    contract.documents = getDocuments(data[7]);
                }

                contract.amendments=[];
                let contract_amendment = { };

                if (data[17].length > 0) {
                    contract_amendment.changes = getAmendments(data[17]);
                }

	   	        if (JSON.stringify(contract_amendment) !== JSON.stringify({})){
                    contract.amendments.push(contract_amendment);
                }else {
                    delete contract.amendments;
                }
                
              	contract.implementation = { };                 
                
               		if (data[0].implementation.status !== null ) {
	              		contract.implementation.status = data[0].implementation.status;
	                }
	                                
	                if (data[8].length > 0) {
	                    contract.implementation.documents = getDocuments(data[8]);
	                }
	                 
	                if (data[14].length > 0) {
	                    
	                    contract.implementation.transactions = getTransactions(data[14]);
	                }
	
	                if (data[13].length > 0) {
	                    contract.implementation.milestones = getMilestones(data[13]);
	                }
	
	            //limpia: Contract -> implementation
	                deleteNullProperties( contract, true );
	
	                if (JSON.stringify(contract) !== JSON.stringify({})){
	                    release.contracts = [ contract ];
	                }				
                             
                release.language = 'es';

                if (type === "release-package" || type === "release-package_all"){

                    var publisher = {
                        name: data[3].name,
                        scheme: data[3].scheme,
                        uid: data[3].uid,
                        uri: data[3].uri
                    };

                    deleteNullProperties(publisher, true);


                    var release_package = {};

                    release_package.uri = data[0].cp.uri;
                    release_package.version = "1.1";
                    release_package.publishedDate = (new Date()).toISOString();//getMString(new Date()),
                    release_package.releases = [ release ];
                    release_package.publisher = publisher;
                    release_package.license = data[0].cp.license;
                    release_package.publicationPolicy = data[0].cp.publicationpolicy;
                    release_package.localid  = localid;

                    deleteNullProperties(release_package, false);

                    return release_package;
                }     
                    
                release.localid = localid;
                return release ;

            })
        });
    }
};
