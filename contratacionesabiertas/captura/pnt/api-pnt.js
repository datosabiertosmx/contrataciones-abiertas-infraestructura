/**
 *  Conexión la plataforma PNT 
 */


// credenciales
const URL = process.env.PNT_URL || 'http://devcarga.inai.org.mx:8080';
const USER = process.env.PNT_USER || 'dga@inai.org.mx';
const PASS = process.env.PNT_PASS || 'P4ssw0rd';

// cliente http
const axios = require("axios");
axios.defaults.baseURL = URL
axios.defaults.headers.post['Content-Type'] = 'application/json';
//axios.default.timeout = 5000;

let token;

let throwErrorPTN = (section, body) => {
    throw Error(`${section}. ${body.id}. ${body.mensaje}`);
}

/**
 * Iniciar sesion
 * @param {String} user Usuario
 * @param {String} pass Password
 */
let generateToken = async (user, pass) => {
    let response;

    try{
        response = await axios.post(`sipot-web/spring/generaToken/`,{
            usuario: user || USER,
            password: pass || PASS
        });
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }
    if(response.data.success){
        token = response.data.token.token;
        console.log('---> Sesion iniciada');
    } else{
        throwErrorPTN('Inicio de sesión', response.data);
    }
    return token;
}


/**
 * Enviar registros a registrar
 * @param {Number} format Numero de formato
 * @param {String} email Email de la unidad administrativa
 * @param {Array} registers Registros a guardar
 */
let registerInfo = async (format, email, registers) => {
    try{
        
        response = await axios.post(`sipot-web/spring/mantenimiento/agrega`,{
            token: token,
            idFormato: format,
            correoUnidadAdministrativa: email,
            registros: registers
        });
        console.log(JSON.stringify({
            token: token,
            idFormato: format,
            correoUnidadAdministrativa: email,
            registros: registers
        },null, 4));
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}". ${e.message}`);
    }

    console.log(`-------> ${registers.length} Registros cargados de formato ${format}`);
    return response.data;
}

/**
 * Actualizar registros
 * @param {Number} format Numero de formato
 * @param {String} email Email de la unidad administrativa
 * @param {Array} registers Registros a guardar
 */
let updateInfo = async (format, email, registers) => {
    try{
        response = await axios.post(`sipot-web/spring/mantenimiento/actualiza`,{
            token: token,
            idFormato: format,
            correoUnidadAdministrativa: email,
            registros: registers
        });

        console.log(JSON.stringify({
            token: token,
            idFormato: format,
            correoUnidadAdministrativa: email,
            registros: registers
        },null, 4));
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }

    console.log(`-------> ${registers.length} Registros actualizados del formato ${format}`);
    return response.data;
}

/**
 * Eliminar registros
 * @param {Number} format Numero de formato
 * @param {String} email Email de la unidad administrativa
 * @param {Array} registers Registros a guardar
 */
let deleteInfo = async (format, email, registers) => {
    try{
        response = await axios.post(`sipot-web/spring/mantenimiento/elimina`,{
            token: token,
            idFormato: format,
            correoUnidadAdministrativa: email,
            registros: registers
        });
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }

    console.log(`-------> ${registers.length} Registros eliminados del formato ${format}`);
    return response.data;
}

/**
 * Cargar catalogos del formato
 * @param {Number} catalog Numero del campo
 */
let getCatalog = async (catalog) => {
    try{
        response = await axios.post(`sipot-web/spring/informacionFormato/campoCatalogo`,{
            token: token,
            idCampo: catalog
        });
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }

    if(response.data.success){
        console.log('-----> Catalogo cargado ' + catalog);
        return response.data.mensaje;
    } else{
        throwErrorPTN('Carga de catalogo', response.data);
    }
}

/**
 * Cargar formato
 * @param {Number} format Numero de formato
 */
let getFormat = async (format) => {
    try{
        response = await axios.post(`sipot-web/spring/informacionFormato/camposFormato`,{
            token: token,
            idFormato: format
        });
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }

    if(response.data.success){
        console.log('-----> Formato cargado ' + format);
        return response.data.mensaje;
    } else{
        throwErrorPTN('Carga de formato', response.data);
    }
}

/**
 * Obtener campos del formato
 * @param {Number} format Numero de formato
 * @param {Number} cocentrator Numero de concentrador
 * @param {Number} code Codigo SO
 */
let getFields = async (format, cocentrator, code) => {
    try{
        response = await axios.post(`sipot-web/spring/informacionFormato/camposFormato`,{
            token: token,
            idFormato: format,
            concentradora: cocentrator,
            codigoSO: code
        });
    }
    catch(e){
        throw Error(`Ha ocurrido un error al conectarse a url "${URL}"`);
    }

    if(response.data.success){
        console.log('-----> Campos cargados ' + format);
        return response.data.mensaje;
    } else{
        throwErrorPTN('Carga de campos', response.data);
    }
}

module.exports = {
    generateToken: generateToken,
    registerInfo: registerInfo,
    updateInfo: updateInfo,
    deleteInfo: deleteInfo,
    getCatalog: getCatalog,
    getFormat: getFormat,
    getFields: getFields
};