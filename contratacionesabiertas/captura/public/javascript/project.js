// modelos para infraestructura
const db = require('../../models');
// PostgreSQL database
var db_conf = require('../../db_conf');
// moment format
var moment = require('moment'); // require
const { isNotNullOrEmpty } = require('../../utilities/validation-rules');

module.exports = {
    createPublisher: async function(user){
        var publisher = null;
        if(user.isAdmin){
            try {
                publisher = await db.edcapi_publisher.create({
                    name : 'Administrador',
                    scheme :  'Administrador',
                    uid : 'Administrador',
                    uri :  'N/A',
                    createdAt : new Date(),
                    updatedAt : new Date()
                });    
            } catch (error) {
                console.log("ERROR in fuction - createPublisher: " + error);
            }
        }else{
            try {
                publisher = await db.edcapi_publisher.create({
                    name : user.publisherName,
                    scheme :  user.publisherScheme,
                    uid : user.publisherUid,
                    uri :  user.publisherUri,
                    createdAt : new Date(),
                    updatedAt : new Date()
                });    
            } catch (error) {
                console.log("ERROR in fuction - createPublisher: " + error);
            }
        }
        return publisher;
    },
    generateOc4ids:async function (){
        console.log("$$$$ generateOc4ids")
        var prefix = await db.edcapi_project_prefix.findAll({attributes: ['prefix']});
        return prefix;
    },
    createProjectPackage: async function(metaData){
        console.log("### METADATA " + JSON.stringify(metaData))
        try {
            const projectPackage = await db.edcapi_project_package.create({
                uri : '', 
                publishedDate : '',
                version : '0.9.1',
                license : metaData.length === 0 ? 'N/A' : metaData[0].value,
                publicationPolicy : metaData.length === 0 ? 'N/A' : metaData[1].value,
                createdAt : new Date(),
                updatedAt : new Date()
            });
            return projectPackage;
        } catch (error) {
            console.log("ERROR in fuction - createProjectPackage: " + error);
        }
    },
    createPublisherProjectPackage: async function(publisher,projectPackage){
        if(publisher !== undefined && projectPackage !== undefined){
            try {
                const relPublisherProjectPackage = await db.edcapi_publisher_project_package.create({
                    edcapiPublisherId :  publisher,
                    project_package_id : projectPackage,
                    createdAt : new Date(),
                    updatedAt : new Date()
                });
                return relPublisherProjectPackage;    
            } catch (error) {
                console.log("ERROR in fuction - createPublisherProjectPackage:" + error)
            }
        }
        return false;
    },
    createProject: async function(){
        try {
            const project = await db.edcapi_project.create({
                createdAt : new Date(),
                updatedAt : new Date()
            });
            return project;    
        } catch (error) {
            console.log("ERROR in fuction - createProject: " + error)
        }
    },
    createProjectPackageProject: async function(project,projectPackage, host){
        if(project !== undefined && projectPackage !== undefined){
            try {
                const relProjectPackageProject = await db.edcapi_project_package_project.create({
                    project_package_id: projectPackage,
                    project_id: project,  
                    createdAt : new Date(),
                    updatedAt : new Date()
                })    
                await db.edcapi_project_package.findByPk(projectPackage).then(function(value){
                    value.update({
                        uri : host+"/edcapi/projectPackage/"+project, 
                        updatedAt : new Date()
                    });
                });
            return relProjectPackageProject;    
        } catch (error) {
            console.log("ERROR in fuction - createProjectPackageProject:" + error)
        }
    }
    return false;
    },
    insertProject: async function(data){
        console.log("$$$$ insertProject")
        var obj = JSON.parse(data);
        var relProjectPeriodProject = new db.edcapi_project_period_project();
        var relProjectAssetLifetimeProject = new db.edcapi_project_asset_lifetime_project();
        var relBudgetProject = new db.edcapi_budget_project();
        var relBudgetAmount = new db.edcapi_budget_amount_budget();
        var period = new db.edcapi_project_period();
        var amount = new db.edcapi_budget_amount();
        var assetLifetime = new db.edcapi_project_asset_lifetime();
        var budget = new db.edcapi_budget();
        var project = await db.edcapi_project.findByPk(obj.project_id);
        var prefix = await db.edcapi_project_prefix.findByPk(1);

        period = await db.edcapi_project_period.create({
            startDate : (obj.period_startDate === '' ? null : obj.period_startDate),
            endDate : (obj.period_endDate === '' ? null : obj.period_endDate),
            maxExtentDate : (obj.period_maxExtentDate === '' ? null : obj.period_maxExtentDate),
            durationInDays : (obj.period_durationInDays === '' ? null : obj.period_durationInDays),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(period){
            console.log("############## PERIOD -" + JSON.stringify(period, null, 4))
            return relProjectPeriodProject = await db.edcapi_project_period_project.create({
                project_id: obj.project_id,
                project_period_id: period.id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relProjectPeriodProject){
                console.log("############## REL_PERIOD_PROJECT - " + JSON.stringify(relProjectPeriodProject, null, 4))   
                var arraySector = new Array();
                    if(Array.isArray(obj.sector)){
                        console.log("si es un array")
                        arraySector = obj.sector;
                    }else if(obj.sector === '') {
                        console.log("es vacio")
                    }else{
                        console.log("es un string")
                        arraySector.push(obj.sector);
                    } 
                return project.update({
                    oc4ids:  prefix.prefix,
                    identifier: (obj.id === '' ? null : obj.id),
                    updated: new Date(),
                    title: (obj.title === '' ? null : obj.title),
                    description: (obj.description === '' ? null : obj.description),
                    status: (obj.status === '' ? null : obj.status),
                    purpose: (obj.purpose === '' ? null : obj.purpose),
                    sector: (arraySector < 0 ? null : arraySector),
                    type: (obj.type === '' ? null : obj.type),
                    oc4idsIdentifier: (obj.id === '' ? null : prefix.prefix + "-" + obj.id),
                    updatedAt : new Date()
                });
            }).then(async function(project){
                console.log("############## PROJECT - " + JSON.stringify(project, null, 4))                
                return assetLifetime = await db.edcapi_project_asset_lifetime.create({
                    startDate : (obj.assetLifetime_startDate === '' ? null : obj.assetLifetime_startDate),
                    endDate : (obj.assetLifetime_endDate === '' ? null : obj.assetLifetime_endDate),
                    maxExtentDate : (obj.assetLifetime_maxExtentDate === '' ? null : obj.assetLifetime_maxExtentDate),
                    durationInDays : (obj.assetLifetime_durationInDays === '' ? null : obj.assetLifetime_durationInDays),
                    createdAt : new Date(),
                    updatedAt : new Date()
                });
            }).then(async function(assetLifetime){
                console.log("############## ASSET LIFE TIME - " + JSON.stringify(assetLifetime, null, 4))                
                return relProjectAssetLifetimeProject = await db.edcapi_project_asset_lifetime_project.create({
                    project_id: obj.project_id,
                    edcapiProjectAssetLifetimeId: assetLifetime.id,
                    createdAt : new Date(),
                    updatedAt : new Date()
                });
            }).then(async function(relProjectAssetLifetimeProject){
                console.log("############## REL ASSET LIFE TIME - " + JSON.stringify(relProjectAssetLifetimeProject, null, 4))                
                return budget = await db.edcapi_budget.create({
                    requestDate: (obj.budget_requestDate === '' ? null : obj.budget_requestDate),
                    approvalDate: (obj.budget_approvalDate === '' ? null : obj.budget_approvalDate),
                    createdAt : new Date(),
                    updatedAt : new Date()
                });
            }).then(async function(budget){
                console.log("############## BUDGET - " + JSON.stringify(budget, null, 4))                
                return relBudgetProject = await db.edcapi_budget_project.create({
                    project_id: obj.project_id,
                    edcapiBudgetId: budget.id,
                    createdAt : new Date(),
                    updatedAt : new Date()
                });
            }).then(async function(relBudgetProject){
                console.log("############## REL BUDGET PROJECT - " + JSON.stringify(relBudgetProject, null, 4))       
                console.log("############## X1 ")       
                    amount = await db.edcapi_budget_amount.create({
                        amount: (obj.budget_amount_amount === '' ? null : obj.budget_amount_amount),
                        currency: (obj.budget_amount_amount === '' ? null : obj.budget_amount_currency),
                        createdAt : new Date(),
                        updatedAt : new Date()
                    })
                    .then(async function(amount){
                        console.log("############## AMOUNT - " + JSON.stringify(amount, null, 4))      
                        console.log("############## X2 ")
                        relBudgetAmount = await db.edcapi_budget_amount_budget.create({
                            budget_id: relBudgetProject.edcapiBudgetId,
                            edcapiBudgetAmountId: amount.id,                    
                            createdAt : new Date(),
                            updatedAt : new Date()
                        });
                    })
                return true;
            });
        }); 
        console.log("############## REL BUDGET AMOUNT - " + JSON.stringify(relBudgetAmount,null,4))       
        
    },
    imprimeProjectPackage: async function(projectID,arrayContractingProcesses,isProjectPackage){
        return findProjects(projectID).then(value =>{
            var objProjectPackage = new Object();
            var objPublisher = new Object();
            var objProject = new Object();
            var objPeriod  = new Object();
            var objAssetLifetime = new Object();
            var objBudget = new Object();
            var objAmount = new Object();
            var arrayParties = new Array();
            var arrayAdditionalClassifications = new Array();
            var arrayDocumentsProject = new Array();
            var arrayRelatedProjects = new Array();
            var arrayLocationProjects = new Array();
            var arrayBudgetBreakdown = new Array();
            var objCompletion  = new Object();
            var objFinalValue  = new Object();
            
            if(value[0].projects[0].locations !== undefined){
                value[0].projects[0].locations.forEach(element => {
                    var objLocationProject = new Object();
                    var objGeometry = new Object();
                    var objAddress = new Object();
                    var arrayCoordinates = new Array();
                    if(element.id !== "" && element.id !== null)
                    objLocationProject.id = String(element.id);
                    if(element.description !== "" && element.description !== null)
                    objLocationProject.description = element.description;
                    if(element.type !== "" && element.type !== null)
                    objGeometry.type = element.type;
                    if(element.coordinates !== undefined){
                        element.coordinates.forEach(element => {
                            if(element.point !== "" && element.point !== null)
                            arrayCoordinates.push(element.point);
                        });
                    }
                    if(arrayCoordinates.length > 0)
                    objGeometry.coordinates = arrayCoordinates;
                    if(Object.entries(objGeometry).length !== 0)
                    objLocationProject.geometry = objGeometry;
                    if(element.address !== undefined){
                        element.address.forEach(element => {
                            if(element.streetAddress !== "" && element.streetAddress !== null)
                            objAddress.streetAddress = element.streetAddress;
                            if(element.locality !== "" && element.locality !== null)
                            objAddress.locality = element.locality;
                            if(element.region !== "" && element.region !== null)
                            objAddress.region = element.region;
                            if(element.postalCode !== "" && element.postalCode !== null)
                            objAddress.postalCode = element.postalCode;
                            if(element.countryName !== "" && element.countryName !== null)
                            objAddress.countryName = element.countryName;
                        });
                    }
                    if(Object.entries(objAddress).length !== 0)
                    objLocationProject.address = objAddress;
                    arrayLocationProjects.push(objLocationProject);
                })
            }

            if(value[0].projects[0].documents !== undefined){
                value[0].projects[0].documents.forEach(element => {
                    var objDocumentProject = new Object();
                    if(element.id !== "" && element.id !== null)
                    objDocumentProject.id = String(element.id);
                    if(element.documentType !== "" && element.documentType !== null)
                    objDocumentProject.documentType = element.documentType;
                    if(element.title !== "" && element.title !== null)
                    objDocumentProject.title = element.title;
                    if(element.description !== "" && element.description !== null)
                    objDocumentProject.description = element.description;
                    if(element.url !== "" && element.url !== null)
                    objDocumentProject.url = element.url;
                    if(element.datePublished !== "" && element.datePublished !== null)
                    objDocumentProject.datePublished = dateFortmatGMT(element.datePublished);
                    if(element.dateModified !== "" && element.dateModified !== null)
                    objDocumentProject.dateModified = dateFortmatGMT(element.dateModified);
                    if(element.format !== "" && element.format !== null)
                    objDocumentProject.format = element.format;
                    if(element.language !== "" && element.language !== null)
                    objDocumentProject.language = element.language;
                    if(element.pageStart !== "" && element.pageStart !== null)
                    objDocumentProject.pageStart = String(element.pageStart);
                    if(element.pageEnd !== "" && element.pageEnd !== null)
                    objDocumentProject.pageEnd = String(element.pageEnd);
                    if(element.accessDetails !== "" && element.accessDetails !== null)
                    objDocumentProject.accessDetails = element.accessDetails;
                    if(element.author !== "" && element.author !== null)
                    objDocumentProject.author = element.author;
                    arrayDocumentsProject.push(objDocumentProject);
                })
            }

            if(value[0].projects[0].additionalClassifications !== undefined){
                value[0].projects[0].additionalClassifications.forEach(element => {
                    var objAdditionalClassification = new Object();
                    if(element.schema !== "" && element.schema !== null)
                    objAdditionalClassification.scheme = element.schema;
                    if(element.identifier !== "" && element.identifier !== null)
                    objAdditionalClassification.id = element.identifier;
                    if(element.description !== "" && element.description !== null)
                    objAdditionalClassification.description = element.description;
                    arrayAdditionalClassifications.push(objAdditionalClassification);
                })
            }

            if(value[0].projects[0].relatedProjects !== undefined){
                value[0].projects[0].relatedProjects.forEach(element => {
                    var objRelatedProjects = new Object();
                    var arrayRelationship = new Array();
                    if(element.id !== "" && element.id !== null)
                    objRelatedProjects.id = String(element.id);
                    if(element.relationship !== "" && element.relationship !== null)
                    arrayRelationship.push(element.relationship)
                    if(element.relationship !== "" && element.relationship !== null)
                    objRelatedProjects.relationship = arrayRelationship;
                    if(element.identifier !== "" && element.identifier !== null)
                    objRelatedProjects.title = element.identifier;
                    if(element.scheme !== "" && element.scheme !== null)
                    objRelatedProjects.scheme = element.scheme;
                    if(element.title !== "" && element.title !== null)
                    objRelatedProjects.identifier = element.title;
                    if(element.uri !== "" && element.uri !== null)
                    objRelatedProjects.uri = element.uri;
                    arrayRelatedProjects.push(objRelatedProjects);
                })
            }

            if(value[0].projects[0].parties !== undefined){
                value[0].projects[0].parties.forEach(element => {
                    //Identifier
                    var objIdentifier = new Object();
                    var objParty = new Object();
                    var objAddress = new Object();
                    var objContactPoint = new Object();
                    var arrayRoles = new Array();
                    var arrayAdditionalIdentifiers = new Array();
                    if(element.identifierR[0].scheme !== "" && element.identifierR[0].scheme !== null)
                    objIdentifier.scheme = element.identifierR[0].scheme;
                    if(element.identifierR[0].identifier !== "" && element.identifierR[0].identifier !== null)
                    objIdentifier.id = element.identifierR[0].identifier;
                    if(element.identifierR[0].legalName !== "" && element.identifierR[0].legalName !== null)
                    objIdentifier.legalName = element.identifierR[0].legalName;
                    if(element.identifierR[0].uri !== "" && element.identifierR[0].uri !== null)
                    objIdentifier.uri = element.identifierR[0].uri;
                    //AdditionalIdentifier
                    if(element.additionalIdentifiers !== undefined){
                        element.additionalIdentifiers.forEach(element => {
                            var objIdentifier = new Object();
                            if(element.scheme !== "" && element.scheme !== null)
                            objIdentifier.scheme = element.scheme;
                            if(element.id !== "" && element.id !== null)
                            objIdentifier.id = element.identifier;
                            if(element.legalName !== "" && element.legalName !== null)
                            objIdentifier.legalName = element.legalName;
                            if(element.uri !== "" && element.uri !== null)
                            objIdentifier.uri = element.uri;
                            arrayAdditionalIdentifiers.push(objIdentifier);
                        });
                    }
                    //Address
                    if(element.address[0].streetAddress !== "" && element.address[0].streetAddress !== null)
                    objAddress.streetAddress = element.address[0].streetAddress;
                    if(element.address[0].locality !== "" && element.address[0].locality !== null)
                    objAddress.locality = element.address[0].locality;
                    if(element.address[0].region !== "" && element.address[0].region !== null)
                    objAddress.region = element.address[0].region;
                    if(element.address[0].postalCode !== "" && element.address[0].postalCode !== null)
                    objAddress.postalCode = element.address[0].postalCode;
                    if(element.address[0].countryName !== "" && element.address[0].countryName !== null)
                    objAddress.countryName = element.address[0].countryName;
                    //Contact Point
                    if(element.contactPoint[0].name !== "" && element.contactPoint[0].name !== null)
                    objContactPoint.name = element.contactPoint[0].name;
                    if(element.contactPoint[0].email !== "" && element.contactPoint[0].email !== null)
                    objContactPoint.email = element.contactPoint[0].email;
                    if(element.contactPoint[0].telephone !== "" && element.contactPoint[0].telephone !== null)
                    objContactPoint.telephone = element.contactPoint[0].telephone;
                    if(element.contactPoint[0].faxNumber !== "" && element.contactPoint[0].faxNumber !== null)
                    objContactPoint.faxNumber = element.contactPoint[0].faxNumber;
                    if(element.contactPoint[0].url !== "" && element.contactPoint[0].url !== null)
                    objContactPoint.url = element.contactPoint[0].url;
                    //Roles
                    if(element.roles[0].buyer !== "" && element.roles[0].buyer !== null)
                    arrayRoles.push("buyer")
                    if(element.roles[0].reviewBody !== "" && element.roles[0].reviewBody !== null)
                    arrayRoles.push("reviewBody")
                    if(element.roles[0].publicAuthority !== "" && element.roles[0].publicAuthority !== null)
                    arrayRoles.push("publicAuthority")
                    if(element.roles[0].payer !== "" && element.roles[0].payer !== null)
                    arrayRoles.push("payer")
                    if(element.roles[0].procuringEntity !== "" && element.roles[0].procuringEntity !== null)
                    arrayRoles.push("procuringEntity")
                    if(element.roles[0].funder !== "" && element.roles[0].funder !== null)
                    arrayRoles.push("funder")
                    if(element.roles[0].tenderer !== "" && element.roles[0].tenderer !== null)
                    arrayRoles.push("tenderer")
                    if(element.roles[0].enquirer !== "" && element.roles[0].enquirer !== null)
                    arrayRoles.push("enquirer")
                    if(element.roles[0].supplier !== "" && element.roles[0].supplier !== null)
                    arrayRoles.push("supplier")
                    if(element.roles[0].payee !== "" && element.roles[0].payee !== null)
                    arrayRoles.push("payee")
                    //Party
                    if(element.name !== "" && element.name !== null)
                    objParty.name = element.name;
                    if(element.identifier !== "" && element.identifier !== null)
                    objParty.id = element.identifier;
                    if(Object.entries(objIdentifier).length !== 0)
                    objParty.identifier = objIdentifier;
                    if(arrayAdditionalIdentifiers.length > 0)
                    objParty.additionalIdentifiers = arrayAdditionalIdentifiers
                    if(Object.entries(objAddress).length !== 0)
                    objParty.address = objAddress;
                    if(Object.entries(objContactPoint).length !== 0)
                    objParty.contactPoint = objContactPoint;
                    objParty.roles = arrayRoles;
                    arrayParties.push(objParty);
                });
            }
            //Publisher
            if(value[0].publisher[0].name !== "" && value[0].publisher[0].name !== null)
            objPublisher.name = value[0].publisher[0].name;
            if(value[0].publisher[0].scheme !== "" && value[0].publisher[0].scheme !== null)
            objPublisher.scheme = value[0].publisher[0].scheme;
            if(value[0].publisher[0].uid !== "" && value[0].publisher[0].uid !== null)
            objPublisher.uid = value[0].publisher[0].uid;
            if(value[0].publisher[0].uri !== "" && value[0].publisher[0].uri !== null)
            objPublisher.uri = value[0].publisher[0].uri;
            //Period
            if(JSON.stringify(value[0].projects[0].period[0]) !== undefined){
                if(value[0].projects[0].period[0].startDate !== "" && value[0].projects[0].period[0].startDate !== null)
                objPeriod.startDate = dateFortmatGMT(value[0].projects[0].period[0].startDate);
                if(value[0].projects[0].period[0].endDate !== "" && value[0].projects[0].period[0].endDate !== null)
                objPeriod.endDate = dateFortmatGMT(value[0].projects[0].period[0].endDate);
                if(value[0].projects[0].period[0].maxExtentDate !== "" && value[0].projects[0].period[0].maxExtentDate !== null)
                objPeriod.maxExtentDate = dateFortmatGMT(value[0].projects[0].period[0].maxExtentDate);
                if(value[0].projects[0].period[0].durationInDays !== "" && value[0].projects[0].period[0].durationInDays !== null)
                objPeriod.durationInDays = value[0].projects[0].period[0].durationInDays;
            }
            //completion
            if(JSON.stringify(value[0].projects[0].completion[0]) !== undefined){
                if(value[0].projects[0].completion[0].endDate !== "" && value[0].projects[0].completion[0].endDate !== null)
                objCompletion.endDate = dateFortmatGMT(value[0].projects[0].completion[0].endDate);
                if(value[0].projects[0].completion[0].endDateDetails !== "" && value[0].projects[0].completion[0].endDateDetails !== null)
                objCompletion.endDateDetails = value[0].projects[0].completion[0].endDateDetails;
                if(value[0].projects[0].completion[0].finalValueDetails !== "" && value[0].projects[0].completion[0].finalValueDetails !== null)
                objCompletion.finalValueDetails = value[0].projects[0].completion[0].finalValueDetails;
                if(value[0].projects[0].completion[0].finalScope !== "" && value[0].projects[0].completion[0].finalScope !== null)
                objCompletion.finalScope = value[0].projects[0].completion[0].finalScope;
                if(value[0].projects[0].completion[0].finalScopeDetails !== "" && value[0].projects[0].completion[0].finalScopeDetails !== null)
                objCompletion.finalScopeDetails = value[0].projects[0].completion[0].finalScopeDetails;
                //completion_finalValue
                if(value[0].projects[0].completion[0].amount !== "" && value[0].projects[0].completion[0].amount !== null)
                objFinalValue.amount = value[0].projects[0].completion[0].amount;
                if(value[0].projects[0].completion[0].currency !== "" && value[0].projects[0].completion[0].currency !== null)
                objFinalValue.currency = value[0].projects[0].completion[0].currency;
                if(Object.entries(objFinalValue).length !== 0)
                objCompletion.finalValue = objFinalValue;            
                
            }
            //AssetLifeTime
            if(JSON.stringify(value[0].projects[0].assetLifetime[0]) !== undefined){
                if(value[0].projects[0].assetLifetime[0].startDate !== "" && value[0].projects[0].assetLifetime[0].startDate !== null)
                objAssetLifetime.startDate = dateFortmatGMT(value[0].projects[0].assetLifetime[0].startDate);
                if(value[0].projects[0].assetLifetime[0].endDate !== "" && value[0].projects[0].assetLifetime[0].endDate !== null)
                objAssetLifetime.endDate = dateFortmatGMT(value[0].projects[0].assetLifetime[0].endDate);
                if(value[0].projects[0].assetLifetime[0].maxExtentDate !== "" && value[0].projects[0].assetLifetime[0].maxExtentDate !== null)
                objAssetLifetime.maxExtentDate = dateFortmatGMT(value[0].projects[0].assetLifetime[0].maxExtentDate);
                if(value[0].projects[0].assetLifetime[0].durationInDays !== "" && value[0].projects[0].assetLifetime[0].durationInDays !== null)
                objAssetLifetime.durationInDays = value[0].projects[0].assetLifetime[0].durationInDays;
            }
            //Budget
            if(JSON.stringify(value[0].projects[0].budget[0]) !== undefined){
                if(value[0].projects[0].budget[0].requestDate !== "" && value[0].projects[0].budget[0].requestDate !== null)
                objBudget.requestDate = dateFortmatGMT(value[0].projects[0].budget[0].requestDate);
                if(value[0].projects[0].budget[0].approvalDate !== "" && value[0].projects[0].budget[0].approvalDate !== null)
                objBudget.approvalDate = dateFortmatGMT(value[0].projects[0].budget[0].approvalDate);
                //Amount
                if(JSON.stringify(value[0].projects[0].budget[0].amount[0]) !== undefined){
                    if(value[0].projects[0].budget[0].amount[0].amount !== "" && value[0].projects[0].budget[0].amount[0].amount !== null)
                    objAmount.amount = parseInt(value[0].projects[0].budget[0].amount[0].amount, 10);
                    if(value[0].projects[0].budget[0].amount[0].currency !== "" && value[0].projects[0].budget[0].amount[0].currency !== null)
                    objAmount.currency = value[0].projects[0].budget[0].amount[0].currency;
                }
                //BudgetBreakdown
                if(JSON.stringify(value[0].projects[0].budget[0].budgetBreakdown[0]) !== undefined){
                    value[0].projects[0].budget[0].budgetBreakdown.forEach(element => {
                        var objBudgetBreakdown = new Object();
                        var objBudgetBreakdownAmount = new Object();
                        var objBudgetBreakdownPeriod = new Object();
                        var objBudgetBreakdownSourceParty = new Object();
                        var arrayBudgetLines = new Array();

                        if(element.id !== "" && element.id !== null)
                        objBudgetBreakdown.id = String(element.id);
                        if(element.description !== "" && element.description !== null)
                        objBudgetBreakdown.description = element.description;
                        if(element.uri !== "" && element.uri !== null)
                        objBudgetBreakdown.uri = element.uri;
                        //BudgetBreakdown_Amount
                        if(element.amount !== "" && element.amount !== null)
                        objBudgetBreakdownAmount.amount = element.amount;
                        if(element.currency !== "" && element.currency !== null)
                        objBudgetBreakdownAmount.currency = element.currency;
                        if(Object.entries(objBudgetBreakdownAmount).length !== 0)
                        objBudgetBreakdown.amount = objBudgetBreakdownAmount;
                        //BudgetBreakdown_Period
                        if(element.startDate !== "" && element.startDate !== null)
                        objBudgetBreakdownPeriod.startDate = dateFortmatGMT(element.startDate);
                        if(element.endDate !== "" && element.endDate !== null)
                        objBudgetBreakdownPeriod.endDate = dateFortmatGMT(element.endDate);
                        if(element.maxExtentDate !== "" && element.maxExtentDate !== null)
                        objBudgetBreakdownPeriod.maxExtentDate = dateFortmatGMT(element.maxExtentDate);
                        if(element.durationInDays !== "" && element.durationInDays !== null)
                        objBudgetBreakdownPeriod.durationInDays = element.durationInDays;
                        if(Object.entries(objBudgetBreakdownPeriod).length !== 0)
                        objBudgetBreakdown.period = objBudgetBreakdownPeriod;
                        //BudgetBreakdown_SourceParty
                        if(element.sourceParty !== undefined){
                            if(element.sourceParty[0].relation_identifier !== "" && element.sourceParty[0].relation_identifier !== null)
                            objBudgetBreakdownSourceParty.id = element.sourceParty[0].relation_identifier;
                            if(element.sourceParty[0].name !== "" && element.sourceParty[0].name !== null)
                            objBudgetBreakdownSourceParty.name = element.sourceParty[0].name;
                            if(Object.entries(objBudgetBreakdownSourceParty).length !== 0)
                            objBudgetBreakdown.sourceParty = objBudgetBreakdownSourceParty;    
                        }
                        //BudgetBreakdown_Components
                        if(element.budgetLines !== undefined){
                            var arrayBudgetLines = new Array();
                            element.budgetLines.forEach(budgetLine => {
                                var objBudgetLine = new Object();
                                if(budgetLine.c !== undefined){
                                    budgetLine.c.forEach(component => {
                                        var id= null;
                                        var arrayComponents = new Array();
                                        if(component.year !== "" ){
                                            var objComponent = new Object();
                                            objComponent.name = "cycle";
                                            objComponent.level = "1";
                                            objComponent.code = (component.year === null ? '' : component.year);
                                            objComponent.description = (component.year === null ? '' : component.year.toString());
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyBranch !== null && component.branch !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "branch";
                                            objComponent.level = "2";
                                            objComponent.code = (component.kBranch === null ? '' : component.kBranch);
                                            objComponent.description = (component.branch === null ? '' : component.branch);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyResponsibleUnit !== null && component.responsibleUnit !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "responsibleUnit";
                                            objComponent.level = "3";
                                            objComponent.code = (component.kResponsibleUnit === null ? '' : component.kResponsibleUnit);
                                            objComponent.description = (component.responsibleUnit === null ? '' : component.responsibleUnit);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyFinality !== null && component.finality !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "finality";
                                            objComponent.level = "4";
                                            objComponent.code = (component.kFinality === null ? '' : component.kFinality);
                                            objComponent.description = (component.finality === null ? '' : component.finality);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyFunction !== null && component.function !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "function";
                                            objComponent.level = "5";
                                            objComponent.code = (component.kFunction === null ? '' : component.kFunction);
                                            objComponent.description = (component.function === null ? '' : component.function);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keySubFunction !== null && component.subFunction !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "subFunction";
                                            objComponent.level = "6";
                                            objComponent.code = (component.kSubFunction === null ? '' : component.kSubFunction);
                                            objComponent.description = (component.subFunction === null ? '' : component.subFunction);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyInstAct !== null && component.instAct !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "institutionalActivity";
                                            objComponent.level = "7";
                                            objComponent.code = (component.kInstAct === null ? '' : component.kInstAct);
                                            objComponent.description = (component.instAct === null ? '' : component.instAct);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyBudgetProgram !== null && component.budgetProgram !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "budgetProgram";
                                            objComponent.level = "8";
                                            objComponent.code = (component.kBudgetProgram === null ? '' : component.kBudgetProgram);
                                            objComponent.description = (component.budgetProgram === null ? '' : component.budgetProgram);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keySpendingObject !== null && component.spendingObject !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "spendingObject";
                                            objComponent.level = "9";
                                            objComponent.code = (component.kSpendingObject === null ? '' : component.kSpendingObject);
                                            objComponent.description = (component.spendingObject === null ? '' : component.spendingObject);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keySpendingType !== null && component.spendingType !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "spendingType";
                                            objComponent.level = "10";
                                            objComponent.code = (component.kSpendingType === null ? '' : component.kSpendingType);
                                            objComponent.description = (component.spendingType === null ? '' : component.spendingType);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyBudgetSource !== null && component.budgetSource !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "budgetSource";
                                            objComponent.level = "11";
                                            objComponent.code = (component.kBudgetSource === null ? '' : component.kBudgetSource);
                                            objComponent.description = (component.budgetSource === null ? '' : component.budgetSource);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyRegion !== null && component.region !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "region";
                                            objComponent.level = "12";
                                            objComponent.code = (component.kRegion === null ? '' : component.kRegion);
                                            objComponent.description = (component.region === null ? '' : component.region);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(component.keyPortfolio !== null && component.portfolio !== null){
                                            var objComponent = new Object();
                                            objComponent.name = "portfolioKey";
                                            objComponent.level = "13";
                                            objComponent.code = (component.kPortfolio === null ? '' : component.kPortfolio);
                                            objComponent.description = (component.portfolio === null ? '' : component.portfolio);
                                            id = id + objComponent.code;
                                            arrayComponents.push(objComponent)
                                        }
                                        if(arrayComponents.length > 0)
                                        objBudgetLine.id = id;
                                        objBudgetLine.components = arrayComponents;
                                    });
                                }
                                if(budgetLine.measures !== undefined){
                                    var arrayMeasures = new Array();
                                    budgetLine.measures.forEach(measure => {
                                        var objMeasure = new Object();
                                        var objValue = new Object();
                                        objValue.amount = measure.amount;
                                        objValue.currency = measure.currency;
                                        objMeasure.id = measure.type;
                                        objMeasure.value = objValue;
                                        objMeasure.update = dateFortmatGMT(measure.date);
                                        arrayMeasures.push(objMeasure);
                                    }); 
                                    if(arrayMeasures.length > 0)
                                    objBudgetLine.measures = arrayMeasures
                                }
                                arrayBudgetLines.push(objBudgetLine)
                            });
                            if(arrayBudgetLines.length > 0)
                            objBudgetBreakdown.budgetLines = arrayBudgetLines;
                            arrayBudgetBreakdown.push(objBudgetBreakdown);
                        }
                    });
                }
                if(Object.entries(objAmount).length !== 0)
                objBudget.amount = objAmount;
                if(arrayBudgetBreakdown.length > 0)
                objBudget.budgetBreakdown = arrayBudgetBreakdown;
                
            }
            //Project
            // OC4IDS campo que aun no tiene el standar mejora propuesta por el INAI
            // if(value[0].projects[0].oc4ids !== "" && value[0].projects[0].oc4ids !== null)
            // objProject.oc4ids = value[0].projects[0].oc4ids;
            // IDENTIFIER campo Identificador que se llena en la vista, no cuenta con el prefijo OC4IDS
            // if(value[0].projects[0].identifier !== "" && value[0].projects[0].identifier !== null)
            // objProject.id = value[0].projects[0].identifier;
            if(value[0].projects[0].oc4ids !== "" && value[0].projects[0].oc4ids !== null)
            objProject.id = value[0].projects[0].oc4ids + "-" + value[0].projects[0].identifier;
            if(value[0].projects[0].updated !== "" && value[0].projects[0].updated !== null)
            objProject.updated = dateFortmatGMT(value[0].projects[0].updated);
            if(value[0].projects[0].title !== "" && value[0].projects[0].title !== null)
            objProject.title = value[0].projects[0].title;
            if(value[0].projects[0].description !== "" && value[0].projects[0].description !== null)
            objProject.description = value[0].projects[0].description;
            if(value[0].projects[0].status !== "" && value[0].projects[0].status !== null)
            objProject.status = value[0].projects[0].status;
            if(value[0].projects[0].purpose !== "" && value[0].projects[0].purpose !== null)
            objProject.purpose = value[0].projects[0].purpose;
            if(value[0].projects[0].sector !== null)
            objProject.sector = value[0].projects[0].sector;
            if(value[0].projects[0].type !== "" && value[0].projects[0].type !== null)
            objProject.type = value[0].projects[0].type;            
            if(Object.entries(objPeriod).length !== 0)
            objProject.period = objPeriod;            
            if(Object.entries(objCompletion).length !== 0)
            objProject.completion = objCompletion;            
            if(Object.entries(objAssetLifetime).length !== 0)
            objProject.assetLifetime = objAssetLifetime;
            if(Object.entries(objBudget).length !== 0)
            objProject.budget = objBudget;
            if(arrayParties.length > 0 && arrayParties.length !== undefined)
            objProject.parties = arrayParties;
            if(arrayRelatedProjects.length > 0 && arrayRelatedProjects.length !== undefined)
            objProject.relatedProjects = arrayRelatedProjects;
            if(arrayAdditionalClassifications.length > 0 && arrayAdditionalClassifications.length !== undefined)
            objProject.additionalClassifications = arrayAdditionalClassifications;
            if(arrayDocumentsProject.length > 0 && arrayDocumentsProject.length !== undefined)
            objProject.documents = arrayDocumentsProject;
            if(arrayLocationProjects.length > 0 && arrayLocationProjects.length !== undefined)
            objProject.locations = arrayLocationProjects;
            if(arrayContractingProcesses.length > 0 && arrayContractingProcesses.length !== undefined)
            objProject.contractingProcesses = arrayContractingProcesses;
            //ProjectPackage
            if(value[0].uri !== "" && value[0].uri !== null)
            objProjectPackage.uri = value[0].uri;
            if(value[0].publishedDate !== "" && value[0].publishedDate !== null)
            objProjectPackage.publishedDate = dateFortmatGMT(value[0].publishedDate);
            if(value[0].version !== "" && value[0].version !== null)
            objProjectPackage.version = value[0].version.substr(-5,3);
            if(value[0].license !== "" && value[0].license !== null)
            objProjectPackage.license = value[0].license;
            if(value[0].publicationPolicy !== "" && value[0].publicationPolicy !== null)
            objProjectPackage.publicationPolicy = value[0].publicationPolicy
            if(Object.entries(objProject).length !== 0)
            objProjectPackage.projects = [objProject]
            if(Object.entries(objPublisher).length !== 0)
            objProjectPackage.publisher = objPublisher;

            console.log("$$|$$ OBJ: " + JSON.stringify(objProjectPackage))
            console.log("$$|$$ imprimeProjectPackage: " + JSON.stringify(value))
            if(isProjectPackage){
                return objProjectPackage;
            }else{
                return objProject;
            }
            
        });
    },
    updateProject: async function(data){
        console.log("$$$$ updateProject")
        var obj = JSON.parse(data);
        var prefix = await db.edcapi_project_prefix.findByPk(1);
        
        findProjects(obj.project_id).then(value =>{
            var arraySector = new Array();
            if(Array.isArray(obj.sector)){
                arraySector = obj.sector;
            }else if(obj.sector === '') {

            }else{
                arraySector.push(obj.sector);
            }
            value[0].projects[0].update({
                oc4ids:  prefix.prefix,
                identifier: (obj.id === '' ? null : obj.id),
                updated: new Date(),
                title: (obj.title === '' ? null : obj.title),
                description: (obj.description === '' ? null : obj.description),
                status: (obj.status === '' ? null : obj.status),
                purpose: (obj.purpose === '' ? null : obj.purpose),
                sector: (arraySector < 0 ? null : arraySector),
                type: (obj.type === '' ? null : obj.type),
                updatedAt : new Date()
            }).then(function(result){
                if(value[0].projects[0].period.length > 0){
                    value[0].projects[0].period[0].update({
                        startDate : (obj.period_startDate === '' ? null : obj.period_startDate),
                        endDate : (obj.period_endDate === '' ? null : obj.period_endDate),
                        maxExtentDate : (obj.period_maxExtentDate === '' ? null : obj.period_maxExtentDate),
                        durationInDays : (obj.period_durationInDays === '' ? null : obj.period_durationInDays),
                        updatedAt : new Date()
                    });
                }
            }).then(function(result){
                if(value[0].projects[0].budget.length > 0){
                    value[0].projects[0].budget[0].update({
                        requestDate: (obj.budget_requestDate === '' ? null : obj.budget_requestDate),
                        approvalDate: (obj.budget_approvalDate === '' ? null : obj.budget_approvalDate),
                        updatedAt : new Date()
                    });
                    if(value[0].projects[0].budget[0].amount.length > 0){
                        value[0].projects[0].budget[0].amount[0].update({
                            amount: (obj.budget_amount_amount === '' ? null : obj.budget_amount_amount),
                            currency: (obj.budget_amount_amount === '' ? null : obj.budget_amount_currency),
                            updatedAt : new Date()
                        });
                    }
                }
            }).then(function(result){
                if(value[0].projects[0].assetLifetime.length > 0){
                    value[0].projects[0].assetLifetime[0].update({
                        startDate : (obj.assetLifetime_startDate === '' ? null : obj.assetLifetime_startDate),
                        endDate : (obj.assetLifetime_endDate === '' ? null : obj.assetLifetime_endDate),
                        maxExtentDate : (obj.assetLifetime_maxExtentDate === '' ? null : obj.assetLifetime_maxExtentDate),
                        durationInDays : (obj.assetLifetime_durationInDays === '' ? null : obj.assetLifetime_durationInDays),
                        updatedAt : new Date()
                    });                   
                }
            });         
        });
    },
    insertParties: async function(data){
        console.log("$$$$ insertParties")
        var obj = JSON.parse(data);
        var relProjectPartyProject = new db.edcapi_project_party_project();
        var projectParty = new db.edcapi_project_party();
        var relPartyIdentifierParty = new db.edcapi_project_parties_identifier_project();
        var partyIdentifier = new db.edcapi_project_parties_identifier();
        var relPartyAddressParty = new db.edcapi_project_parties_address_party();
        var partyAddress = new db.edcapi_project_parties_address();
        var relPartyContactPointParty = new db.edcapi_project_parties_contact_point_party();
        var partyContactPoint = new db.edcapi_project_parties_contact_point();
        var relPartyRolesParty = new db.edcapi_project_parties_roles_party();
        var partyRoles = new db.edcapi_project_parties_roles();

        projectParty = await db.edcapi_project_party.create({ // PARTY
            identifier : (obj.parties_id === '' ? null : obj.parties_id),
            name : (obj.parties_name === '' ? null : obj.parties_name),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectParty){ // REL PARTY - PROJECT
            console.log("############## PROJECT PARTY - " + JSON.stringify(projectParty, null, 4))
            return relProjectPartyProject = await db.edcapi_project_party_project.create({
                project_id: (obj.project_id === '' ? null : obj.project_id),
                edcapiProjectPartyId: projectParty.id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relProjectPartyProject){ // PARTY/IDENTIFIER
                console.log("############## REL PROJECT PARTY - " + JSON.stringify(relProjectPartyProject, null, 4))
                return partyIdentifier = await db.edcapi_project_parties_identifier.create({
                    scheme: (obj.identifier_scheme === '' ? null : obj.identifier_scheme),
                    identifier: (obj.identifier_id === '' ? null : obj.identifier_id),
                    legalName: (obj.identifier_legalName === '' ? null : obj.identifier_legalName),
                    uri: (obj.identifier_uri === '' ? null : obj.identifier_uri),
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(async function(partyIdentifier){ // REL PARTY/IDENTIFIER - PARTY
                    console.log("############## IDENTIFIER - " + JSON.stringify(partyIdentifier, null, 4))
                    return relPartyIdentifierParty = await db.edcapi_project_parties_identifier_project.create({
                        edcapiProjectPartiesIdentifierId: partyIdentifier.id,
                        party_id: relProjectPartyProject.edcapiProjectPartyId,
                        createdAt : new Date(),
                        updatedAt : new Date()
                }).then(async function(relPartyIdentifierParty){ // PARTY/ADDRESS
                    console.log("############## REL PARTY IDENTIFIER - " + JSON.stringify(relPartyIdentifierParty, null, 4))
                    return partyAddress = await db.edcapi_project_parties_address.create({
                        streetAddress: (obj.address_streetAddress === '' ? null : obj.address_streetAddress),
                        locality: (obj.address_locality === '' ? null : obj.address_locality),
                        region: (obj.address_region === '' ? null : obj.address_region),
                        postalCode: (obj.address_postalCode === '' ? null : obj.address_postalCode),
                        countryName: (obj.address_countryName === '' ? null : obj.address_countryName),
                        createdAt : new Date(),
                        updatedAt : new Date()
                    }).then(async function(partyAddress){ // REL PARTY/ADDRESS - PARTY
                        console.log("############## PARTY ADDRESS - " + JSON.stringify(partyAddress, null, 4))
                        return relPartyAddressParty = await db.edcapi_project_parties_address_party.create({
                            edcapiProjectPartiesAddressId: partyAddress.id,
                            party_id: projectParty.id,
                            createdAt : new Date(),
                            updatedAt : new Date()
                        }).then(async function(relPartyAddressParty){ // PARTY/CONTACT POINT
                            console.log("############## REL PARTY ADDRESS - " + JSON.stringify(relPartyAddressParty, null, 4))
                            return partyContactPoint = await db.edcapi_project_parties_contact_point.create({
                                name: (obj.contactPoint_name === '' ? null : obj.contactPoint_name),
                                email: (obj.contactPoint_email === '' ? null : obj.contactPoint_email),
                                telephone: (obj.contactPoint_telephone === '' ? null : obj.contactPoint_telephone),
                                faxNumber: (obj.contactPoint_faxNumber === '' ? null : obj.contactPoint_faxNumber),
                                url: (obj.contactPoint_url === '' ? null : obj.contactPoint_url),
                                createdAt : new Date(),
                                updatedAt : new Date()
                            }).then(async function(partyContactPoint){ // REL PARTY/CONTACT POINT - PARTY
                                console.log("############## PARTY CONTACT POINT - " + JSON.stringify(partyContactPoint, null, 4))
                                return relPartyContactPointParty = await db.edcapi_project_parties_contact_point_party.create({
                                    edcapiProjectPartiesContactPointId: partyContactPoint.id,
                                    party_id: projectParty.id,
                                    createdAt : new Date(),
                                    updatedAt : new Date()
                                }).then(async function(relPartyContactPointParty){ // PARTY/ROLES
                                    console.log("############## REL PARTY CONTACT POINT - " + JSON.stringify(relPartyContactPointParty, null, 4))
                                    return partyRoles = await db.edcapi_project_parties_roles.create({
                                        buyer: (obj.buyer === '' ? null : obj.buyer),
                                        reviewBody: (obj.reviewBody === '' ? null : obj.reviewBody),
                                        publicAuthority: (obj.publicAuthority === '' ? null : obj.publicAuthority),
                                        payer: (obj.payer === '' ? null : obj.payer),
                                        procuringEntity: (obj.procuringEntity === '' ? null : obj.procuringEntity),
                                        funder: (obj.funder === '' ? null : obj.funder),
                                        tenderer: (obj.tenderer === '' ? null : obj.tenderer),
                                        enquirer: (obj.enquirer === '' ? null : obj.enquirer),
                                        supplier: (obj.supplier === '' ? null : obj.supplier),
                                        payee: (obj.payee === '' ? null : obj.payee),
                                        createdAt : new Date(),
                                        updatedAt : new Date()
                                    }).then(async function(partyRoles){ // REL PARTY/ROLES - PARTY
                                        console.log("############## PARTY ROLES - " + JSON.stringify(partyRoles, null, 4))
                                        return relPartyRolesParty = await db.edcapi_project_parties_roles_party.create({
                                            edcapiProjectPartiesRoleId: partyRoles.id,
                                            party_id: projectParty.id
                                        }).then(async function(relPartyRolesParty){
                                            console.log("############## REL PARTY ROLES - " + JSON.stringify(relPartyRolesParty, null, 4))
                                        })
                                    })
                                })
                            })
                        })
                    })
                })
            })
            
        });
    });
    },
    findProject: async function(project_id){
        console.log("$$$$ findProject")
        return findProjects(project_id).then(value =>{
            return value;
        });
    },
    findParty: async function(party_id){
        console.log("%%%% findParty")
        var project_party = await db.edcapi_project_party.findAll({
            include:[
                {
                    model: db.edcapi_project_parties_identifier,
                    as: 'identifierR', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_parties_additional_identifier,
                    as: 'additionalIdentifiers', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_parties_address,
                    as: 'address', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_parties_contact_point,
                    as: 'contactPoint', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_parties_roles,
                    as: 'roles', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                }
            ],attributes: { exclude: ['createdAt','updatedAt']},
            where : {id: party_id}
            });
            return project_party;
    },
    updateParty: async function(data){
        console.log("%%%% updateParty")
        var obj = JSON.parse(data);
        var projectParty = new db.edcapi_project_party();
        var partyIdentifier = new db.edcapi_project_parties_identifier();
        var partyAddress = new db.edcapi_project_parties_address();
        var partyContactPoint = new db.edcapi_project_parties_contact_point();
        var partyRoles = new db.edcapi_project_parties_roles();

        async function findObjects(obj){
            projectParty = await db.edcapi_project_party.findByPk(obj.party_id);
            partyIdentifier = await db.edcapi_project_parties_identifier.findByPk(obj.identifierR_id);
            partyAddress = await db.edcapi_project_parties_address.findByPk(obj.address_id);
            partyContactPoint = await db.edcapi_project_parties_contact_point.findByPk(obj.contactPoint_id);
            partyRoles = await db.edcapi_project_parties_roles.findByPk(obj.roles_id);
        };

        findObjects(obj).then(function (){
            projectParty.update({
                identifier : (obj.parties_id === '' ? null : obj.parties_id),
                name : (obj.parties_name === '' ? null : obj.parties_name),
                updatedAt : new Date()
            }).then(async function(){
                return partyIdentifier.update({
                    scheme: (obj.identifier_scheme === '' ? null : obj.identifier_scheme),
                    identifier: (obj.identifier_id === '' ? null : obj.identifier_id),
                    legalName: (obj.identifier_legalName === '' ? null : obj.identifier_legalName),
                    uri: (obj.identifier_uri === '' ? null : obj.identifier_uri),
                    updatedAt : new Date()
                });
            }).then(async function(){
                return partyAddress.update({
                    streetAddress: (obj.address_streetAddress === '' ? null : obj.address_streetAddress),
                    locality: (obj.address_locality === '' ? null : obj.address_locality),
                    region: (obj.address_region === '' ? null : obj.address_region),
                    postalCode: (obj.address_postalCode === '' ? null : obj.address_postalCode),
                    countryName: (obj.address_countryName === '' ? null : obj.address_countryName),
                    updatedAt : new Date()
                });
            }).then(async function(){
                return partyContactPoint.update({
                    name: (obj.contactPoint_name === '' ? null : obj.contactPoint_name),
                    email: (obj.contactPoint_email === '' ? null : obj.contactPoint_email),
                    telephone: (obj.contactPoint_telephone === '' ? null : obj.contactPoint_telephone),
                    faxNumber: (obj.contactPoint_faxNumber === '' ? null : obj.contactPoint_faxNumber),
                    url: (obj.contactPoint_url === '' ? null : obj.contactPoint_url),
                    updatedAt : new Date()
                });
            }).then(async function(){
                return partyRoles.update({
                    buyer: (obj.buyer === 'on' ? obj.buyer : null),
                    reviewBody: (obj.reviewBody === 'on' ? obj.reviewBody : null),
                    publicAuthority: (obj.publicAuthority === 'on' ? obj.publicAuthority : null),
                    payer: (obj.payer === 'on' ? obj.payer : null),
                    procuringEntity: (obj.procuringEntity === 'on' ? obj.procuringEntity : null),
                    funder: (obj.funder === 'on' ? obj.funder : null),
                    tenderer: (obj.tenderer === 'on' ? obj.tenderer : null),
                    enquirer: (obj.enquirer === 'on' ? obj.enquirer : null),
                    supplier: (obj.supplier === 'on' ? obj.supplier : null),
                    payee: (obj.payee === 'on' ? obj.payee : null),
                    updatedAt : new Date()
                });
            });
        });
    },
    deleteParty: async function(party_id){
        console.log("%%%% deleteParty")
        await db.edcapi_project_party.destroy({
            where: {id: party_id}
          })
        return true;
    },
    insertAdditionalIdentifier: async function(data){
        console.log("$$$$ insertAdditionalIdentifier")
        var obj = JSON.parse(data);
        var relPartyAdditionalIdentifierParty = new db.edcapi_project_parties_additional_identifier_party();
        var partyAdditionalIdentifier = new db.edcapi_project_parties_additional_identifier();

        partyAdditionalIdentifier = await db.edcapi_project_parties_additional_identifier.create({
            scheme: (obj.additionalIdentifiers_scheme === '' ? null : obj.additionalIdentifiers_scheme),
            identifier: (obj.additionalIdentifiers_id === '' ? null : obj.additionalIdentifiers_id),
            legalName: (obj.additionalIdentifiers_legalName === '' ? null : obj.additionalIdentifiers_legalName),
            uri: (obj.additionalIdentifiers_url === '' ? null : obj.additionalIdentifiers_url),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(partyAdditionalIdentifier){
            console.log("############## ADDITIONAL IDENTIFIER - " + JSON.stringify(partyAdditionalIdentifier, null, 4))
            return relPartyAdditionalIdentifierParty = await db.edcapi_project_parties_additional_identifier_party.create({
                party_id: obj.party_id,
                edcapiProjectPartiesAdditionalIdentifierId: partyAdditionalIdentifier.id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relPartyAdditionalIdentifierParty){
                console.log("############## REL PARTY ADDITIONAL IDENTIFIER - " + JSON.stringify(relPartyAdditionalIdentifierParty, null, 4))
            })
        })
    },
    findAdditionalIdentifier: async function(identifier_id){
        console.log("%%%% findAdditionalIdentifier")
        var additional_identifier = await db.edcapi_project_parties_additional_identifier.findAll({
            include:[],
            attributes: { exclude: ['createdAt','updatedAt']},
            where : {id: identifier_id}
            });
            return additional_identifier;
    },
    updateAdditionalIdentifier: async function(data){
        console.log("%%%% updateAdditionalIdentifier")
        var obj = JSON.parse(data);
        var additional_identifier = new db.edcapi_project_parties_additional_identifier();

        async function findObjects(obj){
            additional_identifier = await db.edcapi_project_parties_additional_identifier.findByPk(obj.identifier_id);
        };

        findObjects(obj).then(function (){
            additional_identifier.update({
                scheme: (obj.additionalIdentifiers_scheme === '' ? null : obj.additionalIdentifiers_scheme),
                identifier: (obj.additionalIdentifiers_id === '' ? null : obj.additionalIdentifiers_id),
                legalName: (obj.additionalIdentifiers_legalName === '' ? null : obj.additionalIdentifiers_legalName),
                uri: (obj.additionalIdentifiers_url === '' ? null : obj.additionalIdentifiers_url),
                updatedAt : new Date()
            })
        })
    },
    deleteAdditionalIdentifier: async function(identifier_id){
        console.log("%%%% deleteAdditionalIdentifier")
        await db.edcapi_project_parties_additional_identifier.destroy({
            where: {id: identifier_id}
          })
        return true;
    },
    insertRelatedProject: async function(data){
        console.log("$$$$ insertAdditionalIdentifier")
        var obj = JSON.parse(data);
        var relprojectRelatedProjectProject = new db.edcapi_project_related_project_project();
        var projectRelatedProject = new db.edcapi_project_related_project();

        projectRelatedProject = await db.edcapi_project_related_project.create({
            relationship: (obj.relatedProject_relationship === '' ? null : obj.relatedProject_relationship),
            title: (obj.relatedProject_title === '' ? null : obj.relatedProject_title),
            scheme: (obj.relatedProject_scheme === '' ? null : obj.relatedProject_scheme),
            identifier: (obj.relatedProject_identifier === '' ? null : obj.relatedProject_identifier),
            uri: (obj.relatedProject_uri === '' ? null : obj.relatedProject_uri),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectRelatedProject){
            console.log("############## RELATED PROJECT - " + JSON.stringify(projectRelatedProject, null, 4))
            return relprojectRelatedProjectProject = await db.edcapi_project_related_project_project.create({
                edcapiProjectRelatedProjectId: projectRelatedProject.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectRelatedProjectProject){
                console.log("############## REL PROJECT RELATED PROJECT - " + JSON.stringify(relprojectRelatedProjectProject, null, 4))
            })
        });
    },
    findRelatedProjects: async function(related_project_id){
        console.log("%%%% findRelatedProjects")
        var related_projects = await db.edcapi_project_related_project.findByPk(related_project_id);
        return related_projects;
    },
    updateRelatedProject: async function(data){
        console.log("%%%% updateRelatedProject")
        var obj = JSON.parse(data);
        var related_projects = new db.edcapi_project_related_project();

        async function findObjects(obj){
            related_projects = await db.edcapi_project_related_project.findByPk(obj.related_project_id);
        };

        findObjects(obj).then(function (){
            related_projects.update({
                relationship: (obj.relatedProject_relationship === '' ? null : obj.relatedProject_relationship),
                title: (obj.relatedProject_title === '' ? null : obj.relatedProject_title),
                scheme: (obj.relatedProject_scheme === '' ? null : obj.relatedProject_scheme),
                identifier: (obj.relatedProject_identifier === '' ? null : obj.relatedProject_identifier),
                uri: (obj.relatedProject_uri === '' ? null : obj.relatedProject_uri),
                updatedAt : new Date()
            })
        })
    },
    deleteRelatedProject: async function(related_project_id){
        console.log("%%%% deleteRelatedProject")
        await db.edcapi_project_related_project.destroy({
            where: {id: related_project_id}
          })
        return true;
    },
    insertAdditionalClassification: async function(data){
        console.log("$$$$ insertAdditionalClassification")
        var obj = JSON.parse(data);
        var relprojectAdditionalClassfication = new db.edcapi_project_additional_classification_project();
        var projectAdditionalClassification = new db.edcapi_project_additional_classification();

        projectAdditionalClassification = await db.edcapi_project_additional_classification.create({
            schema: (obj.schema === '' ? null : obj.schema),
            identifier: (obj.identifier === '' ? null : obj.identifier),
            description: (obj.description === '' ? null : obj.description),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectAdditionalClassification){
            console.log("############## ADDITIONAL CLASSIFICATION - " + JSON.stringify(projectAdditionalClassification, null, 4))
            return relprojectAdditionalClassfication = await db.edcapi_project_additional_classification_project.create({
                edcapiProjectAdditionalClassificationId: projectAdditionalClassification.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectAdditionalClassfication){
                console.log("############## REL PROJECT ADDITIONAL CLASSIFICATION - " + JSON.stringify(relprojectAdditionalClassfication, null, 4))
            })
        });
    },
    findAdditionalClassification: async function(additional_classification_id){
        console.log("%%%% findAdditionalClassification")
        var additional_classification = await db.edcapi_project_additional_classification.findByPk(additional_classification_id);
        return additional_classification;
    },
    updateAdditionalClassification: async function(data){
        console.log("%%%% updateAdditionalClassification")
        var obj = JSON.parse(data);
        var additional_classification = new db.edcapi_project_additional_classification();

        async function findObjects(obj){
            additional_classification = await db.edcapi_project_additional_classification.findByPk(obj.classification_id);
        };

        findObjects(obj).then(function (){
            additional_classification.update({
                schema: (obj.schema === '' ? null : obj.schema),
                identifier: (obj.identifier === '' ? null : obj.identifier),
                description: (obj.description === '' ? null : obj.description),
                updatedAt : new Date()
            })
        })
    },
    deleteAdditionalClassification: async function(additional_classification_id){
        console.log("%%%% deleteAdditionalClassification")
        await db.edcapi_project_additional_classification.destroy({
            where: {id: additional_classification_id}
          })
        return true;
    },
    insertDocumentProject: async function(data){
        console.log("$$$$ insertDocumentProject")
        var obj = JSON.parse(data);
        var relprojectDocument = new db.edcapi_project_document_project();
        var projectDocument = new db.edcapi_project_document();

        projectDocument = await db.edcapi_project_document.create({
            documentType: (obj.documents_documentType === '' ? null : obj.documents_documentType),
            title: (obj.documents_title === '' ? null : obj.documents_title),
            description: (obj.documents_description === '' ? null : obj.documents_description),
            url: (obj.documents_url === '' ? null : obj.documents_url),
            datePublished: (obj.documents_datePublished === '' ? null : obj.documents_datePublished),
            dateModified: (obj.documents_dateModified === '' ? null : obj.documents_dateModified),
            format: (obj.documents_format === '' ? null : obj.documents_format),
            language: (obj.documents_language === '' ? null : obj.documents_language),
            pageStart: (obj.documents_pageStart === '' ? null : obj.documents_pageStart),
            pageEnd: (obj.documents_pageEnd === '' ? null : obj.documents_pageEnd),
            accessDetails: (obj.documents_accessDetails === '' ? null : obj.documents_accessDetails),
            author: (obj.documents_author === '' ? null : obj.documents_author),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectDocument){
            console.log("############## PROJECT DOCUMENT - " + JSON.stringify(projectDocument, null, 4))
            return relprojectDocument = await db.edcapi_project_document_project.create({
                edcapiProjectDocumentId: projectDocument.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectDocument){
                console.log("############## REL PROJECT DOCUMENT PROJECT - " + JSON.stringify(relprojectDocument, null, 4))
            })
        });
    },
    findDocumentProject: async function(document_id){
        console.log("%%%% findDocumentProject")
        var document_project = await db.edcapi_project_document.findByPk(document_id);
        return document_project;
    },
    updateDocumentProject: async function(data){
        console.log("%%%% updateDocumentProject")
        var obj = JSON.parse(data);
        var document_project = new db.edcapi_project_document();

        async function findObjects(obj){
            document_project = await db.edcapi_project_document.findByPk(obj.document_id);
        };

        findObjects(obj).then(function (){
            document_project.update({
                documentType: (obj.documents_documentType === '' ? null : obj.documents_documentType),
                title: (obj.documents_title === '' ? null : obj.documents_title),
                description: (obj.documents_description === '' ? null : obj.documents_description),
                url: (obj.documents_url === '' ? null : obj.documents_url),
                datePublished: (obj.documents_datePublished === '' ? null : obj.documents_datePublished),
                dateModified: (obj.documents_dateModified === '' ? null : obj.documents_dateModified),
                format: (obj.documents_format === '' ? null : obj.documents_format),
                language: (obj.documents_language === '' ? null : obj.documents_language),
                pageStart: (obj.documents_pageStart === '' ? null : obj.documents_pageStart),
                pageEnd: (obj.documents_pageEnd === '' ? null : obj.documents_pageEnd),
                accessDetails: (obj.documents_accessDetails === '' ? null : obj.documents_accessDetails),
                author: (obj.documents_author === '' ? null : obj.documents_author),
                updatedAt : new Date()
            })
        })
    },
    deleteDocumentProject: async function(document_id){
        console.log("%%%% deleteDocumentProject")
        await db.edcapi_project_document.destroy({
            where: {id: document_id}
        })
        return true;
    },
    insertLocationProject: async function(data){
        console.log("$$$$ insertLocationProject")
        var obj = JSON.parse(data);
        var relprojectLocation = new db.edcapi_project_location_project();
        var projectLocation = new db.edcapi_location_project();
        
        projectLocation = await db.edcapi_location_project.create({
            description: (obj.locations_description === '' ? null : obj.locations_description),
            type: (obj.locations_geometry_type === '' ? null : obj.locations_geometry_type),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectLocation){
            console.log("############## PROJECT LOCATION - " + JSON.stringify(projectLocation, null, 4))
            return relprojectLocation = await db.edcapi_project_location_project.create({
                edcapiLocationProjectId: projectLocation.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectLocation){
                console.log("############## REL PROJECT LOCATION PROJECT - " + JSON.stringify(relprojectLocation, null, 4))
                var locationCoordinate = new db.edcapi_project_location_coordinate();
                var relLocationCoordinateLocation = new db.edcapi_project_locations_coordinate_location();
                return locationCoordinate = await db.edcapi_project_location_coordinate.create({                    
                    point:(obj.latitude_p === '' ? null : obj.latitude_p),
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(async function(locationCoordinate){
                    console.log("############## LOCATION COORDINATE - " + JSON.stringify(locationCoordinate, null, 4))
                    return relLocationCoordinateLocation = await db.edcapi_project_locations_coordinate_location.create({
                        edcapiLocationProjectId: projectLocation.id,
                        edcapiProjectLocationCoordinateId: locationCoordinate.id,
                        createdAt : new Date(),
                        updatedAt : new Date()
                    }).then(async function(relLocationCoordinateLocation){
                        console.log("############## REL LOCATION COORDINATE LOCATION - " + JSON.stringify(relLocationCoordinateLocation, null, 4))
                        var locationCoordinate = new db.edcapi_project_location_coordinate();
                        var relLocationCoordinateLocation = new db.edcapi_project_locations_coordinate_location();
                        return locationCoordinate = await db.edcapi_project_location_coordinate.create({                    
                            point:(obj.longitude_p === '' ? null : obj.longitude_p),
                            createdAt : new Date(),
                            updatedAt : new Date()
                        }).then(async function(locationCoordinate){
                            console.log("############## LOCATION COORDINATE - " + JSON.stringify(locationCoordinate, null, 4))
                            return relLocationCoordinateLocation = await db.edcapi_project_locations_coordinate_location.create({
                                edcapiLocationProjectId: projectLocation.id,
                                edcapiProjectLocationCoordinateId: locationCoordinate.id,
                                createdAt : new Date(),
                                updatedAt : new Date()
                            }).then(async function(relLocationCoordinateLocation){
                                console.log("############## REL LOCATION COORDINATE LOCATION - " + JSON.stringify(relLocationCoordinateLocation, null, 4))
                                var locationAddress = new db.edcapi_project_location_address();
                                var relLocationAddressLocation = new db.edcapi_project_locations_address_location();
                                return locationAddress = await db.edcapi_project_location_address.create({
                                    streetAddress: (obj.location_streetaddress_p === '' ? null : obj.location_streetaddress_p),
                                    locality: (obj.location_locality_p === '' ? null : obj.location_locality_p),
                                    region: (obj.location_region_p === '' ? null : obj.location_region_p),
                                    postalCode: (obj.location_postalcode_p === '' ? null : obj.location_postalcode_p),
                                    countryName: (obj.location_countryname_p === '' ? null : obj.location_countryname_p),
                                    createdAt : new Date(),
                                    updatedAt : new Date()
                                }).then(async function(locationAddress){
                                    console.log("############## LOCATION ADDRESS - " + JSON.stringify(locationAddress, null, 4))
                                    return relLocationAddressLocation = await db.edcapi_project_locations_address_location.create({
                                        edcapiLocationProjectId: projectLocation.id,
                                        edcapiProjectLocationAddressId: locationAddress.id,
                                        createdAt : new Date(),
                                        updatedAt : new Date()
                                    }).then(async function(relLocationAddressLocation){
                                        console.log("############## REL LOCATION ADDRESS LOCATION - " + JSON.stringify(relLocationAddressLocation, null, 4))
                                    })
                                })
                            })
                        })
                    })
                })
            });
        });
    },
    findLocationProject: async function(location_id){
        console.log("%%%% findLocationProject")
        var location_project = await db.edcapi_location_project.findAll({
            include:[
                {
                    model: db.edcapi_project_location_coordinate,
                    as: 'coordinates', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_location_address,
                    as: 'address', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                }
            ],where : {id: location_id}
        });
        return location_project;
    },
    updateLocationProject: async function(data){
        console.log("%%%% updateLocationProject")
        var obj = JSON.parse(data);
        var location_project = new db.edcapi_location_project();

        async function findObjects(obj){
            return location_project = await db.edcapi_location_project.findAll({
                include:[
                    {
                        model: db.edcapi_project_location_coordinate,
                        as: 'coordinates', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_project_location_address,
                        as: 'address', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    }
                ],where : {id: obj.location_id}
            });
        };
        findObjects(obj).then(async function(res){//AQUI
            console.log('####################' + JSON.stringify(res[0].coordinates));
            res[0].coordinates[0].update({
                point:(obj.latitude_p === '' ? null : obj.latitude_p),
                updatedAt : new Date()
            });
            res[0].coordinates[1].update({
                point:(obj.longitude_p === '' ? null : obj.longitude_p),
                updatedAt : new Date()
            });
            res[0].update({
                description: (obj.locations_description === '' ? null : obj.locations_description),
                updatedAt : new Date()
            });
            res[0].address[0].update({
                streetAddress: (obj.location_streetaddress_p === '' ? null : obj.location_streetaddress_p),
                locality: (obj.location_locality_p === '' ? null : obj.location_locality_p),
                region: (obj.location_region_p === '' ? null : obj.location_region_p),
                postalCode: (obj.location_postalcode_p === '' ? null : obj.location_postalcode_p),
                countryName: (obj.location_countryname_p === '' ? null : obj.location_countryname_p),
                updatedAt : new Date()
            });
        })       
    },
    deleteLocationProject: async function(location_id){
        console.log("%%%% deleteLocationProject")
        await db.edcapi_location_project.destroy({
            where: {id: location_id}
          })
        return true;
    },
    findPartyFunder: async function(project_id){
        console.log("%%%% findPartyFunder")
        var arrayPartiesFunder = new Array();
        var party_funder = await db.edcapi_project_package.findAll({
            include:[
                {
                    model: db.edcapi_project, 
                    as: 'projects', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []},
                    where: {id: project_id},
                    include:[
                        {
                            model: db.edcapi_project_party,
                            as: 'parties', 
                            attributes: { exclude: ['createdAt','updatedAt']},
                            through: {attributes: []},
                            include:[
                                {
                                    model: db.edcapi_project_parties_roles,
                                    as: 'roles', 
                                    attributes: { exclude: ['createdAt','updatedAt']},
                                    through: {attributes: []},
                                    where: {funder: 'on'},
                                }
                            ]
                        }
                    ]
                }
            ],attributes: { exclude: ['createdAt','updatedAt']}
            });
            party_funder[0].projects[0].parties.forEach(element => {
                var objCatPartiesFunder = new Object();
                objCatPartiesFunder.id = element.id;
                objCatPartiesFunder.title = element.name;
                arrayPartiesFunder.push(objCatPartiesFunder);
            });
        return arrayPartiesFunder;
    },
    insertBudgetBreakdown: async function(data,budgetId){
        console.log("$$$$ insertBudgetBreakdown")
        var obj = JSON.parse(data);
        var relprojectBudgetBreakdown = new db.edcapi_project_budget_breakdown_budget();
        var projectBudgetBreakdown = new db.edcapi_project_budget_breakdown();
        var relbudgetBreakdownSourceParty = new db.edcapi_project_budget_breakdown_source_party_budget();
        var budgetBreakdownSourceParty = new db.edcapi_project_budget_breakdown_source_party();
        var source_party = await db.edcapi_project_party.findByPk(obj.budget_budgetBreakdown_sourceParty);

        projectBudgetBreakdown = await db.edcapi_project_budget_breakdown.create({
            description: (obj.budget_budgetBreakdown_description === '' ? null : obj.budget_budgetBreakdown_description),
            amount: (obj.budget_budgetBreakdown_amount_amount === '' ? null : obj.budget_budgetBreakdown_amount_amount),
            currency: (obj.budget_budgetBreakdown_amount_currency === '' ? null : obj.budget_budgetBreakdown_amount_currency),
            uri: (obj.budget_budgetBreakdown_uri === '' ? null : obj.budget_budgetBreakdown_uri),
            startDate: (obj.budget_budgetBreakdown_period_startDate === '' ? null : obj.budget_budgetBreakdown_period_startDate),
            endDate: (obj.budget_budgetBreakdown_period_endDate === '' ? null : obj.budget_budgetBreakdown_period_endDate),
            maxExtentDate: (obj.budget_budgetBreakdown_period_maxExtentDate === '' ? null : obj.budget_budgetBreakdown_period_maxExtentDate),
            durationInDays: (obj.budget_budgetBreakdown_period_durationInDays === '' ? null : obj.budget_budgetBreakdown_period_durationInDays),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectBudgetBreakdown){
            console.log("############## PROJECT BUDGET BREAKDOWN - " + JSON.stringify(projectBudgetBreakdown, null, 4))
            return relprojectBudgetBreakdown = await db.edcapi_project_budget_breakdown_budget.create({
                edcapiProjectBudgetBreakdownId: projectBudgetBreakdown.id,
                budget_id: budgetId, 
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectBudgetBreakdown){
                console.log("############## REL PROJECT BUDGET BREAKDOWN BUDGET - " + JSON.stringify(relprojectBudgetBreakdown, null, 4))
                return budgetBreakdownSourceParty = await db.edcapi_project_budget_breakdown_source_party.create({
                    relation_id: source_party.id,
                    name: source_party.name,
                    relation_identifier: source_party.identifier,
                    project_id : (obj.project_id === '' ? null : obj.project_id),
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(async function(budgetBreakdownSourceParty){
                    console.log("############## BUDGET BREAKDOWN SOURCE PARTY - " + JSON.stringify(budgetBreakdownSourceParty, null, 4))
                    return relbudgetBreakdownSourceParty = await db.edcapi_project_budget_breakdown_source_party_budget.create({
                        edcapiProjectBudgetBreakdownSourcePartyId: budgetBreakdownSourceParty.id,
                        edcapiProjectBudgetBreakdownId: projectBudgetBreakdown.id, 
                        createdAt : new Date(),
                        updatedAt : new Date()
                    }).then(async function(relbudgetBreakdownSourceParty){
                        console.log("############## REL BUDGET BREAKDOWN SOURCE PARTY - " + JSON.stringify(relbudgetBreakdownSourceParty, null, 4))
                        });
                    });
                });
            });
    },
    findBudgetBreakdown: async function(breakdown_id){
        console.log("%%%% findBudgetBreakdown")
        var project_budgetBreakdown = await db.edcapi_project_budget_breakdown.findAll({
            include:[
                {
                    model: db.edcapi_project_budget_breakdown_source_party,
                    as: 'sourceParty', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_budget_breakdown_budget_line,
                    as: 'budgetLines', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []},
                    include:[
                        {
                            model: db.edcapi_project_budget_breakdown_budget_lines_component,
                            as: 'c', 
                            attributes: { exclude: ['createdAt','updatedAt']},
                            through: {attributes: []}   
                        },
                        {
                            model: db.edcapi_project_budget_breakdown_budget_lines_measure,
                            as: 'measures', 
                            attributes: { exclude: ['createdAt','updatedAt']},
                            through: {attributes: []}   
                        }
                    ]   
                }
            ],attributes: { exclude: ['createdAt','updatedAt']},
            where : {id: breakdown_id}
            });
            console.log("%%%% findBudgetBreakdown " + JSON.stringify(project_budgetBreakdown,null,4))
            return project_budgetBreakdown;
    },
    updateBudgetBreakdown: async function(data){
        console.log("%%%% updateBudgetBreakdown")
        var obj = JSON.parse(data);

        var projectBudgetBreakdown = new db.edcapi_project_budget_breakdown();
        var source_party = await db.edcapi_project_party.findByPk(obj.budget_budgetBreakdown_sourceParty);

        projectBudgetBreakdown = await db.edcapi_project_budget_breakdown.findAll({
            include:[
                {
                    model: db.edcapi_project_budget_breakdown_source_party,
                    as: 'sourceParty', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                }
            ],attributes: { exclude: ['createdAt','updatedAt']},
            where : {id: obj.budget_breakdown_id}
        });
        
        projectBudgetBreakdown[0].update({
            description: (obj.budget_budgetBreakdown_description === '' ? null : obj.budget_budgetBreakdown_description),
            amount: (obj.budget_budgetBreakdown_amount_amount === '' ? null : obj.budget_budgetBreakdown_amount_amount),
            currency: (obj.budget_budgetBreakdown_amount_currency === '' ? null : obj.budget_budgetBreakdown_amount_currency),
            uri: (obj.budget_budgetBreakdown_uri === '' ? null : obj.budget_budgetBreakdown_uri),
            startDate: (obj.budget_budgetBreakdown_period_startDate === '' ? null : obj.budget_budgetBreakdown_period_startDate),
            endDate: (obj.budget_budgetBreakdown_period_endDate === '' ? null : obj.budget_budgetBreakdown_period_endDate),
            maxExtentDate: (obj.budget_budgetBreakdown_period_maxExtentDate === '' ? null : obj.budget_budgetBreakdown_period_maxExtentDate),
            durationInDays: (obj.budget_budgetBreakdown_period_durationInDays === '' ? null : obj.budget_budgetBreakdown_period_durationInDays),
            updatedAt : new Date()  
        }).then(async function(){
            return projectBudgetBreakdown[0].sourceParty[0].update({
                relation_id: source_party.id,
                name: source_party.name,
                relation_identifier: source_party.identifier,
                updatedAt : new Date()
            })
        });
    },
    deleteBudgetBreakdown: async function(budgetBreakdown_id){
        console.log("%%%% deleteBudgetBreakdown")
        await db.edcapi_project_budget_breakdown.destroy({
            where: {id: budgetBreakdown_id}
          })
        return true;
    },
    insertCompletionProject: async function(data){
        console.log("$$$$ insertCompletionProject")
        var obj = JSON.parse(data);
        var projectCompletion = new db.edcapi_project_completion();
        var relProjectCompletion = new db.edcapi_project_completion_project();

        projectCompletion = await db.edcapi_project_completion.create({
            endDate: (obj.completion_endDate === '' ? null : obj.completion_endDate),
            endDateDetails: (obj.completion_endDateDetails === '' ? null : obj.completion_endDateDetails),
            amount: (obj.completion_finalValue_amount === '' ? null : obj.completion_finalValue_amount),
            currency: (obj.completion_finalValue_currency === '' ? null : obj.completion_finalValue_currency),
            finalValueDetails: (obj.completion_finalValueDetails === '' ? null : obj.completion_finalValueDetails),
            finalScope: (obj.completion_finalScope === '' ? null : obj.completion_finalScope),
            finalScopeDetails: (obj.completion_finalScopeDetails === '' ? null : obj.completion_finalScopeDetails),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectCompletion){
            console.log("############## COMPLETION - " + JSON.stringify(projectCompletion, null, 4))
            return relProjectCompletion = await db.edcapi_project_completion_project.create({
                edcapiProjectCompletionId: projectCompletion.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relProjectCompletion){
                console.log("############## REL PROJECT COMPLETION - " + JSON.stringify(relProjectCompletion, null, 4))
            })
        }); 
    },
    updateCompletionProject: async function(data){
        console.log("%%%% updateCompletionProject")
        var obj = JSON.parse(data);
        
        var project_edcapi = await db.edcapi_project_package.findAll({
            include:[
                {
                    model: db.edcapi_project, 
                    as: 'projects', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []},
                    where: {id: obj.project_id},
                    include:[
                        {
                            model: db.edcapi_project_completion,
                            as: 'completion', 
                            attributes: { exclude: ['createdAt','updatedAt']},
                            through: {attributes: []}   
                        },
                    ]
                }
            ],attributes: { exclude: ['createdAt','updatedAt']}
        });

        project_edcapi[0].projects[0].completion[0].update({
            endDate: (obj.completion_endDate === '' ? null : obj.completion_endDate),
            endDateDetails: (obj.completion_endDateDetails === '' ? null : obj.completion_endDateDetails),
            amount: (obj.completion_finalValue_amount === '' ? null : obj.completion_finalValue_amount),
            currency: (obj.completion_finalValue_currency === '' ? null : obj.completion_finalValue_currency),
            finalValueDetails: (obj.completion_finalValueDetails === '' ? null : obj.completion_finalValueDetails),
            finalScope: (obj.completion_finalScope === '' ? null : obj.completion_finalScope),
            finalScopeDetails: (obj.completion_finalScopeDetails === '' ? null : obj.completion_finalScopeDetails),
            updatedAt : new Date()
        });
    },
    insertRelatedContractingProcessProject: async function(data){
        console.log("$$$$ insertRelatedContractingProcessProject")
        var obj = JSON.parse(data);
        var projectRelatedContractingProcess = new db.edcapi_project_related_contracting_process();
        var relProjectRelatedContractingProcess = new db.edcapi_project_related_contracting_process_project();

        projectRelatedContractingProcess = await db.edcapi_project_related_contracting_process.create({
            ocid: (obj.relatedprocedure_identifier === '' ? null : obj.relatedprocedure_identifier),
            title: (obj.title === '' ? null : obj.title),
            contractingProcessId: (obj.contractingprocess_id === '' ? null : obj.contractingprocess_id),
            tenderId: (obj.tender_id === '' ? null : obj.tender_id),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectRelatedContractingProcess){
            console.log("############## RELATED CONTRACTING PROCESS - " + JSON.stringify(projectRelatedContractingProcess, null, 4))
            return relProjectRelatedContractingProcess = await db.edcapi_project_related_contracting_process_project.create({
                edcapiProjectRelatedContractingProcessId: projectRelatedContractingProcess.id,
                project_id: obj.project_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relProjectRelatedContractingProcess){
                console.log("############## REL RELATED CONTRACTING PROCESS - " + JSON.stringify(relProjectRelatedContractingProcess, null, 4))
            })
        }); 
    },
    updateRelatedContractingProcessProject: async function(data){
        console.log("$$$$ updateRelatedContractingProcessProject")
        var obj = JSON.parse(data);
        var related_contracting_process = await db.edcapi_project_related_contracting_process.findByPk(obj.contracting_process_id); 
        related_contracting_process.update({
            ocid: (obj.relatedprocedure_identifier === '' ? null : obj.relatedprocedure_identifier),
            title: (obj.title === '' ? null : obj.title),
            contractingProcessId: (obj.contractingprocess_id === '' ? null : obj.contractingprocess_id),
            tenderId: (obj.tender_id === '' ? null : obj.tender_id),
            updatedAt : new Date()
        });
    },
    deleteRelatedContractingProcessProject: async function(relatedContractingProcess_id){
        console.log("%%%% deleteRelatedContractingProcessProject")
        await db.edcapi_project_related_contracting_process.destroy({
            where: {id: relatedContractingProcess_id}
          })
        return true;
    },
    findRelatedContractingProcess: async function(projectID){
        console.log("%%%% findRelatedContractingProcess")
        var arrayOcdsIds = new Array();
        await findProjects(projectID).then(value =>{
            if(value[0].projects[0].contractingProcesses !== undefined){
                value[0].projects[0].contractingProcesses.forEach(element => {
                    var objOcdsId = new Object();
                    objOcdsId.id = element.ocid;
                    arrayOcdsIds.push(objOcdsId);  
                });
            }
        });
        if(arrayOcdsIds.length > 0 && arrayOcdsIds.length !== undefined){
            return arrayOcdsIds;
        }else{
            return false;
        }
    },
    insertBudgetLinesComponent: async function(data){
        console.log("$$$$ insertBudgetLinesComponent")
        var obj = JSON.parse(data);

        budgetLine = await db.edcapi_project_budget_breakdown_budget_line.create({ 
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(budgetLine){ 
            console.log("############## BUDGET LINE - " + JSON.stringify(budgetLine, null, 4))
            return relBudgetLineBudget = await db.edcapi_project_budget_breakdown_budget_line_budget.create({
                edcapiProjectBudgetBreakdownBudgetLineId: budgetLine.id,
                edcapiProjectBudgetBreakdownId: obj.budget_breakdown_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relBudgetLineBudget){
                console.log("############## REL BUDGET LINE - " + JSON.stringify(relBudgetLineBudget, null, 4))
                return projectBudgetLinesComponent = await db.edcapi_project_budget_breakdown_budget_lines_component.create({
                    year: (obj.budget_budgetBreakdown_budgetLines_components_year === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_year),
                    branch: (obj.budget_budgetBreakdown_budgetLines_components_branch === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_branch),
                    kBranch: (obj.budget_budgetBreakdown_budgetLines_components_key_branch === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_branch),
                    responsibleUnit: (obj.budget_budgetBreakdown_budgetLines_components_resposibleUnit === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_resposibleUnit),
                    kResponsibleUnit: (obj.budget_budgetBreakdown_budgetLines_components_key_resposibleUnit === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_resposibleUnit),
                    finality: (obj.budget_budgetBreakdown_budgetLines_components_finality === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_finality),
                    kFinality: (obj.budget_budgetBreakdown_budgetLines_components_key_finality === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_finality),
                    function: (obj.budget_budgetBreakdown_budgetLines_components_function === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_function),
                    kFunction: (obj.budget_budgetBreakdown_budgetLines_components_key_function === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_function),
                    subFunction: (obj.budget_budgetBreakdown_budgetLines_components_subFunction === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_subFunction),
                    kSubFunction: (obj.budget_budgetBreakdown_budgetLines_components_key_subFunction === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_subFunction),
                    instAct: (obj.budget_budgetBreakdown_budgetLines_components_institutionalActivity === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_institutionalActivity),
                    kInstAct: (obj.budget_budgetBreakdown_budgetLines_components_key_institutionalActivity === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_institutionalActivity),
                    budgetProgram: (obj.budget_budgetBreakdown_budgetLines_components_budgetProgram === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_budgetProgram),
                    kBudgetProgram: (obj.budget_budgetBreakdown_budgetLines_components_key_budgetProgram === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_budgetProgram),
                    spendingObject: (obj.budget_budgetBreakdown_budgetLines_components_spendingObject === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_spendingObject),
                    kSpendingObject: (obj.budget_budgetBreakdown_budgetLines_components_key_spendingObject === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_spendingObject),
                    spendingType: (obj.budget_budgetBreakdown_budgetLines_components_spendingType === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_spendingType),
                    kSpendingType: (obj.budget_budgetBreakdown_budgetLines_components_key_spendingType === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_spendingType),
                    budgetSource: (obj.budget_budgetBreakdown_budgetLines_components_budgetSource === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_budgetSource),
                    kBudgetSource: (obj.budget_budgetBreakdown_budgetLines_components_key_budgetSource === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_budgetSource),
                    region: (obj.budget_budgetBreakdown_budgetLines_components_region === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_region),
                    kRegion: (obj.budget_budgetBreakdown_budgetLines_components_key_region === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_region),
                    portfolio: (obj.budget_budgetBreakdown_budgetLines_components_portfolio === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_portfolio),
                    kPortfolio: (obj.budget_budgetBreakdown_budgetLines_components_key_portfolio === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_key_portfolio),
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(async function(projectBudgetLinesComponent){
                    console.log("############## BUDGET LINE COMPONENT - " + JSON.stringify(projectBudgetLinesComponent, null, 4))
                    return relprojectBudgetLinesComponent = await db.edcapi_project_budget_breakdown_budget_lines_component_budget.create({
                        edcapiProjectBudgetBreakdownBudgetLinesComponentId: projectBudgetLinesComponent.id,
                        edcapiProjectBudgetBreakdownBudgetLineId: budgetLine.id,
                        createdAt : new Date(),
                        updatedAt : new Date()
                    }).then(async function(relprojectBudgetLinesComponent){
                        console.log("############## REL BUDGET LINE COMPONENT LINE - " + JSON.stringify(relprojectBudgetLinesComponent, null, 4))
                    });
                })
            })
        })
    },
    generateRecordPackage:function(ocids,host){
        console.log("%%%% generateRecordPackage")
        return findRecordPackage(ocids, host);
    },
    updatePrefix: async function(prefijo){
        console.log("%%%% updatePrefix")
        var prefix = await db.edcapi_project_prefix.findByPk(1);
        prefix.update({
            prefix: prefijo,
            description: "Prefijo actualizado.",
            updatedAt : new Date()      
        });
        
    },
    updatePublishedDate: async function(projectId,publisher){
        console.log("%%%% updatePublishedDate")
        var project_package = await db.edcapi_project_package.findAll({
            include:[
                {
                    model: db.edcapi_project, 
                    as: 'projects', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []},
                    where: {id: projectId},
                },
                {
                    model: db.edcapi_publisher,
                    as: 'publisher', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}
                }
            ],attributes: { exclude: ['createdAt','updatedAt']}
        });
        project_package[0].update({
            publishedDate: dateFortmatGMT(Date.now()),
            updatedAt : new Date()      
        });
        project_package[0].publisher[0].update({
            name : publisher.publisherName,
            scheme :  publisher.publisherScheme,
            uid : publisher.publisherUid,
            uri :  publisher.publisherUri,
            updatedAt : new Date()      
        });   

    },
    findProjectAPI:async function(project_id){
        console.log("$$$$ findProjectAPI  X1 " + project_id)
        var project = null;
        await findProjects(project_id).then(value =>{
            console.log("$$$$ findProjectAPI X2 " + JSON.stringify(value,null,4))
            project = value;
        });
        return project;
    },
    findProjectsAPI: function(){
        console.log("$$$$ findProjectAPI")
        return findProjects();
    },
    findBudgetLineComponent: async function(component_id){
        console.log("%%%% findBudgetLineComponent")
        var component = await db.edcapi_project_budget_breakdown_budget_lines_component.findByPk(component_id);
        return component;
    },
    updateBudgetLineComponents: async function(data){
        console.log("%%%% updateBudgetLineComponents")
        var obj = JSON.parse(data);
        var budget_line = await db.edcapi_project_budget_breakdown_budget_lines_component.findByPk(obj.budget_line_component_id);
        budget_line.update({
            year: (obj.budget_budgetBreakdown_budgetLines_components_year === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_year, 10)),
            branch: (obj.budget_budgetBreakdown_budgetLines_components_branch === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_branch),
            kBranch: (obj.budget_budgetBreakdown_budgetLines_components_key_branch === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_branch, 10)),
            responsibleUnit: (obj.budget_budgetBreakdown_budgetLines_components_resposibleUnit === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_resposibleUnit),
            kResponsibleUnit: (obj.budget_budgetBreakdown_budgetLines_components_key_resposibleUnit === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_resposibleUnit, 10)),
            finality: (obj.budget_budgetBreakdown_budgetLines_components_finality === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_finality),
            kFinality: (obj.budget_budgetBreakdown_budgetLines_components_key_finality === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_finality, 10)),
            function: (obj.budget_budgetBreakdown_budgetLines_components_function === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_function),
            kFunction: (obj.budget_budgetBreakdown_budgetLines_components_key_function === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_function, 10)),
            subFunction: (obj.budget_budgetBreakdown_budgetLines_components_subFunction === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_subFunction),
            kSubFunction: (obj.budget_budgetBreakdown_budgetLines_components_key_subFunction === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_subFunction, 10)),
            instAct: (obj.budget_budgetBreakdown_budgetLines_components_institutionalActivity === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_institutionalActivity),
            kInstAct: (obj.budget_budgetBreakdown_budgetLines_components_key_institutionalActivity === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_institutionalActivity, 10)),
            budgetProgram: (obj.budget_budgetBreakdown_budgetLines_components_budgetProgram === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_budgetProgram),
            kBudgetProgram: (obj.budget_budgetBreakdown_budgetLines_components_key_budgetProgram === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_budgetProgram, 10)),
            spendingObject: (obj.budget_budgetBreakdown_budgetLines_components_spendingObject === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_spendingObject),
            kSpendingObject: (obj.budget_budgetBreakdown_budgetLines_components_key_spendingObject === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_spendingObject, 10)),
            spendingType: (obj.budget_budgetBreakdown_budgetLines_components_spendingType === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_spendingType),
            kSpendingType: (obj.budget_budgetBreakdown_budgetLines_components_key_spendingType === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_spendingType, 10)),
            budgetSource: (obj.budget_budgetBreakdown_budgetLines_components_budgetSource === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_budgetSource),
            kBudgetSource: (obj.budget_budgetBreakdown_budgetLines_components_key_budgetSource === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_budgetSource, 10)),
            region: (obj.budget_budgetBreakdown_budgetLines_components_region === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_region),
            kRegion: (obj.budget_budgetBreakdown_budgetLines_components_key_region === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_region, 10)),
            portfolio: (obj.budget_budgetBreakdown_budgetLines_components_portfolio === '' ? null : obj.budget_budgetBreakdown_budgetLines_components_portfolio),
            kPortfolio: (obj.budget_budgetBreakdown_budgetLines_components_key_portfolio === '' ? null : parseInt(obj.budget_budgetBreakdown_budgetLines_components_key_portfolio, 10)),
            updatedAt : new Date()
        });
        return budget_line;
    },
    deleteBudgetLineComponents: async function(line_id){
        console.log("%%%% deleteBudgetLineComponents")
        await db.edcapi_project_budget_breakdown_budget_line.destroy({
            where: {id: line_id}
          })
        return true;
    },
    insertBudgetLinesMeasure: async function(data){
        console.log("$$$$ insertBudgetLinesMeasure")
        var obj = JSON.parse(data);
        
        projectBudgetLinesMeasure = await db.edcapi_project_budget_breakdown_budget_lines_measure.create({
            type: (obj.budget_budgetBreakdown_budgetLines_measures_type === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_type),
            amount: (obj.budget_budgetBreakdown_budgetLines_measures_amount === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_amount),
            currency: (obj.budget_budgetBreakdown_budgetLines_measures_currency === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_currency),
            date: (obj.budget_budgetBreakdown_budgetLines_measures_update === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_update),
            createdAt : new Date(),
            updatedAt : new Date()
        }).then(async function(projectBudgetLinesMeasure){
            console.log("############## BUDGET LINES MEASURE - " + JSON.stringify(projectBudgetLinesMeasure, null, 4))
            return relprojectBudgetLinesMeasure = await db.edcapi_project_budget_breakdown_budget_lines_measure_budget.create({
                edcapiProjectBudgetBreakdownBudgetLinesMeasureId: projectBudgetLinesMeasure.id,
                edcapiProjectBudgetBreakdownBudgetLineId: obj.budget_line_id,
                createdAt : new Date(),
                updatedAt : new Date()
            }).then(async function(relprojectBudgetLinesMeasure){
                console.log("############## REL BUDGET LINES MEASURE- " + JSON.stringify(relprojectBudgetLinesMeasure, null, 4))
            });
        });

    },
    findBudgetLineMeasure: async function(budget_line_id){
        console.log("%%%% findBudgetLineMeasure")
        var budget_line = await db.edcapi_project_budget_breakdown_budget_line.findAll({
            attributes: { exclude: ['createdAt','updatedAt']},
            through: {attributes: []},
            where: {id: budget_line_id},
            include:[
                {
                    model: db.edcapi_project_budget_breakdown_budget_lines_component,
                    as: 'c', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                },
                {
                    model: db.edcapi_project_budget_breakdown_budget_lines_measure,
                    as: 'measures', 
                    attributes: { exclude: ['createdAt','updatedAt']},
                    through: {attributes: []}   
                }
            ]
            
        });
        return budget_line;
    },
    findMeasure: async function(measure_id){
        console.log("%%%% findBudgetLineMeasure")
        var measure = await db.edcapi_project_budget_breakdown_budget_lines_measure.findByPk(measure_id);
        return measure;
    },
    updateMeasure: async function(data){
        console.log("%%%% updateMeasure")
        var obj = JSON.parse(data);
        var measure = await db.edcapi_project_budget_breakdown_budget_lines_measure.findByPk(obj.budget_line_measure_id);
        measure.update({
            type: (obj.budget_budgetBreakdown_budgetLines_measures_type === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_type),
            amount: (obj.budget_budgetBreakdown_budgetLines_measures_amount === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_amount),
            currency: (obj.budget_budgetBreakdown_budgetLines_measures_currency === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_currency),
            date: (obj.budget_budgetBreakdown_budgetLines_measures_update === '' ? null : obj.budget_budgetBreakdown_budgetLines_measures_update),
            updatedAt : new Date()
        });
        return measure;    
    },
    deleteBudgetLineMeasure: async function(measure_id){
        console.log("%%%% deleteBudgetLineMeasure")
        await db.edcapi_project_budget_breakdown_budget_lines_measure.destroy({
            where: {id: measure_id}
          })
        return true;
    },
    
}

async function findProjects(projectId) {
    console.log('calling...');
    console.log('findingProjects...');
    var options = {};
    if(projectId) {
        options = { where:{ id:projectId } };
    }
    //console.log("##### " + JSON.stringify(options.where))
    var project_edcapi = await db.edcapi_project_package.findAll({
        include:[
            {
                model: db.edcapi_project, 
                as: 'projects', 
                attributes: { exclude: ['createdAt','updatedAt']},
                through: {attributes: []},
                where: options.where,
                include:[
                    {
                        model: db.edcapi_project_period,
                        as: 'period', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_project_asset_lifetime,
                        as: 'assetLifetime', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_budget,
                        as: 'budget', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []},
                        include:[
                            {
                                model: db.edcapi_budget_amount,
                                as: 'amount', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_budget_breakdown,
                                as: 'budgetBreakdown', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []},
                                include:[
                                    {
                                        model: db.edcapi_project_budget_breakdown_source_party,
                                        as: 'sourceParty', 
                                        attributes: { exclude: ['createdAt','updatedAt']},
                                        through: {attributes: []}   
                                    },
                                    {
                                        model: db.edcapi_project_budget_breakdown_budget_line,
                                        as: 'budgetLines', 
                                        attributes: { exclude: ['createdAt','updatedAt']},
                                        through: {attributes: []},
                                        include:[
                                            {
                                                model: db.edcapi_project_budget_breakdown_budget_lines_component,
                                                as: 'c', 
                                                attributes: { exclude: ['createdAt','updatedAt']},
                                                through: {attributes: []}   
                                            },
                                            {
                                                model: db.edcapi_project_budget_breakdown_budget_lines_measure,
                                                as: 'measures', 
                                                attributes: { exclude: ['createdAt','updatedAt']},
                                                through: {attributes: []}   
                                            }
                                        ] 
                                    }
                                ]   
                            }
                        ]  
                    },
                    {
                        model: db.edcapi_project_party,
                        as: 'parties', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []},
                        include:[
                            {
                                model: db.edcapi_project_parties_identifier,
                                as: 'identifierR', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_parties_additional_identifier,
                                as: 'additionalIdentifiers', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_parties_address,
                                as: 'address', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_parties_contact_point,
                                as: 'contactPoint', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_parties_roles,
                                as: 'roles', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            }
                        ]
                    },
                    {
                        model: db.edcapi_project_related_project,
                        as: 'relatedProjects', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_project_additional_classification,
                        as: 'additionalClassifications', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_project_document,
                        as: 'documents', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_location_project,
                        as: 'locations', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []},
                        include:[
                            {
                                model: db.edcapi_project_location_coordinate,
                                as: 'coordinates', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            },
                            {
                                model: db.edcapi_project_location_address,
                                as: 'address', 
                                attributes: { exclude: ['createdAt','updatedAt']},
                                through: {attributes: []}   
                            }
                        ]
                    },
                    {
                        model: db.edcapi_project_completion,
                        as: 'completion', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                    {
                        model: db.edcapi_project_related_contracting_process,
                        as: 'contractingProcesses', 
                        attributes: { exclude: ['createdAt','updatedAt']},
                        through: {attributes: []}   
                    },
                ]
            },
            {
                model: db.edcapi_publisher,
                as: 'publisher', 
                attributes: { exclude: ['createdAt','updatedAt']},
                through: {attributes: []}
            }
        ],
        order: [['id', 'ASC']],
        attributes: { exclude: ['createdAt','updatedAt']}
        
        });
    return project_edcapi;
};

function findRecordPackage(ocids,host){
    console.log('##### findRecordPackage');
    var arrayContractingProcess = new Array();
    const start = async () => {
        await asyncForEach(ocids, async (ocid) => {
            var objRelease = new Object();
            var objContractingProcess = new Object();
            let record = require('../../io/record')(db_conf.edca_db);
            let log = await db_conf.edca_db.oneOrNone(`select version,release_file from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1) order by id desc limit 1`, [ocid.id]);
            var recordPackage = await record.getPackage(log.version, log.release_file, host);
            if(recordPackage !== undefined){
                objRelease.id = recordPackage.records[0].compiledRelease.id;
                objRelease.tag = [recordPackage.records[0].compiledRelease.tag[0]];
                objRelease.date = dateFortmatGMT(recordPackage.records[0].compiledRelease.date);
                objRelease.url = recordPackage.uri;
                objContractingProcess.id = ocid;
                objContractingProcess.releases = objRelease    
                arrayContractingProcess.push(objContractingProcess) 
            }
        });
         return  arrayContractingProcess;
      };
    return start();
};

function dateFortmatGMT(fecha) {
    return moment(fecha).format();
};

async function asyncForEach(array, callback) {
    for (let index = 0; index < array.length; index++) {
        await callback(array[index], index, array);
    }
};