
// https://www.npmjs.com/package/jsonpath
// Busqueda sobre json
const jp = require('jsonpath');

/**
 * Funciones para generar el formato
 * @param {Object} release Release de la contratacion
 * @param {Array} recordsPnt Registros del pnt,
 * @param {Number} position Numero de registro
 */
let FormatFuntions =  function(release, recordsPnt, position){
   
    let self = this;
    self.release = release;
    self.recordsPnt = recordsPnt;
    self.formats = [];
    self.position = position;
    self.currentContract = -1;
    self.contractid = '';
    this.nextContract();

    return self; 
}

/**
 * Se posiciona en el siguiente contrato
 */
FormatFuntions.prototype.nextContract = function() {
    this.currentContract++;
    let contract = this.release.contracts[this.currentContract];
    if(contract){
        this.contractid = contract.id;
        let pnt = this.recordsPnt ? this.recordsPnt.filter(x => x.isroot === true && x.contractid == this.contractid).map(x => x.record_id)[0] : '';
        this.fields = [];
        this.formats.push({
            idRegistro: pnt || '',
            numeroRegistro: this.position++,
            campos: this.fields,
            contractid: this.contractid
        });
    }
}

/**
* Buscar Id del Registro de PNT 
* @param {Number} field Numero del campo
* @param {Number} position Posicion
*/
FormatFuntions.prototype.findIdRecord = function(field, position) {
    let record = this.recordsPnt ? this.recordsPnt.find(x => x.field_id === field && x.position === position && x.contractid === this.contractid) || {} : {};
    return record.record_id || '';
}

/**
* Buscar valor mediante una ruta
* @param {String} path Ruta para obtener el valor
* @param {Object} obj (Opcional) Objecto donde se buscara. Por defecto se toma el release
*/
FormatFuntions.prototype.findValue = function(path, obj) {
    let tmp = obj || this.release;
    return jp.value(tmp, '$.' + path);
}

/**
* Buscar valor mediante una ruta
* @param {String} path Ruta para obtener el valor
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
* @param {Object} obj (Opcional) Objecto donde se buscara. Por defecto se toma el release
*/
FormatFuntions.prototype.findValues = function(path, obj) { 
    let tmp = obj || this.release;
    let result = [];
    jp.query(tmp, '$.' + path).map(value => {
        if(Array.isArray(value)){
            result = result.concat(value);
        } else if(value){
            result.push(value);
        }
    });
    
    return result;
}

/**
* Agregar campo de tipo tabla
* @param {Number} field Numero del campo
* @param {String} path Ruta del valor en el json del release
* @param {Function} fn Procesar los valores internos
* @param {Object} obj (Opcional) utilizar objeto en lugar del release
*/
FormatFuntions.prototype.addTable = function(field, path, fn, obj) {
    if (field === 0) return;
    let results = this.findValues(path, obj);
    let values = [];
    if(results && fn) {
        results.map(v => {
            let campos = [];
            fn(v,campos);
            if(campos.length > 0){
                values.push({
                    numeroRegistro: values.length + 1,
                    idRegistro: this.findIdRecord(field,values.length + 1),
                    campos: campos
                });
            }
        });
    }
    if (values.length > 0) {
        this.fields.push({
            idCampo: field,
            valor: values,
        });
    }
}

/**
* Agregar valor al formato
* @param {Number} field Numero del campo
* @param {String} path Ruta del valor en el json del release
* @param {obj} obj Utilizar objeto en lugar del release
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
* @param {Boolean} required (Opcional) Indica si es obligatorio. Si es obligatorio y no se recibe valor se arroja una excepcion
* @param {String} error (Opcional) Mensaje de error a desplegar, por defecto se muestra field
*/
FormatFuntions.prototype.addField = function(field, path, obj, fn, required, error) {
    if (field === 0) return;
    let value = this.findValue(path, obj);
    
    if(value !== undefined && value !== null && fn) {
        value = fn(value);
    }
    if (value !== undefined && value !== null) {
        this.fields.push({
            idCampo: field,
            valor: value
        });
    } else if(required){
        throw Error(`El Campo ${error||field} es obligatorio`);
    }
}

/**
* Agregar valores al formato. Cuando el resultado es una lista
* @param {Number} field Numero del campo
* @param {String} path Ruta del valor en el json del release
* @param {obj} obj Utilizar objeto en lugar del release
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
* @param {Boolean} required (Opcional) Indica si es obligatorio. Si es obligatorio y no se recibe valor se arroja una excepcion
* @param {String} error (Opcional) Mensaje de error a desplegar, por defecto se muestra field
* 
*/
FormatFuntions.prototype.addFields = function(field, path, obj, fn, required, error) {
    if (field === 0) return;
    let values = this.findValues(path, obj);
    let added = false;

    values.map(value => {
        if(value !== undefined && value !== null && fn) {
            value = fn(value);
        }
        if (value !== undefined && value !== null) {
            this.fields.push({
                idCampo: field,
                valor: value
            });
            added = true;
        } 
    });

    if(required && !added){
        throw Error(`El Campo ${error||field} es obligatorio`);
    }
}

/**
* Agregar directamente campo al formato
* @param {Number} field Numero del campo
* @param {String} value Valor
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
* @param {Boolean} required (Opcional) Indica si es obligatorio. Si es obligatorio y no se recibe valor se arroja una excepcion
* @param {String} error (Opcional) Mensaje de error a desplegar, por defecto se muestra field
*/
FormatFuntions.prototype.add = function(field, value, fn, required, error) {
    if (field === 0) return;
    if(value !== undefined && value !== null && fn) {
        value = fn(value);
    }
    if (value !== undefined && value !== null) {
        this.fields.push({
            idCampo: field,
            valor: value
        });
    } else if(required){
        throw Error(`El Campo ${error||field} es obligatorio`);
    }
}


/**
* Agregar valor al formato
* @param {Number} field Numero del campo
* @param {String} path Ruta del valor en el json del release
* @param {Object} obj Objeto donde se obtendra el valor
* @param {Array} results Lista donde se agregara
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
*/
FormatFuntions.prototype.addInternalField = function(field, path, obj, results, fn) {
    if (field === 0) return;
    let value = this.findValue(path, obj);
    if(value !== undefined && value !== null && fn){
        value = fn(value);
    }
    if (value !== undefined && value !== null && results) {
        results.push({
            idCampo: field,
            valor: value
        });
    }
}

/**
* Agregar valor al formato
* @param {Number} field Numero del campo
* @param {Object} value Valor a agregar
* @param {Array} results Lista donde se agregara
*/
FormatFuntions.prototype.addInternal = function(field, value, results) {
    if (field === 0) return;
    if (value !== undefined && value !== null && results) {
        results.push({
            idCampo: field,
            valor: value
        });
    }
}

/**
* Agregar valores al formato. Cuando son multiples resultados
* @param {Number} field Numero del campo
* @param {String} path Ruta del valor en el json del release
* @param {Object} obj Objeto donde se obtendra el valor
* @param {Array} results Lista donde se agregara
* @param {Function} fn (Opcional) Procesar el valor antes de regresarlo
*/
FormatFuntions.prototype.addInternalFields = function(field, path, obj, results, fn) {
    if (field === 0) return;
    let values = this.findValues(path, obj);
    if(values){
        values.map(value => {
            if(value !== undefined && value !== null && fn){
                value = fn(value);
            }
            if (value !== undefined && value !== null && results) {
                results.push({
                    idCampo: field,
                    valor: value
                });
            }
        });
    }
   
}

/**
 * Devuelve el formato
 */
FormatFuntions.prototype.getFormat = function() {
    return this.formats;
};

FormatFuntions.prototype.dateFormat = function(date) {
    if(date){
        if(/\d{4}-\d{2}-\d{2}/.test(date)) {
            const fragments = /\d{4}-\d{2}-\d{2}/.exec(date)[0].split('-');
            return `${fragments[2]}/${fragments[1]}/${fragments[0]}`;
        } else return undefined;
    }
    else return undefined
  };
  

module.exports = FormatFuntions;