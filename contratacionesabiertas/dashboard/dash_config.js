
var options = {};

var pgp = require('pg-promise')(options);

const configDash = {
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_NAME ||'edca',
    user: process.env.POSTGRES_USER || 'prueba_dashboard',
    password: process.env.POSTGRES_PASSWORD || 'p4ssw0rd'
};

const globals = {
    site : {
        port : 4000
    }
}

var connectionDashboard = pgp(configDash);
////////////////////////////////


module.exports = {
    dashboard: connectionDashboard,
    globals: globals
};
