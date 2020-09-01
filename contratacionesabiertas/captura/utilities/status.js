

// Catalogo de estatus de licitacion
const estatusLicitacion = {
    planning: 'En planeación',
    planned: 'Planeada',
    active: 'Activa',
    cancelled: 'Cancelada',
    unsuccessful: 'No exitosa',
    complete: 'Concluida',
    withdrawn: 'Retirada',
    direct: 'Directa'
};

// Catalogo de estatus de adjudicacion
const estatusAdjudicacion =  { 
    pending: 'Pendiente',
    active: 'Activo',
    cancelled: 'Cancelado',
    unsuccessful: 'No exitoso' 
};


// Catalogo de estatus de contrato
const estatusContrato = {
    pending: 'Pendiente',
    active: 'Activo',
    cancelled: 'Cancelado',
     terminated: 'Terminado' 
};

// Catalogo de estatus de ejecucion
const estatusEjecucion = {
    pending: 'En planeación',
    ongoing: 'En progreso',
    concluded: 'En finiquito'
};

const typesOfStatus = {
    licitacion: 'licitacion',
    adjudicacion: 'adjudicacion',
    contratacion: 'contratacion',
    ejecucion: 'ejecucion'
}


let getValueStatus = (typeOfCatalog, value) => {
    switch(typeOfCatalog) {
        case typesOfStatus.adjudicacion:
            return estatusAdjudicacion[value] ? estatusAdjudicacion[value] : value;
        case typesOfStatus.contratacion:
            return estatusContrato[value] ? estatusContrato[value] : value;
        case typesOfStatus.licitacion:
            return estatusLicitacion[value] ? estatusLicitacion[value] : value;
            case typesOfStatus.ejecucion:
            return estatusEjecucion[value] ? estatusEjecucion[value] : value;
    }
}

module.exports.TypesOfStatus =  typesOfStatus;

module.exports.getValueStatus = getValueStatus;