

/**
 *  Ejecutar proceso PNT para enviar las contrataciones.
 * 
 * Es necesario tener configurado las variables de entorno:
 *  - PNT_URL = Url al api. Ej http://devcarga.inai.org.mx:8080
 *  - PNT_USER = Nombre del usuario para generar token
 *  - PNT_PASS = Contraseña del usuario para generar token
 *  - PNT_EMAIL = Email de la unidad administrativa
 * 
 */
const pnt = require('./pnt/process-pnt.js');


(async () => 
{
    console.log('Iniciando proceso con PNT...');

    await pnt.init();

    console.log('Se ha terminado el proceso con PNT.');
})();
