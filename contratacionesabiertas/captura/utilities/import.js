const Stages = {
    planning: 1,
    tender: 2,
    award: 3,
    contract: 4,
    implementation: 5
};

const justificaciones = {
    'Invitación a cuando menos tres personas': {
        'Artículo 41 fracción I RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción I del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción II RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción II del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción III RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción III del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción IV RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción IV del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción V RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción V del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción VI RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción VI del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción VII RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción VII del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción VIII RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción VIII del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción IX RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción IX del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción X RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción X del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción XI RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción XI del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción XII RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 41 fracción I del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 42 RAAS ITP': 'Se propone que se realice un procedimiento de contratación de invitación a cuando menos tres personas, de conformidad con lo dispuesto en el artículo 42 del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales'
       
    },
    'Adjudicación directa': {
        'Artículo 41 fracción I RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción I del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción II RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción II del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción III RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción III del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 41 fracción IV RAAS AD': 'Se propone que se realice un procedimiento de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción IV del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción V RAAS AD': 'Se propone que se realice un procedimiento de contratación de de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción V del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción VI RAAS AD': 'Se propone que se realice un procedimiento de contratación de de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción VI del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción VII RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción VII del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción VIII RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción VIII del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción IX RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción IX del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción X RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción X del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción XI RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción XI del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales' ,
        'Artículo 41 fracción XII RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 41 fracción XII del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales',
        'Artículo 42 RAAS AD': 'Se propone que se realice un procedimiento de contratación de adjudicación directa, de conformidad con lo dispuesto en el artículo 42 del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales'
    },
    'Licitación pública': {
        'Artículo 26 fracción I RAAS': 'Se propone que se realice un procedimiento de contratación de licitación pública, de conformidad con lo dispuesto en el artículo 26 fracción I del Reglamento de Adquisiciones, Arrendamientos y Servcios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales'
    }
};


/**
 * Importaciones masivas a una contratación
 * @param {Number} contractingproessid ID de la contratación a la cual se importaran los datos
 * @param {IDBDatabase} database Instancia de la base de datos
 * @param {Number} numberStage Número del etapa(cuando solo se va actualizar una etapa)
 * @param {Number} registerid Registro actual al que se ligaran los registros(para adjudicaciones y contratos)
 */
function Import(contractingproessid, database, numberStage, registerid) {
    const db = database;
    const cpid = parseInt(contractingproessid);
    const stage = numberStage ? parseInt(numberStage): undefined;
    const currentId = registerid;

    if(isNaN(cpid) || cpid === 0) throw Error('No se ha especificado la contratación');

    /**
     * Importar todo
     * @param {Object} json Json a importar
     */
    this.importAll = async function(json){
        if(json.releases) 
        {
            importAll(json.releases[0]);
        } else{
            console.log('importando contratacion');

            if (!stage) {
                if (json.parties) await importParties(json.parties);
                if (json.planning) await importPlanning(json.planning);
                if (json.tender) await importTender(json.tender);
                if (json.awards) await importAwards(json.awards);
                if (json.contracts) await importContracts(json.contracts);
                if (json.relatedProcesses) await importRelatedProcesses(json.relatedProcesses);

                if (json.ocid) {
                    await processRecords('contractingprocess', ['id'], {
                        ocid: async (ocid, result) => {
                            // impedir que se repitan los ocid
                            result.ocid = await uniqueOcid(ocid);
                        }
                    }, { id: cpid }, [json]);
                }
            } else {
                // importacion para una etapa en especifico
                switch (stage) {
                    case Stages.planning: await importPlanning(json); break;
                    case Stages.tender: await importTender(json); break;
                    case Stages.award: await importAwards([json], currentId); break;
                    case Stages.contract: await importContracts([json], currentId); break;
                    case Stages.implementation: await importImplementation(json, currentId); break;
                }
            }

            console.log('contratacion importada');
        }
    }

    let uniqueOcid = async function(ocid) {
        let unique = await checkIfExists('contractingprocess', {ocid: ocid});
        let newOcid = unique && unique !== cpid ? ocid + '(1)' : ocid;
        if(ocid !== newOcid){
            // se revalida
            return uniqueOcid(newOcid);
        } else{
            return newOcid;
        }
    }
    

    this.importParties = async function(parties) {
        let schema = {
            name: 'name',
            id: 'partyid',
            identifier: {
                scheme: 'identifier_scheme',
                id: 'identifier_id',
                legalName: 'identifier_legalname',
                legalPersonality: (legalPersonality, result) => result.naturalPerson = legalPersonality === 'naturalPerson',
                givenName: 'givenname',
                patronymicName: 'surname',
                matronymicName: 'additionalsurname',
            },
            address: {
                streetAddress: 'address_streetaddress',
                locality: 'address_locality',
                region: 'address_region',
                postalCode: 'address_postalcode',
                countryName: 'address_countryname'
            },
            contactPoint: {
                name: 'contactpoint_name',
                email: 'contactpoint_email',
                telephone: 'contactpoint_telephone',
                faxNumber: 'contactpoint_faxnumber',
                url: 'contactpoint_url',
                type: 'contactpoint_type',
                givenName: 'contactpoint_givenname',
                patronymicName: 'contactpoint_surname',
                matronymicName: 'contactpoint_additionalsurname'
            },
            position: 'position'
        };
        
        await deleteAll(['roles','parties']);
        await processRecords('parties',['contractingprocess_id', 'partyid'], schema, {contractingprocess_id: cpid}, parties, async party => {
            // agregar roles al actor
            if(party.roles){
                let schemaRoles = {},
                    values = {};
                party.roles.map(x => {
                    values[x] = true;
                    schemaRoles[x] = x.toLowerCase();
                });
                await processRecords('roles', ['parties_id'], schemaRoles, {parties_id: party.id, contractingprocess_id: cpid}, [values]);
            }

            // agregar miembros
            if(party.memberOf) {
                await processRecords('memberof', ['parties_id'], {
                    id: async (id, result) => {
                        result.memberofid = id;
                        result.parties_id = await checkIfExists('parties', {partyid: id});
                    },
                }, {
                    principal_parties_id: party.id
                }, party.memberOf);
            }

            // agregar puntos de contacto adicional
            if(party.additionalContactPoints) {
                await processRecords('additionalcontactpoints', ['party_id'], 
                {
                    type: 'type',
                    name: 'name',
                    givenName: 'givenname',
                    patronymicName: 'surname',
                    matronymicName: 'additionalsurname',
                    email: 'email',
                    telephone: 'telephone',
                    faxNumber: 'faxnumber',
                    url: 'url'
                }, 
                {
                    party_id: party.id
                }, 
                party.additionalContactPoints);
            }
        });
    }

    /**
     * Importar etapa de planeación
     */
    this.importPlanning = async function(planning){
        let schema = {
            rationale: 'rationale',
            hasquotes: 'hasquotes',
            numberofbeneficiaries: 'numberofbeneficiaries'
        };
        await deleteAll(['planning', 'requestforquotes', 'planningdocuments', 'budget', 'budgetbreakdown']);
        await processRecords('planning', ['contractingprocess_id'], schema,{contractingprocess_id: cpid, hasquotes: planning.requestsForQuotes !== undefined}, [planning]);
        if(!planning.id) planning.id = await checkIfExists('planning', {contractingprocess_id: cpid});
        if(planning.documents) await importDocuments(Stages.planning, planning.documents,[planning.id]);
        if(planning.requestsForQuotes) await importRequestsForQuotes(planning.requestsForQuotes, planning.id);
        if(planning.budget) await importBudget(planning.budget, planning.id);
    }

    /**
     * Importar licitacion
     */
    this.importTender = async function(tender) {
        let schema = {
            id: 'tenderid',
            title: 'title',
            description: 'description',
            status: 'status',
            value: {
                amount: 'value_amount',
                currency: 'value_currency'
            },
            minValue: {
                amount: 'minvalue_amount',
                currency: 'minvalue_currency'
            },
            procurementMethod: 'procurementmethod',
            procurementMethodDetails: 'procurementmethod_details',
            mainProcurementCategory: 'mainprocurementcategory',
            procurementMethodRationale: async (relationale, result) => {
                let justificacion = justificaciones[result.procurementmethod_details];
                if(justificacion){
                    let id = Object.keys(justificacion).find(x => justificacion[x] === relationale);
                    result.procurementmethod_rationale_id =  id ? id : '';
                }
                result.procurementmethod_rationale = relationale;
            },
            additionalProcurementCategories: (category, result) => {
                let croc;
                switch (category[0]){
                    case 'goodsAcquisition':
                        croc = 'Adquisición de bienes';
                        break;
                    case 'goodsLease':
                        croc = 'Arrendamiento de bienes';
                        break;
                    case 'services':
                        croc = 'Servicios';
                        break;
                    case 'worksRelatedServices':
                        croc = 'Servicios relacionados con obras públicas';
                        break;
                    case 'works':
                        croc = 'Obras públicas';
                        break;
                    default:
                        croc = category[0];
                        break;
                }  
                result.additionalprocurementcategories = croc;
            },
            awardCriteria: 'awardcriteria',
            awardCriteriaDetails: 'awardcriteria_details',
            submissionMethod: async (submissionMethod, result) => {
                result.submissionmethod = submissionMethod ? submissionMethod[0] : '';
            },
            submissionMethodDetails: 'submissionmethod_details',
            tenderPeriod: {
                startDate: 'tenderperiod_startdate',
                endDate: 'tenderperiod_enddate'
            },
            enquiryPeriod: {
                startDate: 'enquiryperiod_startdate',
                endDate: 'enquiryperiod_enddate'
            },
            hasEnquiries: 'hasenquiries',
            eligibilityCriteria: 'eligibilitycriteria',
            awardPeriod: {
                startDate: 'awardperiod_startdate',
                endDate: 'awardperiod_enddate'
            },
            numberOfTenderers: 'numberoftenderers'
        };

        await deleteAll(['tender', 'tenderitem', 'tenderdocuments','tendermilestone', 'tenderamendmentchanges', 'clarificationmeeting']);
        await processRecords('tender', ['contractingprocess_id'], schema,{contractingprocess_id: cpid}, [tender], async tender => {
            // Registrar documentos, modificaciones, hitos y aclaraciones

            await importItems(Stages.tender, tender.items, [tender.id]);
            await importDocuments(Stages.tender, tender.documents, [tender.id]);
            await importMilestones(Stages.tender, tender.milestones, [tender.id]);
            await importAmendments(Stages.tender, tender.amendments, [tender.id]);
            await importClarificationMeetings(tender.clarificationMeetings, tender.id);
        });
    }


    /**
     * Importar adjudicaciones
     */
    this.importAwards = async function(awards, awardid) {
        await deleteAll(['award', 'awarditem', 'awarddocuments', 'awardamendmentchanges']);
        if(!awards) return;

        let schema = {
            id: 'awardid',
            title: 'title',
            description: 'description',
            status: 'status',
            date: 'award_date',
            value: {
                amount: 'value_amount',
                currency: 'value_currency',
                netAmount: 'value_amountnet'
            },
            contractPeriod: {
                startDate: 'contractperiod_startdate',
                endDate: 'contractperiod_enddate'
            },
            rationale: 'rationale'
        };

        let identifiers = ['contractingprocess_id', 'awardid'];
        let annexes = {contractingprocess_id: cpid};

        // cuando se especifca el id de adudicacion se debe agregar a la configuracion
        if(awardid){
            identifiers = ['contractingprocess_id', 'id'];
            annexes.id = awardid;
        }

        
        await processRecords('award',identifiers , schema, annexes, awards, async award => {
            await processRecords('awardsupplier', ['parties_id', 'award_id'],{
                id: async (supplier, result) => {
                    result.parties_id = await checkIfExists('parties', {partyid: supplier, contractingprocess_id: cpid});
                }
            }, {award_id: award.id}, award.suppliers);
            await importItems(Stages.award, award.items, [award.id]);
            await importDocuments(Stages.award, award.documents, [award.id]);
            await importAmendments(Stages.award, award.amendments, [award.id]);
        });

        
    }

    /**
     * Importar contratos
     * @param {Array} contracts Contratos a importar
     * @param {Number} contractid (Opcional) Id del contrato al que se ligaran
     */
    this.importContracts = async function(contracts, contractid) {
        await deleteAll(['contract', 'contractamendmentchanges', 'contractitem', 'contractdocuments', 'guarantees']);
        await deleteAll(['implementation', 'implementationdocuments', 'implementationtransactions', 'implementationmilestone']);
        if(!contracts) return;

        let schema = {
            id: 'contractid',
            awardID: async (id, result) => {
                result.awardid = await checkIfExists('award', {contractingprocess_id: cpid, awardid: id});
            },
            title: 'title',
            description: 'description',
            status: 'status',
            period: {
                startDate: 'period_startdate',
                endDate: 'period_enddate'
            },
            value: {
                netAmount: 'value_amountnet',
                amount: 'value_amount',
                currency: 'value_currency',
                exchangeRates: async (exchanges, result) => {
                    if(exchanges){
                        result.exchangerate_currency = exchanges[0].currency;
                        result.exchangerate_rate = exchanges[0].rate;
                        result.exchangerate_date = exchanges[0].date;
                        result.exchangerate_source = exchanges[0].source;
                    }
                }
            },
            dateSigned: 'datesigned',
            surveillanceMechanisms : async (surve, result) => {
                if(surve) result.surveillancemechanisms = surve[0];
            }
        };

        let identifiers = ['contractingprocess_id', 'contractid'];
        let annexes =  {contractingprocess_id: cpid};
        if(contractid){
            identifiers = ['contractingprocess_id', 'id'];
            annexes.id = contractid;
        }

       
        await processRecords('contract',identifiers , schema, annexes, contracts, async contract => {
            await importItems(Stages.contract, contract.items, [contract.id]);
            await importAmendments(Stages.contract, contract.amendments, [contract.id]);
            await importDocuments(Stages.contract, contract.documents, [contract.id]);

            // importar ejecuciones
            await importImplementation(contract.implementation, contract.id);

            // importar garantias
            await processRecords('guarantees', ['contractingprocess_id', 'contract_id' ,'guarantee_id'], {
                id: 'guarantee_id',
                type: 'type',
                date: 'date',
                obligations: 'obligations',
                value: {
                    amount: 'value',
                    currency: 'currency'
                },
                guarantor: {
                    id: async (id, result) => {
                        result.guarantor = await checkIfExists('parties', {contractingprocess_id: cpid, partyid: id});
                    }
                },
                period: {
                    startDate: 'guaranteeperiod_startdate',
                    endDate: 'guaranteeperiod_enddate'
                }  
            }, {contractingprocess_id: cpid, contract_id: contract.id}, contract.guarantees);
        });
    }

    /**
     * Importar ejecuciones a una contratacion
     */
    this.importImplementation = async function(implementation, contractid){
        if(!implementation) return;

        await processRecords('implementation', ['contractingprocess_id','contract_id'], {status: 'status'}, {contract_id: contractid, contractingprocess_id: cpid}, [implementation], async impl =>{
            await importMilestones(Stages.implementation, impl.milestones, [impl.id]);
            await importDocuments(Stages.implementation, impl.documents, [impl.id]);
            await processRecords('implementationtransactions',['contractingprocess_id', 'implementation_id', 'transactionid'], {
                id: 'transactionid',
                source: 'source',
                date: 'implementation_date',
                value: {
                    netAmount: 'value_amountnet',
                    amount: 'value_amount',
                    currency: 'value_currency'
                },
                payer: {
                    id: 'payer_id',
                    name: 'payer_name'
                },
                payee: {
                    id: 'payee_id',
                    name: 'payee_name'
                },
                paymentMethod: 'payment_method'
            }, {contractingprocess_id: cpid, implementation_id: impl.id}, impl.transactions);
        });
    }

    /**
     * Importar procedimientos relacionados
     */
    this.importRelatedProcesses = async function(relatedProcesses) {
        deleteAll(['relatedprocedure']);
        if(!relatedProcesses) return;
        let schema = {
            id: 'relatedprocedure_id',
            relationship: async (relationship, result) => {
                if(relationship) result.relationship_type = relationship[0];
            },
            title: 'title',
            scheme: 'identifier_scheme',
            identifier: 'relatedprocedure_identifier',
            uri: 'url'
        };

        
        await processRecords('relatedprocedure',['contractingprocess_id', 'relatedprocedure_id'], schema, {contractingprocess_id: cpid}, relatedProcesses);
    }

    /**
     * Importar documentos
     * @param {Number} stage Etapa donde se agregan
     * @param {Array} documents Documentos a importar
     * @param {Array} parents IDs de los registros a los que se anexara (para adjudicaciones, contratos o ejecuciones)
     */
    this.importDocuments = async function(stage, documents, parents){
        if(!documents) return;

        if(!stage) throw new Error('No se ha especificado la etapa');

        let schema = {
            id: 'documentid',
            documentType: 'document_type',
            title: 'title',
            description: 'description',
            url: 'url',
            datePublished: 'date_published',
            dateModified: 'date_modified',
            format: 'format',
            language: 'language',
        };

        switch(stage){
            case Stages.award:
                await processRecords('awarddocuments', ['documentid', 'contractingprocess_id','award_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    award_id: parents[0]
                }, documents);
            break;
            case Stages.planning:
                await processRecords('planningdocuments', ['documentid', 'contractingprocess_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    planning_id: parents[0]
                }, documents);
            break;
            case Stages.tender:
                await processRecords('tenderdocuments',['documentid', 'contractingprocess_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    tender_id:  parents[0]
                }, documents);
            break;
            case Stages.contract:
                await processRecords('contractdocuments', ['documentid', 'contractingprocess_id', 'contract_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    contract_id:  parents[0]
                }, documents);
            break;
            case Stages.implementation:
                await processRecords('implementationdocuments', ['documentid', 'contractingprocess_id', 'implementation_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    implementation_id:  parents[0]
                }, documents);
            break;
        }
    }

    /**
     * Importar hitos
     * @param {Number} stage Etapa donde se agregan
     * @param {Array} milestones Hitos a importar
     * @param {Array} parents IDs de los registros a los que se anexara (para adjudicaciones, contratos o ejecuciones)
     */
    this.importMilestones = async function(stage, milestones, parents){
        if(!milestones) return;

        if(!stage) throw new Error('No se ha especificado la etapa');

        let schema = {
            id: 'milestoneid',
            title: 'title',
            type: 'type',
            description: 'description',
            dueDate: 'duedate',
            dateModified: 'date_modified',
            status: 'status'
        };

        switch(stage){
            case Stages.tender:
                await processRecords('tendermilestone', ['milestoneid', 'contractingprocess_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    tender_id: parents[0]
                }, milestones);
            break;
            case Stages.implementation:
                await processRecords('implementationmilestone', ['milestoneid', 'contractingprocess_id', 'implementation_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    implementation_id:  parents[0]
                }, milestones);
            break;
        }
    }

    /**
     * Importar items
     * @param {Number} stage Etapa donde se agregan
     * @param {Array} items Items a importar
     * @param {Array} parents IDs de los registros a los que se anexara (para adjudicaciones, contratos o ejecuciones)
     */
    this.importItems = async function(stage, items, parents){
        if(!items) return;

        if(!stage) throw new Error('No se ha especificado la etapa');

        let schema = {
            id: 'itemid',
            description: 'description',
            classification: {
                scheme: 'classification_scheme',
                id: 'classification_id',
                description: 'classification_description',
            },
            quantity: 'quantity',
            unit: {
                name: 'unit_name',
                netAmount: 'unit_value_amountNet',
                amount: 'unit_value_amount',
                currency: 'unit_value_currency'
            },
            deliveryLocation: {
                geometry: {
                      coordinates: async (coords, result) => {
                        result.longitude = coords ? coords[0]: null;
                        result.latitude = coords ? coords[1]: null;
                      }
                },
                gazetteer: {
                    scheme: 'gazetteer_scheme',
                    identifiers: async (gazetteer, result) => {
                        result.gazetteer_identifiers = gazetteer ? gazetteer[0] : '';
                    }
                },
                description: 'location_description',
                url: 'location_url'
            },
            deliveryAddress: {
                postalCode: 'location_postalcode',
                countryName: 'location_countryname',
                streetAddress: 'location_streetaddress',
                region: 'location_region',
                locality: 'location_locality'
            }
        };

        switch(stage){
            case Stages.tender:
                await processRecords('tenderitem', ['itemid', 'contractingprocess_id', 'tender_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    tender_id: parents[0]
                }, items);
            break;
            case Stages.award:
                await processRecords('awarditem', ['itemid', 'contractingprocess_id', 'award_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    award_id: parents[0]
                }, items);
            break;
            case Stages.contract:
                await processRecords('contractitem', ['itemid', 'contractingprocess_id', 'contract_id'], schema, 
                {
                    contractingprocess_id: cpid,
                    contract_id:  parents[0],
                }, items);
            break;
        }
    }

    /**
     * Importar modificaciones
     * @param {Number} stage Etapa donde se agregan
     * @param {Array} milestones Modificaciones a a importar
     * @param {Array} parents IDs de los registros a los que se anexara (para adjudicaciones, contratos o ejecuciones)
     */
    this.importAmendments = async function(stage, amendments, parents){
        if(!amendments) return;

        if(!stage) throw new Error('No se ha especificado la etapa');

        let schema = {
            date: 'amendments_date',
            rationale: 'amendments_rationale',
            id: 'amendments_id',
            description: 'amendments_description',
        };

        switch (stage) {
            case Stages.tender:
                await processRecords('tenderamendmentchanges', ['contractingprocess_id' ,'tender_id', 'amendments_id'], schema,
                    {
                        contractingprocess_id: cpid,
                        tender_id: parents[0]
                    }, amendments);
                break;
            case Stages.award:
                await processRecords('awardamendmentchanges', ['contractingprocess_id', 'award_id', 'amendments_id'], schema,
                    {
                        contractingprocess_id: cpid,
                        award_id: parents[0],
                    }, amendments);
                break;
            case Stages.contract:
                await processRecords('contractamendmentchanges', ['contractingprocess_id', 'contract_id', 'amendments_id'], schema,
                    {
                        contractingprocess_id: cpid,
                        contract_id: parents[0]
                    }, amendments);
                break;
        }
    }

    /**
     * Importar solicitudes de cotizacion
     * @param {Array} requests Solicitudes a importar
     * @param {Number} planningid ID de la planeación a la que se ligaran
     */
    this.importRequestsForQuotes = async function(requests, planningid) {
        let schema = {
            id: 'requestforquotes_id',
            title: 'title',
            description: 'description',
            period: {
                startDate: 'period_startdate',
                endDate: 'period_enddate'
            }
        };

        await processRecords('requestforquotes', ['contractingprocess_id', 'planning_id', 'requestforquotes_id'], schema, { contractingprocess_id: cpid, planning_id: planningid}, requests,
        async (request) => {
            // despues cada registro se va a crear sus items, suppliers, quotes, etc
            
            // items
            await processRecords('requestforquotesitems', ['requestforquotes_id' , 'itemid'], {
                id: 'itemid',
                description: 'item',
                quantity: 'quantity',
                classification: {
                    id: 'item'
                }
            }, {requestforquotes_id: request.id}, request.items);
            
            // invitados
            if(request.invitedSuppliers.filter(x => x !== null).length > 0) {
                let parties = await db.manyOrNone('select id from parties where partyid in ($1:csv) and contractingprocess_id = $2',[request.invitedSuppliers.filter(x => x !== null).map(x => x.id), cpid]);
                await processRecords('requestforquotesinvitedsuppliers', ['requestforquotes_id', 'parties_id'], { id: 'parties_id' }, {requestforquotes_id: request.id}, parties);

            }
            let schemaQuotes = {
                id: 'quotes_id',
                description: 'description',
                date: 'date',
                value: { amount: 'value' },
                period:{
                    startDate: 'quoteperiod_startdate',
                    endDate: 'quoteperiod_enddate'
                },
                issuingSupplier: async (supplier, result) => { result.issuingsupplier_id = await checkIfExists('parties', {partyid: supplier.id, contractingprocess_id: cpid})}
            };
            
            // cuotas
            await processRecords('quotes', ['requestforquotes_id', 'quotes_id'], schemaQuotes, { requestforquotes_id: request.id }, request.quotes, async quote => {
                // items de cuotas
                await processRecords('quotesitems', ['quotes_id', 'itemid'], {
                    id: 'itemid',
                    description: 'item',
                    amount: 'quantity',
                    classification: {
                        id: 'item'
                    }
                }, { 
                    quotes_id: quote.id 
                }, 
                quote.items);
            });
        });
            
    }

    /**
     * Importar desploses de presupuesto
     */
    let importBudget = async function(budgets , planningid) {
        let schema = {
            id: 'budget_budgetid',
            description: 'budget_description',
            amount: {
                amount: 'budget_amount',
                currency: 'budget_currency'
            },
            project: 'budget_project',
            projectID: 'budget_projectid',
            uri: 'budget_uri',
            source: 'budget_source',
        };

        await processRecords('budget', ['contractingprocess_id', 'planning_id'], schema, { contractingprocess_id: cpid, planning_id: planningid}, [budgets], async budget => {
            let schemaBreakdown = {
                period: {
                    startDate: 'budgetbreakdownperiod_startdate',
                    endDate: 'budgetbreakdownperiod_enddate'
                },
                id: 'budgetbreakdown_id',
                description: 'description',
                amount: {
                    amount: 'amount',
                    currency: 'currency'
                },
                origin: 'origin',
                fundType: 'fund_type',
                sourceParty:  async (actor, result) => {
                    result.source_id = await checkIfExists('parties', {
                        contractingprocess_id: cpid,
                        partyid: actor.id
                    });
                }
            };


            await processRecords('budgetbreakdown', ['contractingprocess_id', 'planning_id', 'budgetbreakdown_id'], schemaBreakdown, { contractingprocess_id: cpid, planning_id: planningid}, budget.budgetBreakdown, async budgetBreakdown => {
                
                let schemalines = {
                    components: (components, result) => {
                        components.map(component => {
                            switch(component.name){
                                case 'branch': result.branch = component.code; break;
                                case 'responsibleUnit': result.responsibleunit = component.code; break;
                                case 'finality': result.finality = component.code; break;
                                case 'function': result.function = component.code; break;
                                case 'subFunction': result.subfunction = component.code; break;
                                case 'institutionalActivity': result.institutionalactivity = component.code; break;
                                case 'budgetProgram': result.budgetprogram = component.code; break;
                                case 'strategicObjective': result.strategicobjective = component.code; break;
                                case 'requestingUnit': result.requestingunit = component.code; break;
                                case 'specificActivity': result.specificactivity = component.code; break;
                                case 'spendingObject': result.spendingobject = component.code; break;
                                case 'spendingType': result.spendingtype = component.code; break;
                                case 'budgetSource': result.budgetsource = component.code; break;
                                case 'region': result.region = component.code; break;
                            }
                        });
                    },
                    measures: (measures, result) => {
                        measures.map(mea => {
                            switch(mea.id){
                                case 'approved': result.approved = mea.value ? mea.value.amount : 0; break;
                                case 'modified': result.modified = mea.value ? mea.value.amount : 0; break;
                                case 'executed': result.executed = mea.value ? mea.value.amount : 0; break;
                                case 'committed': result.committed = mea.value ? mea.value.amount : 0; break;
                                case 'reserved': result.reserved = mea.value ? mea.value.amount : 0; break;
                            }
                        });
                    }
                };


                await db.none('delete from budgetclassifications where budgetbreakdown_id = $1', [budgetBreakdown.id]);

                await processRecords('budgetclassifications', ['budgetbreakdown_id'], schemalines, { budgetbreakdown_id: budgetBreakdown.id}, budgetBreakdown.budgetLines, async (line, record) => {
                    
                    let campos = [
                        'branch like ${branch}',
                        'finality like ${finality}',
                        'function like ${function}',
                        'subfunction like ${subfunction}',
                        'institutionalactivity like ${institutionalactivity}',
                        'budgetprogram like ${budgetprogram}',
                        'strategicobjective like ${strategicobjective}',
                        'responsibleunit like ${responsibleunit}',
                        'requestingunit like ${requestingunit}',
                        'spendingtype like ${spendingtype}',
                        'specificactivity like ${specificactivity}',
                        'spendingobject like ${spendingobject}',
                        'region like ${region}',
                        'approvedamount = ${approved}',
                        'modifiedamount = ${modified}',
                        'executedamount = ${executed}',
                        'committedamount = ${committed}',
                        'reservedamount = ${reserved}'
                    ];

                    record.branch = record.branch || '';
                    record.finality = record.finality || '';
                    record.function = record.function || '';
                    record.subfunction = record.subfunction || '';
                    record.institutionalactivity = record.institutionalactivity || '';
                    record.budgetprogram = record.budgetprogram || '';
                    record.strategicobjective = record.strategicobjective || '';
                    record.responsibleunit = record.responsibleunit || '';
                    record.requestingunit = record.requestingunit || '';
                    record.spendingtype = record.spendingtype || '';
                    record.specificactivity = record.specificactivity || '';
                    record.spendingobject = record.spendingobject || '';
                    record.region = record.region || '';
                    record.approved = record.approved || 0;
                    record.modified = record.modified || 0;
                    record.executed = record.executed || 0;
                    record.committed = record.committed || 0;
                    record.reserved = record.reserved || 0;



                    let programatic = await db.oneOrNone("select * from programaticstructure where  " + campos.join(' and ') + " limit 1", record);
                        if(programatic){
                            let cve = `${(programatic.year || '').toString().padStart(4, '0')}${(programatic.branch || '').padStart(2, '0')}${(programatic.responsibleunit || '').padStart(3, '0')}${(programatic.finality || '').padStart(1, '0')}${(programatic.function || '').padStart(1, '0')}${(programatic.subfunction || '').padStart(2, '0')}${(programatic.institutionalactivity || '').padStart(3, '0')}${(programatic.budgetprogram || '').padStart(4, '0')}${(programatic.strategicobjective || '').padStart(3, '0')}${(programatic.requestingunit || '').padStart(3, '0')}${(programatic.specificactivity || '').padStart(5, '0')}${(programatic.spendingobject || '').padStart(5, '0')}${(programatic.spendingtype || '').padStart(1, '0')}${(programatic.budgetsource || '').padStart(1, '0')}${(programatic.region || '').padStart(2, '0')}${(programatic.portfoliokey || '').padStart(1, '0')}`;

                            await db.none('update budgetclassifications set year = $2, cve = $3, portfoliokey= $4 where id = $1',[
                                line.id,
                                programatic.year,
                                cve,
                                programatic.portfoliokey
                            ]);
                        }
                    
                });


            });
            
        });
    }

    /**
     * Importar juntas de clarificacion
     * @param {Array} clarificationMeetings Juntas de clarificacion
     */
    let importClarificationMeetings = async function(clarificationMeetings){
        let schema = {
            id: 'clarificationmeetingid',
            date: 'date'
        };

        await processRecords('clarificationmeeting', ['contractingprocess_id', 'clarificationmeetingid'], schema, { contractingprocess_id: cpid }, clarificationMeetings, async clarification => {
            let schemaActor = {
                id: async (actor, result) =>{
                    result.parties_id = await checkIfExists('parties', {
                        contractingprocess_id: cpid,
                        partyid: actor
                    });
                }
            }
            
            await processRecords('clarificationmeetingactor', ['clarificationmeeting_id', 'parties_id'], schemaActor, { clarificationmeeting_id: clarification.id, attender: true }, clarification.attendees);
            await processRecords('clarificationmeetingactor', ['clarificationmeeting_id', 'parties_id'], schemaActor, { clarificationmeeting_id: clarification.id, official: true }, clarification.officials);
        });
    }

    let transform = async (reg, schema, result) => {
        let keys = Object.keys(schema)
      
        for(let i = 0; i < keys.length; i++){
            let property = schema[keys[i]],
                value = reg[keys[i]];
            if(!value) continue;
            if(typeof property === 'function') 
                await property(value, result);
            else if(typeof property === 'object' && !(property instanceof Date) )
                await transform(value, property, result);
            else 
                result[schema[keys[i]]] = value;
        }
        return result;
    }

    /**
     * Insertar y/o actualizar los registros a una tabla
     * @param {String} table Tabla
     * @param {Array} identifiers Identificadores del registro
     * @param {Object} schema Esquema al cual se pasaran los registros
     * @param {Object} annexes Anexar propiedades a cada registro
     * @param {Array} records Registros
     * @param {function} next Ejecutar función despues de terminar cada registro
     */
    let processRecords = async (table, identifiers, schema, annexes, records, next) =>{
        let filter = {};
        if(!records) return;
        for(let i = 0, reg = records[i]; i < records.length; i++, reg = records[i]){
            // convierte el json al esquema que necesita la tabla
            let reg2Import = await transform(reg, schema, {});
             // anexar propiedades
             Object.keys(annexes).map(x => reg2Import[x] = annexes[x]);
            // prepara el filtro para revisar si es insert o update
            identifiers.map(x => filter[x] = reg2Import[x] ? reg2Import[x].toString() : undefined);
            reg2Import.id = await checkIfExists(table, filter);
            reg2Import = clean(reg2Import);
            if(reg2Import.id) await update(table,{id: reg2Import.id}, reg2Import);
            else reg2Import.id = await insert(table, reg2Import);
            if(next) {
                reg.id = reg2Import.id;
                await next(reg, reg2Import);
            }
        }
        console.log('Importacion', table, records.length);
    }

    /**
     * Revisar si existe un registro
     * @param {String} table Tabla
     * @param {Object} where Condicion de la consulta
     */
    let checkIfExists = async function(table, where) {
        let params = [table],
            swhere = Object.keys(where).map((x, i) => {
                params.push(where[x]);
                return `${x}=$${params.length}`
            }).join(' and ');
       
        let result = (await db.oneOrNone(`select id from $1~ where ${swhere} limit 1`, params));
        return result ? result.id : undefined;
    }

    /**
     * Ejecutar una consulta para obtener un solo resultado
     * @param {String} table Nombre de la tabla
     * @param {String} field Nombre del campo por el que se va a filtrar
     * @param {String} value Valor por el que se va a filtrar
     */
    let one = async function(table, field, value) {
        return (await db.oneOrNone('select * from $1~ where $2~ = $3 limit 1', [table, field, value]));
    };

    /**
     * Ejecutar una consulta para obtener varios resultados
     * @param {String} table Nombre de la tabla
     * @param {String} field Nombre del campo por que el se va a filtrar
     * @param {String} value Valor por el que se va a filtrar
     */
    let many = async function(table, field, value) {
        return await db.manyOrNone('select * from $1~ where $2~ = $3 order by id', [table, field, value]);
    };

    /**
     * Insertar un registro
     * @param {String} table Tabla
     * @param {Object} values Valores a registrar
     * @returns {Number} Id del registro
     */
    let insert = async function(table, values ){
        let params = [table]
        sColumns = Object.keys(values).map(x => x).join(', '),
        sValues = Object.keys(values).map((x, i) => {
            params.push(values[x]);
            return `$${params.length}`
        }).join(', ');
        let {id} = await db.one(`insert into $1~ (${sColumns}) values (${sValues}) returning id`, params);
        return id;
    }

    /**
     * Actualizar registro
     * @param {String} table Tabla
     * @param {Object} where Llave y valor del registro que se actualizara
     * @param {Object} values Valores a actualizar
     */
    let update = async function(table, where, values ){
        let params = [table]
        sColumns = Object.keys(values).map((x, i) => {
            params.push(values[x]);
            return `${x}=$${params.length}`
        }).join(', '),
        sWhere = Object.keys(where).map((x, i) => {
            params.push(where[x]);
            return `${x}=$${params.length}`
        }).join(' AND ');
        await db.none(`update $1~ set ${sColumns} where ${sWhere}`, params);
    }

    /**
     * Eliminar los regisrtos de las tablas
     * @param {String[]} tables 
     */
    let deleteAll = async function(tables) {
        for(t in tables){
            try{
            await db.none(`delete from $1~ where contractingprocess_id = $2`, [tables[t], contractingproessid]);
            }
            catch(e) {
                console.log('Error al vaciar tabla', tables[t], e);
            }
        }      
    }

    /**
     * Limpiar propiedades vacias
     * @param {Object} obj Objeto a limpiar de propiedades vacias
     */
    let clean = obj => {
        Object.keys(obj).map(key => {
            if(obj[key] === undefined ||
                obj[key] === null ||
                (Array.isArray(obj[key]) && obj[key].length === 0) || 
                (typeof obj[key] === 'object' && !(obj[key] instanceof Date) && Object.keys(obj[key]).length === 0) ||
                (typeof obj[key] === 'string' && obj[key].trim() === '') ||
                (typeof obj[key] === 'number' && isNaN(obj[key]))){
                 delete obj[key];
             }
        });
        return obj;
    }

    return this;
}

module.exports = Import;