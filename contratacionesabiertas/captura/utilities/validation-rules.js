isNotNullOrEmpty = text => {
    return text !== null && text !== undefined && (typeof text === 'string' ? text.length > 0 : true)
}


/**
 *  Validar tipo de documento
 * 
 * @param {Documents} document
 * @param {String} stage
 */
validateTypeOfDocument = (document, stage) => {
    let result = false;
    switch (document.document_type) {
        case 'assetAndLiabilityAssessment':
        case 'environmentalImpact':
        case 'feasibilityStudy':
        case 'marketStudies':
        case 'needsAssessment':
        case 'procurementPlan':
        case 'projectPlan':
        case 'hearingNotice':
            result = stage === 'planning';
            break;
        case 'biddingDocuments':
        case 'billOfQuantity':
        case 'clarifications':
        case 'conflictOfInterest':
        case 'debarments':
        case 'eligibilityCriteria':
        case 'evaluationCriteria':
        case 'bidders':
        case 'riskProvisions':
        case 'shortlistedFirms':
        case 'technicalSpecifications':
        case 'tenderNotice':
            result = stage === 'tender';
            break;
        case 'awardNotice':
        case 'complaints':
        case 'evaluationReports':
        case 'winningBid':
        case 'awardDraftContract':
            result = stage === 'award';
            break;
        case 'contractArrangements':
        case 'contractAnnexe':
        case 'contractNotice':
        case 'contractGuarantees':
        case 'contractSchedule':
        case 'contractSigned':
        case 'subContract':
            result = stage === 'contract';
            break;
        case 'completionCertificate':
        case 'finalAudit':
        case 'financialProgressReport':
        case 'physicalProcessReport':
            result = stage === 'implementation';
            break;
    }
    return result;
}

/**
 *  Validar el detalle del método de contratación
 * 
 * @param {String} details
 */
validateProcurementMethodDetails = (details) => {
    let result = false;
    switch (details) {
        case 'Licitación pública':
        case 'Invitación a cuando menos tres personas':
        case 'Adjudicación directa':
            result = true;
            break;
    }

    return result;
}

/**
 *  Validar la relación entre método de contratación y detalles del método de contratación
 * 
 * @param {String} details
 * @param {String} method
 */
validateRelationBetweenProcurementMethodDetailsAndProcurementMethod = (details, method) => {
    let result = false;
    switch (details) {
        case 'Licitación pública':
            result = method === 'open';
            break;
        case 'Invitación a cuando menos tres personas':
            result = method === 'selective';
            break;
        case 'Adjudicación directa':
            result = method === 'direct';
            break;
    }
    return result;
}

/**
 *  Validar la relación entre Justificación del método de contratación y Categoría principal de la contratación
 * 
 * @param {String} additional
 * @param {String} main
 */
validateRelationBetweenAdditionalProcurementCategoriesAndMainProcurementCategory = (additional, main) => {
    let result = false;
    switch (additional) {
        case 'Adquisición de bienes':
        case 'goodsLease':
            result = main === 'goods';
            break;
        case 'Arrendamiento de bienes':
        case 'goodsAcquisition':
            result = main === 'goods';
            break;
        case 'Servicios':
        case 'services':
            result = main === 'services';
            break;
        case 'Servicios relacionados con obras públicas':
        case 'worksRelatedServices':
            result = main === 'services';
            break;
        case 'Obras públicas':
        case 'works':
            result = main === 'works';
            break;
    }
    return result;
}

getSpanishMainProcurementCategory = (value) => {
    let result = value;
    switch(value){
        case 'goods':
            result = 'Bienes';
            break;
        case 'services':
            result = 'Servicios';
            break;
        case 'works':
            result = 'Obras públicas';
            break;
    }
    return result;
}


/**
 * Validar que un id sea unico
 * @param {Number} id
 * @param {Array} list
 */
validateUniqueId = (id, list) => {
    return list.filter(x => x.id === id).length === 1;
}

module.exports.isNotNullOrEmpty = isNotNullOrEmpty;
module.exports.validateRelationBetweenAdditionalProcurementCategoriesAndMainProcurementCategory = validateRelationBetweenAdditionalProcurementCategoriesAndMainProcurementCategory;
module.exports.validateRelationBetweenProcurementMethodDetailsAndProcurementMethod = validateRelationBetweenProcurementMethodDetailsAndProcurementMethod;
module.exports.validateProcurementMethodDetails = validateProcurementMethodDetails;
module.exports.validateTypeOfDocument = validateTypeOfDocument;
module.exports.validateUniqueId = validateUniqueId;
module.exports.getSpanishMainProcurementCategory = getSpanishMainProcurementCategory;