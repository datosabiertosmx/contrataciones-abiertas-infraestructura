var express = require('express');
var router = express.Router();
const uuid = require('uuid/v4');
var path  = require('path');
// modelos para infraestructura
const db = require('../models');
// Funciones para infraestructura
var project = require('../public/javascript/project');
// Funciones para contrataciones
var cp_functions = require('../public/javascript/contracting_process_functions');
// PostgreSQL database
var db_conf = require('../db_conf');
const { Op,Sequelize} = require("sequelize");
//Swagger doc
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('../swagger.json');
const cors = require('cors')

//passport db
var dbConfig = require('../db.js');
var mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
mongoose.connect(dbConfig.url, {useNewUrlParser: true,useUnifiedTopology: true});

// Configuring Passport
var passport = require('passport');
var expressSession = require('express-session');
const MongoStore = require('connect-mongo')(expressSession);

// reading csv
var stream = require('stream');
const csvtojsonV2=require("csvtojson/v2");
const fs = require('fs');

router.use(expressSession({secret: 'mySecretKey', resave: true, saveUninitialized: true,  store: new MongoStore({ mongooseConnection: mongoose.connection })}));
router.use(passport.initialize());
router.use(passport.session());

// Using the flash middleware provided by connect-flash to store messages in session
// and displaying in templates
var flash = require('connect-flash');
router.use(flash());


// Initialize Passport
/* ******************* */
var LocalStrategy   = require('passport-local').Strategy;
var User = require('../models/user');
var bCrypt = require('bcrypt-nodejs');

// utilidades
const {TypesOfStatus, getValueStatus} = require('../utilities/status');
const VadalitionProcess = require('../utilities/validation-process');
const converterToCSV = require('json-2-csv');
const { fork } = require('child_process');


const Stages = {
    planning: 1,
    tender: 2,
    award: 3,
    contract: 4,
    implementation: 5
};

// se sobre escribe porque esta causando problemas con los json
Date.prototype.toISOString = function() {
    let fecha = this;
    let result =(
        fecha.getFullYear() + "-"+
        ( (fecha.getMonth() + 1 < 10)?("0"+(fecha.getMonth()+1)):(fecha.getMonth() + 1) )+ "-" + // 0 - 11
        ( (fecha.getDate() < 10)?("0"+(fecha.getDate())):(fecha.getDate()) ) +"T"+ // 1 - 31
        ( (fecha.getHours() < 10)?("0"+fecha.getHours()):fecha.getHours() )+":"+ //0 - 23
        ( (fecha.getMinutes() < 10 )?("0"+fecha.getMinutes()):fecha.getMinutes() ) + ":" +
        ( (fecha.getSeconds() < 10 )?("0"+ fecha.getSeconds()):fecha.getSeconds() ) + "Z"
    );
    return result;
}

Date.prototype.toString = function() {
    let fecha = this;
    let result =(
        fecha.getFullYear() + "-"+
        ( (fecha.getMonth() + 1 < 10)?("0"+(fecha.getMonth()+1)):(fecha.getMonth() + 1) )+ "-" + // 0 - 11
        ( (fecha.getDate() < 10)?("0"+(fecha.getDate())):(fecha.getDate()) ) +"T"+ // 1 - 31
        ( (fecha.getHours() < 10)?("0"+fecha.getHours()):fecha.getHours() )+":"+ //0 - 23
        ( (fecha.getMinutes() < 10 )?("0"+fecha.getMinutes()):fecha.getMinutes() ) + ":" +
        ( (fecha.getSeconds() < 10 )?("0"+ fecha.getSeconds()):fecha.getSeconds() ) + "Z"
    );
    return result;
}

const implementationStatus = [ {title_esp: 'En planeación', code: 'planning'},
{title_esp: 'En progreso', code: 'ongoing'},
{title_esp: 'Terminado', code: 'concluded'},];


passport.use('login', new LocalStrategy({
        passReqToCallback : true
    },
    function(req, username, password, done, isActive) {
        // check in mongo if a user with username exists or not

        User.findOne({ 'username' :  username },
            function(err, user) {

                // In case of any error, return using the done method
                if (err)
                    return done(err);
                // Username does not exist, log the error and redirect back
                if (!user){
                    console.log('User Not Found with username '+username);
                    return done(null, false, req.flash('message', 'Usuario no registrado'));
                }
                // User exists but wrong password, log the error
                if (!isValidPassword(user, password)){
                    console.log('Contraseña no válida');
                    return done(null, false, req.flash('message', 'Contraseña no válida')); // redirect back to login page
                }
                // check user is active
                if (user.isActive === false){
                    console.log('El usuario '+ username + ' se encuentra inactivo');
                    return done(null, false, req.flash('message', 'Usuario inactivo'));
                }
                // User and password both match, return user from done method
                // which will be treated like success
                return done(null, user);
            }
        );

    }
));


var isValidPassword = function(user, password){
    return bCrypt.compareSync(password, user.password);
};

// Generates hash using bCrypt
const createHash = (password) => bCrypt.hashSync(password, bCrypt.genSaltSync(10), null);

// Passport needs to be able to serialize and deserialize users to support persistent login sessions
passport.serializeUser(function(user, done) {
    console.log('serializing user: ');
    console.log(user);
    done(null, user._id);
});

passport.deserializeUser(function(id, done) {
    User.findById(id, function(err, user) {
        //console.log('deserializing user:',user);
        done(err, user);
    });
});

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

var isNotAuthenticated = function (req, res, next) {
    if (req.isUnauthenticated())
        return next();
    // if the user is authenticated then redirect him to the main page
    res.redirect('/main');
};

router.use('/api-docs',swaggerUi.serve, swaggerUi.setup(swaggerDocument))
router.use(cors());
/* * * * * * * * * * * RUTAS * * * * * * * * * * * * * */

/* GET home page. */
router.get('/', isNotAuthenticated, function (req, res, next) {
    res.render('index', {title: 'Sistema de captura de datos de contrataciones abiertas en México', message: req.flash('message')});
});

router.get('/admin/new-user.html', isAuthenticated, function(req, res){
    res.render('modals/new_user');
});

router.get('/admin/users.html', isAuthenticated,  function (req, res) {
    //console.log(req.user);
    User.find({ _id :{ $ne: req.user._id }}).then(function (users) {
        res.render('modals/users', {users: users});
    });
});

router.get('/admin/contrataciones.html', isAuthenticated, async function (req, res) {
    
    try{
        let select = 'select c.*, t.title tender_name, t.tenderid tender_id, ' +
                    "((select string_agg(name, ', ') from parties p  join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true)) requestingunit_name from contractingprocess c " +
                    ' left join tender t on t.contractingprocess_id = c.id ';
        let where = [];

        if (req.query.ocid) where.push(" lower(c.ocid) like lower('%' || ${ocid} || '%')");
        if (req.query.tender_name) where.push(" lower(t.title) like lower('%' || ${tender_name} || '%')");
        if (req.query.tender_id) where.push(" lower(t.tenderid) like lower('%' || ${tender_id} || '%')");
        if (req.query.requestingunit_name) where.push(" c.id in (select p.contractingprocess_id from parties p  join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true and lower(name) like lower('%' || ${requestingunit_name} || '%'))");

        const cp = await db_conf.edca_db.manyOrNone( select + (where.length > 0 ? 'where ' + where.join(' and ') : ''), req.query);

        res.render('modals/contractingprocess_list',{ cp: cp, body: req.query });
    }
    catch(e) {
        res.render('ERROR');
    }
});

router.get('/admin/contrataciones_list.html', isAuthenticated, async function (req, res) {
    
    try{
        let select = 'select c.*, t.title tender_name, t.tenderid tender_id, ' +
                    "((select string_agg(name, ', ') from parties p  join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true)) requestingunit_name from contractingprocess c " +
                    ' left join tender t on t.contractingprocess_id = c.id ';
        let where = [];

        if (req.query.ocid) where.push(" lower(c.ocid) like lower('%' || ${ocid} || '%')");
        if (req.query.tender_name) where.push(" lower(t.title) like lower('%' || ${tender_name} || '%')");
        if (req.query.tender_id) where.push(" lower(t.tenderid) like lower('%' || ${tender_id} || '%')");
        if (req.query.requestingunit_name) where.push(" c.id in (select p.contractingprocess_id from parties p  join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true and lower(name) like lower('%' || ${requestingunit_name} || '%'))");

        const cp = await db_conf.edca_db.manyOrNone( select + (where.length > 0 ? 'where ' + where.join(' and ') : ''), req.query);

        res.render('modals/list_process',{ cp: cp, body: req.query });
    }
    catch(e) {
        res.render('ERROR');
    }
});

router.post('/admin/cp_options.html', isAuthenticated, function(req, res){

    User.find().then(function(users){


        db_conf.edca_db.manyOrNone('select * from user_contractingprocess where contractingprocess_id = $1', [
            req.body.contractingprocess_id
        ]).then(function(users_){

            let uu = [];
            //console.log('users -> ',users);
            //console.log('users_ -> ',users_);

            for (let u of users){

                let found = users_.find(function(obj){
                    return (obj.user_id === u._id.toString());
                });

                console.log('found -> ',found);

                uu.push({
                    ...u._doc,
                    selected: typeof found !== 'undefined'
                })
            }

            //console.log( uu );
            res.render('modals/cp_options', {
                contractingprocess_id: req.body.contractingprocess_id,
                users: uu
            });

        }).catch(function (error) {
            console.log(error);
            res.send('<p>Error</p>');
        });
    });
});

router.post('/admin/update-permissions', isAuthenticated, function(req, res){

    let contractingprocess_id = req.body.contractingprocess_id;
    let data = req.body;
    delete data.contractingprocess_id;

    console.log('data -> ', contractingprocess_id);

    db_conf.edca_db.manyOrNone('delete from user_contractingprocess where contractingprocess_id = $1 returning id', [
        contractingprocess_id
    ]).then(function (deleted) {

        console.log('deleted rows -> ', deleted);

        return db_conf.edca_db.tx(function (t) {

            let queries = [];
            for (let prop in data){
                console.log ('id -> ', prop);
                queries.push(t.one('insert into user_contractingprocess (user_id, contractingprocess_id) values ($1, $2) returning id', [
                    prop,
                    Number(contractingprocess_id)
                ]));
            }

            return t.batch(queries)
        });


    }).then(function (inserted) {
        console.log('inserted -> ', inserted);
        res.json({
            status: 'Ok',
            message: 'Los permisos se han modificado correctamente'
        });
    }).catch(function (error) {
        console.log(error);
        res.json({
            status: 'Error',
            message: 'Ocurrió un error al modificar los permisos'
        });
    });

});

/* Handle sign up */
router.post('/user', isAuthenticated, function (req, res) {
    console.log("Handle sign up");

    if ( req.user.isAdmin === true ) {
        const username = req.body.username.trim();

        User.findOne({'username': username}, function (err, user) {
            // In case of any error, return using the done method
            if (err) {
                console.log('Error in SignUp: ' + err);
                return done(err);
            }
            // already exists
            if (user) {
                console.log(`User already exists with username: ${username}`);
                res.jsonp({
                    status: 'Error',
                    message: `El usuario ${username} ya existe en la base de datos`
                });
                //return done(null, false, req.flash('message','User Already Exists'));
            } else {
                // if there is no user with that email
                // create the user
                let newUser = new User();

                // set the user's local credentials
                newUser.username = username;
                newUser.password = createHash(req.body.password);
                newUser.email = req.body.email;
                newUser.address = req.body.address;
                newUser.name = req.body.name;
                newUser.lastname = req.body.lastname;
                newUser.isAdmin = req.body.isAdmin === "true" ;
                newUser.publisherName = req.body.publisherName;
                newUser.publisherScheme = req.body.publisherScheme;
                newUser.publisherUid = req.body.publisherUid;
                newUser.publisherUri = req.body.publisherUri;
                newUser.modificaEstatus = req.body.modificaEstatus;
                newUser.isActive = req.body.isActive;

                // save the user
                newUser.save(function (err) {
                    if (err) {
                        console.log('Error in Saving user: ' + err);
                        res.jsonp({
                            status: "Error",
                            message: `Error al guardar el usuario ${usuario}`
                        });
                    }

                    res.jsonp({
                        status: "Ok",
                        message: `Se ha creado el usuario ${username}`
                    });
                });
            }
        });
    }else {
        res.send("<p><b>No estás autorizado para crear usuarios</b></p>");
    }

});

/* Handle Login POST */
router.post('/login', passport.authenticate('login', {
    successRedirect: '/main',
    failureRedirect: '/',
    failureFlash : true
}));

/* Handle Logout */
router.get('/signout', function(req, res) {
    req.logout();
    res.redirect('/');
});


/* GET main page. */
router.get('/main', isAuthenticated, function(req, res, next) {
    res.render('main', { user: req.user, title: 'Sistema de captura de datos de contrataciones abiertas en México' });
});

/* GET proyect page. */
// router.get('/proyecto', isAuthenticated, function(req, res, next) {
//     res.render('proyecto', { user: req.user, title: 'Sistema de captura de datos de contrataciones abiertas en México' });
// });

/* admin page */
router.get('/admin', isAuthenticated, function (req, res) {
    res.render('admin', {title: "Panel de administración del sistema", user: req.user });
});

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * */
router.post("/user-profile/", isAuthenticated, function (req, res) {
    var id = req.body.id;
    User.findOne({ '_id' : id }).then(function (data) {
        res.render('modals/user-profile',{user: data});
    });
});

router.post("/user-profile-admin/", isAuthenticated, function (req, res) {
    var id = req.body.id;
    User.findOne({ '_id' : id }).then(function (data) {
       res.render('modals/user-profile-admin',{user: data});
    });
});

router.post("/change-password/", isAuthenticated, function (req, res) {
    var id = req.body.id;
    User.findOne({ '_id' : id }).then(function (data) {
        res.render('modals/update-password',{user: data});
    });
});

router.post('/update/user/',isAuthenticated, function (req, res) {
    var id = req.body.id;
    var password = req.body.password;
    var email = req.body.email;
    var name = req.body.name;
    var lastname = req.body.lastname;
    var address= req.body.address;
    var publisherName= req.body.publisherName;
    var publisherScheme= req.body.publisherScheme;
    var publisherUid= req.body.publisherUid;
    var publisherUri= req.body.publisherUri;

    User.findOne({ '_id' : id }).then(function (data) {
        data.name = name;
        data.lastname = lastname;
        data.email = email;
        data.address = address;
        data.publisherName = publisherName;
        data.publisherScheme = publisherScheme;
        data.publisherUid = publisherUid;
        data.publisherUri = publisherUri;
        data.isAdmin = req.body.isAdmin;
        data.modificaEstatus = req.body.modificaEstatus;
        data.isActive = req.body.isActive;

        if (password != null && password != '') {
            data.password = bCrypt.hashSync(password, bCrypt.genSaltSync(10), null);
        }

        data.save();
        res.json({
            status : "Ok",
            description: "Los datos han sido actualizados"
        });
    }).catch(function (data) {
        console.log(data);
        res.json({
            status: "Error",
            description: "Ha ocurrido un error"
        })
    });

});

router.post("/delete-user/", isAuthenticated, function (req, res) {
    var id = req.body.id;
    
    res.render('modals/delete-user', { id: id });
});

router.post('/delete/user/', isAuthenticated, async (req, res) => {
    var id = req.body.id;
    try{
        await db_conf.edca_db.none("delete from user_contractingprocess where user_id = $1",[ id ]);
        await User.findOneAndRemove({ _id: id});

        return res.json({
            status: 'Ok',
            description: 'El usuario ha sido eliminado'
        });
    }catch(e) {
        console.log(e);
        return res.json({
            status: 'Error',
            description: 'No se ha podido eliminar el usuario'
        });
    }
});

router.post("/delete-contratacion/", isAuthenticated, function (req, res) {
    var id = req.body.id;
    
    res.render('modals/delete-contratacion', { id: id });
});

router.post('/delete/contratacion/', isAuthenticated, async (req, res) => {
    try{
        await db_conf.edca_db.none('delete from contractingprocess where id = $1',[ req.body.id ]);
        return res.json({
            status: 'Ok',
            description: 'La contratación ha sido eliminada'
        });
    }catch(e) {
        console.log(e);
        return res.json({
            status: 'Error',
            description: 'No se ha podido eliminar la contratación'
        });
    }
});

router.post('/update/password',isAuthenticated,function (req, res ) {

    var user_id = req.body.user_id;
    var old_pass = req.body.old_pass;
    var new_pass = req.body.new_pass;
    var confirm_pass = req.body.confirm_pass;

    User.findOne({ '_id' : user_id }).then(function (user) {

        if ( !isValidPassword(user, old_pass)){
            res.json({
                status : "Error",
                description: "Contraseña incorrecta"
            })
        } else if ( isValidPassword(user, old_pass) && new_pass === confirm_pass ){

            user.password =  bCrypt.hashSync( new_pass, bCrypt.genSaltSync(10), null);
            user.save();

            res.json({
                status: "Ok",
                description: "Contraseña actualizada"
            });
        } else if ( isValidPassword(user, old_pass) && new_pass !== confirm_pass ){
            res.json({
                status : "Error",
                description: "La nueva contraseña no coincide"
            })
        }

    }).catch(function (error) {
        console.log(error);
        res.json({
            status : "Error",
            description: "Ha ocurrido un error al actualizar la contraseña"
        })
    })

});


/* GET main page with data */
router.get('/main/:contractingprocess_id', isAuthenticated, async function (req,res) {

    var query;
    if (req.user.isAdmin){
        query = db_conf.edca_db.one('select id as contractingprocess_id from contractingprocess where id = $1', [
            req.params.contractingprocess_id
        ]);
    } else {
        query = db_conf.edca_db.one("select contractingprocess_id from user_contractingprocess where user_id = $1 and contractingprocess_id =$2", [
            req.user.id,
            req.params.contractingprocess_id
        ]);
    }

    // get prefix ocid
    const ocid = await getPrefixOCID();

    query.then(function (contratacion) {

        db_conf.edca_db.task(function (t) {
            // this = t = transaction protocol context;
            // this.ctx = transaction config + state context;
            return t.batch([
                t.one("select * from ContractingProcess where id = $1",  [contratacion.contractingprocess_id]),
                t.oneOrNone("select * from Planning where contractingprocess_id= $1", [contratacion.contractingprocess_id]),
                t.oneOrNone("select * from budget where contractingprocess_id = $1", [contratacion.contractingprocess_id]),
                t.oneOrNone("select * from Tender where contractingprocess_id = $1", [contratacion.contractingprocess_id]),
                t.manyOrNone("select id, awardid, status from Award where contractingprocess_id = $1 order by id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select id, contractid, status from Contract where contractingprocess_id = $1 order by id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select i.id, c.contractid, i.status from Implementation i join contract c on c.id = i.contract_id where i.contractingprocess_id = $1 order by i.id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
                t.manyOrNone("select * from implementationstatus"),
                t.oneOrNone("select id from award where contractingprocess_id = $1 and status is not null order by datelastupdate desc limit 1", [contratacion.contractingprocess_id]),
                t.oneOrNone("select id from contract where contractingprocess_id = $1 and status is not null order by datelastupdate desc limit 1", [contratacion.contractingprocess_id]),
                t.oneOrNone("select id from implementation where contractingprocess_id = $1 and status is not null order by datelastupdate desc  limit 1", [contratacion.contractingprocess_id]),
                t.manyOrNone("select partyid, name from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.requestingunit = true order by p.id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select partyid, name from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.contractingunit = true order by p.id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select partyid, name from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.responsibleunit = true order by p.id", [contratacion.contractingprocess_id]),
                t.manyOrNone("select * from planning_party_units p where p.contractingprocess_id = $1 order by p.id", [contratacion.contractingprocess_id]),
            ]);
        })
        // using .spread(function(user, event)) is best here, if supported;
            .then(function (data) {
            if(data[15] !== undefined){
                var arrayRequestingUnit = new Array();
                var arrayContractingUnit = new Array();
                var arrayResponsibleUnit = new Array();
                data[15].forEach(element => {
                    if(element.requesting_unit === true){
                        var unit = element.party_code+"-"+element.party_name
                        arrayRequestingUnit.push(unit);
                    }
                    if(element.contracting_unit === true){
                        var unit = element.party_code+"-"+element.party_name
                        arrayContractingUnit.push(unit);
                    }
                    if(element.responsible_unit === true){
                        var unit = element.party_code+"-"+element.party_name
                        arrayResponsibleUnit.push(unit);
                    }
                });
            }
                res.render('main', {
                    user: req.user,
                    title: 'Sistema de captura de datos de contrataciones abiertas en México',
                    cp: data[0],
                    planning: data[1] || {},
                    budget: data[2] || {},
                    tender: data[3] || {},
                    awards: data[4],
                    contracts: data[5],
                    implementations: data[6],
                    currencies : data[7],
                    implementation_status: implementationStatus,
                    award: data[9] || {}, // ultimo editado
                    contract: data[10] || {}, // ultimo editado
                    implementation: data[11] || {}, // utimo editado
                    requestingunit: data[12] || {},
                    contractingunit: data[13] || {},
                    responsibleunit: data[14] || {},
                    requestingunit_selected: arrayRequestingUnit || {},
                    contractingunit_selected: arrayContractingUnit || {},
                    responsibleunit_selected: arrayResponsibleUnit || {},
                    ocid: ocid.value || '' // prefix ocid
                });
            }).catch(function (error) {
            console.log("Error", error);
 
            res.render('main', {
                user: req.user,
                title: 'Sistema de captura de datos de contrataciones abiertas en México',
                error: 'Ha ocurrido un error al cargar el proceso de contratación'
            });
        });
    }).catch(function (error) {
        console.log("Error", error);

        res.render('main', {
            user: req.user,
            title: 'Sistema de captura de datos de contrataciones abiertas en México',
            error: 'Proceso de contratación no encontrado'
        });
    });

});

let udpatePublisher = async (cpid, user) => {
    await db_conf.edca_db.none('update Publisher set name = $2, scheme = $3, uid= $4, uri=$5 where ContractingProcess_id = $1', [
        cpid,
        user.publisherName,
        user.publisherScheme,
        user.publisherUid,
        user.publisherUri
    ]);
}

/**
 * Registrar historial
 * @param {Integer} cpid Id de la contratacion
 * @param {Object} user Usuario actual
 * @param {Integer} stage Stage donde se realiza el cambio
 */
let updateHisitory = async (cpid, user, stage, host)  => {
    
    await udpatePublisher(cpid, user);
    
    await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id  = $1', [cpid]);
    // fork another process
    const process = fork('./utilities/history.js');

    process.send({ cpid, user, stage, host });

    process.on('message', message => {
        process.kill()
    })
}

let validatedAll = async (id_cp, user, stage, host)  => {
    console.log(`Validando... id_cp - ${id_cp}`)
    updateHisitory(id_cp, user, stage, host);
    let record = require('../io/record')(db_conf.edca_db);
    await record.checkRecordIfExists(id_cp, host);           
    const vp = new VadalitionProcess(id_cp, db_conf.edca_db);
    const validationResult = await vp.validate();
    let valid = validationResult.valid;
    await db_conf.edca_db.none('update contractingprocess set valid = $1 where id = $2', [valid,id_cp]); 
}

let publishedAll = async (id_cp, publisher, host)  => {
    console.log(`Publicando... id_cp - ${id_cp}`)
    try{
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(id_cp, host);
        const vp = new VadalitionProcess(id_cp, db_conf.edca_db);
        const validationResult = await vp.validate();
        let v = validationResult.valid;
        await db_conf.edca_db.none('update contractingprocess set valid = $1 where id = $2', [v,id_cp]);
        if(validationResult.valid){
            //  se indica cual log es el que esta publicado
            await db_conf.edca_db.none('update logs set published = true where id in (SELECT id from logs WHERE contractingprocess_id = $1 ORDER BY update_date desc LIMIT 1 )', [id_cp]);

            // actualizar historial
            await db_conf.edca_db.none(`UPDATE contractingprocess SET
                                            published_version = (SELECT version FROM logs WHERE contractingprocess_id = $1 AND published = true ORDER BY update_date DESC LIMIT 1),
                                            date_published = now(),
                                            published = true,
                                            publisher = $2,
                                            updated = false
                                        WHERE id = $1`, [id_cp, publisher ? publisher.publisherName : 'Sin publicador']);

            return true;
        } else {
            return false;
        }
    }
    catch(e) {
        console.log(e);
        return res.status(400).json({message: 'No se ha podido publicar'});
    }
}

let sendToPNT = async (cp)  => {
    console.log(`Actualizando Status de PNT... id_cp - ${cp}`)
    try{
        // se indica que ya se actualizo en pnt
        await db_conf.edca_db.none(`update contractingprocess set 
                    pnt_published = true, 
                    pnt_date= now(),
                    pnt_version = (SELECT version FROM logs WHERE contractingprocess_id = $1 AND logs.published = true ORDER BY update_date DESC LIMIT 1) 
                where id = $1`, [cp]);
    }
    catch(e) {
        console.log(e);
        return res.status(400).json({message: 'No se ha podido actualizar el status'});
    }
}

let updateTags = (data) => {
    
    return db_conf.edca_db.one(`insert into tags (contractingProcess_id, stage, planning, planningUpdate, tender, tenderAmendment, tenderUpdate, tenderCancellation, award,
        awardUpdate, awardCancellation, contract, contractUpdate, contractAmendment, implementation, implementationUpdate, contractTermination, compiled, register_date)
        values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, clock_timestamp()) returning id`, [
        data.tags_id,
        data.tags_stage,
        isChecked(data.tags_planning),
        isChecked(data.tags_planningUpdate),
        isChecked(data.tags_tender),
        isChecked(data.tags_tenderAmendment),
        isChecked(data.tags_tenderUpdate),
        isChecked(data.tags_tenderCancellation),
        isChecked(data.tags_award),
        isChecked(data.tags_awardUpdate),
        isChecked(data.tags_awardCancellation),
        isChecked(data.tags_contract),
        isChecked(data.tags_contractUpdate),
        isChecked(data.tags_contractAmendment),
        isChecked(data.tags_implementation),
        isChecked(data.tags_implementationUpdate),
        isChecked(data.tags_contractTermination),
        isChecked(data.tags_compiled)
    ]).catch((error) => {
        console.log(error);
    });
}

let generateUUID = () => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

let registerLog = async (data) => {
    var logs = await db_conf.edca_db.one('select count(*) from logs where contractingProcess_id = $1', [data.ocid]);
    let {ocid} = await db_conf.edca_db.one('select ocid from contractingprocess where id = $1',[data.ocid]);

    // Verifica si es el primer cambio o si ya existe algun cambio en la etapa
    if (data.register || logs.count == 0) {
        let release = require('../io/release')(db_conf.edca_db);
        let stage = Object.keys(Stages)[data.stage-1];     
        data.version = parseInt(logs.count) + 1;
        let name = `${ocid}.v${data.version}.${stage}`;
        data.releaseFile = `${name}.json`;
        data.release_json = await release.generateRelease(data.ocid, name);

        await db_conf.edca_db.one(`insert into logs (version, update_date, publisher, release_file, contractingProcess_id, release_json)
            values ($1, clock_timestamp(), $2, $3, $4, $5) returning id`, [
            data.version,
            data.publisher,
            data.releaseFile,
            data.ocid,
            data.release_json
        ]);

    }
}

let registerRecord = async (ocid, host) => {
    let log = await db_conf.edca_db.one('select id, version from logs where contractingprocess_id = $1 order by update_date desc limit 1', [ocid]);
    let record = require('../io/record')(db_conf.edca_db);
    let record_json = await record.generateRecord(ocid, host);
    let version_json = await record.getChanges(ocid, record_json);
    await db_conf.edca_db.one('update logs set record_json = $1, version_json  = $3where id = $2 returning id', [record_json, log.id, version_json]);
};

// NUEVO PROCESO DE CONTRATACIÓN
router.post('/new-process', isAuthenticated, function (req, res) {
console.log("/new-process");
    db_conf.edca_db.tx(async function (t) {

        const allMetadata = await db_conf.edca_db.manyOrNone('select * from metadata');
        const ocid = await getPrefixOCID();
        const metadata = {
            licencia_url: '',
            politica_url: ''
        };
        if(allMetadata){
            allMetadata.map(m => metadata[m.field_name] = m.value);
        }
        metadata['ocid'] = (ocid ? ocid.value  || 'CONTRATACION': 'CONTRATACION') + '-';

        return t.one("insert into ContractingProcess (fecha_creacion, hora_creacion, ocid, stage, publicationpolicy, license ) values (current_date, current_time, concat( ${ocid}, current_date,'_', current_time), null, ${politica_url}, ${licencia_url}) returning id", metadata)
            .then(function (process) {

                return t.batch([
                    process = { id : process.id },
                    t.one("insert into Planning (ContractingProcess_id) values ($1) returning id as planning_id", process.id),
                    t.one("insert into Tender (ContractingProcess_id) values ($1) returning id as tender_id", [process.id]),
                    t.one("insert into Award (ContractingProcess_id) values ($1) returning id as award_id", [process.id]),
                    t.one("insert into Contract (ContractingProcess_id) values ($1) returning id as contract_id", [process.id]),
                    //t.one("insert into Buyer (ContractingProcess_id) values ($1) returning id as buyer_id",[process.id]),
                    t.one("insert into Publisher (ContractingProcess_id, name, scheme, uid, uri) values ($1, $2, $3, $4, $5) returning id as publisher_id", [
                        process.id,
                        req.user.publisherName,
                        req.user.publisherScheme,
                        req.user.publisherUid,
                        req.user.publisherUri
                    ]),
                    t.one("insert into user_contractingprocess(user_id, contractingprocess_id) values ($1,$2) returning id", [req.user.id, process.id]),
                    //t.one("insert into tags values (default, $1, true, false, false, false, false, false, false, false, false, false,false, false, false, false, false, false) returning id", [ process.id ]),
                    t.one("insert into links(contractingprocess_id) values ($1) returning id", [process.id])
                ]);

            }).then(function (info) {
                return t.batch([
                    //process, planning, tender, award, contract, buyer, publisher,
                    { contractingprocess : { id: info[0].id } },
                    { planning : { id: info[1].planning_id } },
                    { tender : { id: info[2].tender_id } },
                    { awards: [{ id:info[3].award_id }] },
                    { contracts: [{ id:info[4].contract_id }] },
                    //{ buyer : { id: info[5].buyer_id } },
                    { publisher: { id: info[6].publisher_id } },
                    t.one("insert into Budget (ContractingProcess_id, Planning_id) values ($1, $2 ) returning id as budget_id", [info[0].id, info[1].planning_id]),
                    //t.one("insert into ProcuringEntity (contractingprocess_id, tender_id) values ($1, $2) returning id as procuringentity_id",[info[0].id, info[2].tender_id]),
                    t.one("insert into Implementation (ContractingProcess_id, Contract_id ) values ($1, $2) returning id as implementation_id", [info[0].id, info[4].contract_id])
                ]);
            });

    }).then(function (data) {
        console.log(data);
        res.json( { url: `/main/${data[0].contractingprocess.id}` } );

    }).catch(function (error) {
        console.log("ERROR: ", error);
        res.json({"id": 0});
    });
});

var updateStageGlobal = async (cpid) => {
    try {
        let stage = 1;
        let sql = `select (select status from award where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as award_status,
                    (select status from contract where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as contract_status,
                    (select status from implementation where contractingprocess_id = contractingprocess.id and status is not null order by datelastupdate desc limit 1) as implementation_status,
                    t.status as tender_status
                from contractingprocess 
                join tender t on t.contractingprocess_id = contractingprocess.id
                where contractingprocess.id = ${cpid}`
        let contract = await db_conf.edca_db.oneOrNone(sql);

        if (contract.implementation_status === 'concluded' || contract.implementation_status === 'terminated') {
            stage = 5;
        } else if (contract.implementation_status !== 'concluded' && contract.contract_status === 'active') {
            stage = 5;
        } else if (contract.contract_status !== 'active' && contract.award_status === 'active') {
            stage = 4;
        } else if (contract.award_status !== 'active' && contract.tender_status === 'concluded') {
            stage = 3;
        } else
            stage = 2;

        await db_conf.edca_db.none('update contractingprocess set stage = ${stage} where id = ${id}', {
            stage: stage,
            id: cpid
        });
        await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id  = $1', [cpid]);

        console.log('stage updated');
    } catch (e) {
        console.log('error update stage');
    }
}

// update status of contractingprocess
router.post('/process/status', isAuthenticated, async (req, res) => {
    try{
        if(!req.user.isAdmin && !req.user.modificaEstatus){
            return res.send('No tienes permiso para realizar esta acción');
        }
       let stage = 0;
        switch(req.body.type){
            case 'award':
                req.body.stage = 
                await db_conf.edca_db.none('update contractingprocess set awardstatus = ${status} where id = ${cpid}', req.body);
                await db_conf.edca_db.none('update award set status = ${status} where contractingprocess_id = ${cpid} and id = ${id}', req.body);
                await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${cpid}', req.body);
                stage = Stages.award;
            break;
            case 'contract':
                await db_conf.edca_db.none('update contractingprocess set contractstatus = ${status} where id = ${cpid}', req.body);
                await db_conf.edca_db.none('update contract set status = ${status} where contractingprocess_id = ${cpid} and id = ${id}', req.body);
                await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${cpid}', req.body);
                stage = Stages.contract;
            break;
            case 'implementation':
                await db_conf.edca_db.none('update contractingprocess set implementationstatus = ${status} where id = ${cpid}', req.body);
                await db_conf.edca_db.none('update implementation set status = ${status} where contractingprocess_id = ${cpid} and id = ${id}', req.body);
                await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${cpid}', req.body);
                stage = Stages.implementation;
            break;
            case 'tender':
                await db_conf.edca_db.none('update tender set status = ${status} where contractingprocess_id = ${cpid}', req.body);
                await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${cpid}', req.body);
                stage = Stages.tender;
            break;
        }
        req.body.tags_id = req.body.cpid;
        updateHisitory(req.body.cpid, req.user, stage, getHost(req));
        
        await updateStageGlobal(req.body.cpid);
        await updateTags(req.body);
        res.send('Se ha actualizado el estatus');
    }
    catch(e) {
        res.status(400).send('No se ha podido actualizar el estatus');
    }
});

function dateCol( date ) {
    return (!date || date.trim() === '')?null:date;
}

function numericCol( number ){
    return (isNaN(number) || number === '') ? null : number;
}

function stringCol( str ){
    return ( str===''?null:str);
}

/* Update Planning -> Budget */
router.post('/update-planning', isAuthenticated, async function (req, res) {
    cp_functions.createPlanningPartyUnits(req.body);

    var register = await db_conf.edca_db.oneOrNone('select id from planning where contractingProcess_id = $1 and hasquotes is not null limit 1', [req.body.contractingprocess_id]) != null;
    db_conf.edca_db.tx( async function (t) {
        var planning = this.one("update planning set rationale = $1, hasquotes = $2, numberofbeneficiaries = $3 where ContractingProcess_id = $4 returning id", [
            req.body.rationale,
            req.body.hasquotes != '' ? req.body.hasquotes : null,
            req.body.numberofbeneficiaries,
            req.body.contractingprocess_id
        ]);
        var budget = this.one("update budget set budget_source = $2, budget_budgetid =$3, budget_description= $4, budget_amount=$5, budget_currency=$6, budget_project=$7, budget_projectid=$8, budget_uri=$9" +
            " where contractingprocess_id=$1 returning id",
            [
                parseInt(req.body.contractingprocess_id),
                req.body.budget_source,
                req.body.budget_budgetid,
                req.body.budget_description,
                numericCol(req.body.budget_amount),
                req.body.budget_currency,
                req.body.budget_project,
                req.body.budget_projectid,
                req.body.budget_uri
            ]);
        await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${contractingprocess_id}', req.body);
        await updateTags(req.body);

        return this.batch([planning, budget]);
    }).then(async function (data) {
        
        updateHisitory(req.body.contractingprocess_id, req.user, Stages.planning, getHost(req));
        res.send('La etapa de planeación ha sido actualizada');
        console.log('Update planning: ',data);
    }).catch(function (error) {
        console.log("ERROR: ",error);
        res.send('Error');
    });
});


router.post('/uris', isAuthenticated, function(req, res) {
    var id = Math.abs ( req.body.id );

    db_conf.edca_db.task(function(t){
        return this.batch([
            this.one("select * from contractingprocess where id = $1", [id])
        ]);
    }).then(function (data) {
        res.render('modals/uri', {
            contractingprocess: data[0]
        });
    }).catch(function (error) {
        console.log(error);
        res.render("<p>Error</p>");
    })
});
//Uris de project package
router.post('/uris-project', isAuthenticated, function(req, res) {
    var id = Math.abs ( req.body.id );
    project.findProject(id).then(value => {
        res.render('modals/uri_project', {
            project_package: value[0]
        });
    }).catch(function (error) {
        console.log(error);
        res.render("<p>Error</p>");
    });
});

let isChecked = (checkbox) => {
    if (typeof checkbox !== "undefined"){
        return checkbox === 'on'
    }
    return false;
};

// obsoleta
router.post('/update-uris', isAuthenticated, async function (req, res) {
    //console.log(req.body);

    db_conf.edca_db.tx(function (t) {
        return this.batch([
            this.one("update contractingprocess set uri =$1, publicationpolicy = $2, license = $3, destino=$4 where id = $5 returning id", [
                req.body.uri,
                req.body.publicationpolicy,
                req.body.license,
                req.body.destino,
                req.body.id
            ])
        ]);
    }).then(function (data) {
        console.log('Update URIs: ', data);
        res.json({
            status: "Ok",
            description: "Los datos han sido actualizados",
        });
    }).catch(function (error) {
        console.log(error);
        res.json({
            status: "Error",
            description: "Ha ocurrido un error"
        });
    });
});

router.post('/tags', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([]);
    }).then(function (data) {
        res.render('modals/tags', {
            id: req.body.id,
            stage: req.body.stage
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/update-tags', isAuthenticated, function (req, res) {
    db_conf.edca_db.tx(function (t) {
        return this.batch([
            updateTags(req.body)
        ]);
    }).then(function (data) {
        console.log('Update Tags: ', data);
        res.json({
            status: "Ok",
            description: "Los datos han sido actualizados",
        });
    }).catch(function (error) {
        console.log(error);
        res.json({
            status: "Error",
            description: "Ha ocurrido un error"
        });
    });
});

router.post('/logs', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select id, version, publisher, release_file, to_char(update_date, 'YYYY-MM-DD HH:MI:SS') as update_date_text from logs where contractingProcess_id = $1 and release_file is not null and publisher is not null order by id desc", [req.body.id])
        ]);
    }).then(function (data) {
        var publisher = new Object();
        data[0].map(function (e) {
            publisher.id =  e.publisher;
        });
        User.find().then(function (result) {
            data[0].map(function (e) {
                var user = result.find(function (i) { return i.id == e.publisher});
                if (user != null) {
                    e.publisher = user.username;
                } else {
                    e.publisher = '';
                }
                return e;
            });
            res.render('modals/logs', {
                logs: data[0]
            });
        });
    }).catch(function (error) {
        console.log(error);
    });
});

/* Update Tender*/
router.post('/update-tender',isAuthenticated, async function (req, res) {

    try {
        const tender = [
            req.body.contractingprocess_id,
            req.body.tenderid,
            req.body.title,
            req.body.description,
            stringCol(req.body.status), // se ignora
            numericCol(req.body.minvalue_amount),
            req.body.minvalue_currency,
            numericCol(req.body.value_amount),
            req.body.value_currency,
            stringCol(req.body.procurementmethod),
            req.body.procurementmethod_rationale,
            req.body.awardcriteria,
            req.body.awardcriteria_details,
            req.body.submissionmethod,
            req.body.submissionmethod_details,
            dateCol(req.body.tenderperiod_startdate),
            dateCol(req.body.tenderperiod_enddate),
            dateCol(req.body.enquiryperiod_startdate),
            dateCol(req.body.enquiryperiod_enddate),
            (req.body.hasenquiries === "true"),
            req.body.eligibilitycriteria,
            dateCol(req.body.awardperiod_startdate),
            dateCol(req.body.awardperiod_enddate),
            numericCol(req.body.numberoftenderers || null),
            dateCol(req.body.amendment_date),
            req.body.amendment_rationale,
            req.body.procurementmethod_details,
            stringCol(req.body.mainprocurementcategory),
            req.body.additionalprocurementcategories,
            req.body.procurementmethod_rationale_id
        ];

        const currentTenderid = await db_conf.edca_db.oneOrNone('select tenderid from tender where ContractingProcess_id = $1 ', tender);

        var register = await db_conf.edca_db.oneOrNone('select id from tender where contractingProcess_id = $1 and status is not null limit 1', [req.body.contractingprocess_id]) != null;

        let data = await db_conf.edca_db.one("update tender set tenderid =$2, title= $3, description=$4, minvalue_amount=$6, minvalue_currency=$7, value_amount=$8, value_currency=$9, procurementmethod=$10," +
            "procurementmethod_rationale=$11, awardcriteria=$12, awardcriteria_details=$13, submissionmethod=$14, submissionmethod_details=$15," +
            "tenderperiod_startdate=$16, tenderperiod_enddate=$17, enquiryperiod_startdate=$18, enquiryperiod_enddate=$19 ,hasenquiries=$20, eligibilitycriteria=$21, awardperiod_startdate=$22," +
            "awardperiod_enddate=$23, numberoftenderers=$24, amendment_date=$25, amendment_rationale=$26, procurementmethod_details =$27,  mainprocurementcategory=$28, additionalprocurementcategories=$29, procurementmethod_rationale_id=$30" +
            " where ContractingProcess_id = $1 returning id", tender);

        // update ocid
        let ocid = await getPrefixOCID();
        if(ocid.value) ocid.value = ocid.value + '-';
        ocid = (ocid.value  || '') + req.body.tenderid;
        ocid = ocid.replace(/\//g,'-');

        if (!register) {
            await db_conf.edca_db.none('update contractingprocess set ocid = $1, stage= $3, uri= $4 where id = $2', [ocid, req.body.contractingprocess_id, Stages.tender, getHost(req) + '/release-package/' + ocid]);
        } else {
            await db_conf.edca_db.none('update contractingprocess set ocid = $1, uri= $3 where id = $2', [ocid, req.body.contractingprocess_id, getHost(req) + '/release-package/' + ocid]);
        }
        await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id = ${contractingprocess_id}', req.body);
        await updateStageGlobal(req.body.contractingprocess_id);
        await updateTags(req.body);
        updateHisitory(req.body.contractingprocess_id, req.user, Stages.tender, getHost(req));

        console.log("Update tender: ", data);
        res.send("La etapa de licitación ha sido actualizada");
    }
    catch (e) {
        res.send("ERROR");
        console.log("ERROR: ", e);
    }
});

// partial view award
router.get('/award/:cpid/:id?', isAuthenticated, async (req, res) => {

    if(!req.params.id || req.params.id === '0'){
        req.params.id = (await db_conf.edca_db.one('insert into award (contractingProcess_id) values(${cpid}) returning id', req.params)).id;     
        updateHisitory(req.params.cpid, req.user, Stages.award, getHost(req));
    }

    let award = await db_conf.edca_db.oneOrNone('select * from award where contractingprocess_id = ${cpid} and id = ${id}', req.params);

    if(award != null) {
        award.suppliers = await db_conf.edca_db.manyOrNone('select parties_id id from awardsupplier where award_id = ${id}', req.params);
    }

    res.render('partials/award', {
        award: award,
        cpid: req.params.cpid,
        currencies: await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
        suppliers: await db_conf.edca_db.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = ${cpid} and roles.supplier = true order by parties.name", req.params)
    });
});

// partial list selector awards
router.get('/award-list/:cpid', isAuthenticated, async (req, res) => {
    const awards = await await db_conf.edca_db.manyOrNone('select id, status, awardid from award where  contractingprocess_id = ${cpid} order by id', req.params);
    awards.map(x => x.status = getValueStatus(TypesOfStatus.adjudicacion, x.status));
    const {current} = await db_conf.edca_db.oneOrNone('select id as current from award where contractingprocess_id = ${cpid} order by datelastupdate limit 1', req.params);

    return res.render('partials/award-list-selector', {
        awards: awards,
        cpid:  req.params.cpid,
        current: current
    });
});

/* Update Award */
router.post('/update-award',isAuthenticated, async function (req, res) {
    try{
        const params = [
            req.body.contractingprocess_id,
            req.body.awardid,
            req.body.title,
            req.body.description,
            stringCol(req.body.rationale),
            stringCol(req.body.status),
            dateCol(req.body.award_date),
            numericCol(req.body.value_amount),
            req.body.value_currency,
            dateCol(req.body.contractperiod_startdate),
            dateCol(req.body.contractperiod_enddate),
            dateCol(req.body.amendment_date),
            req.body.amendment_rationale,
            numericCol(req.body.value_amountnet),
            req.body.id
        ];

        var register = await db_conf.edca_db.oneOrNone('select id from award where contractingProcess_id = $1 and status is not null limit 1', [req.body.contractingprocess_id]) != null;

        let data = await db_conf.edca_db.one("update award set awardid=$2, title= $3, description=$4, rationale=$5, award_date=$7," +
                "value_amount=$8,value_currency=$9,contractperiod_startdate=$10," +
                "contractperiod_enddate=$11,amendment_date=$12,amendment_rationale=$13,value_amountnet=$14, datelastupdate = now() " +
                " where id = $15 returning id", params);

        // remove suppliers
        await db_conf.edca_db.none('delete from awardsupplier where award_id = $1', [req.body.id]);

        // add suppliers
        if(req.body.suppliers) {
            if(typeof req.body.suppliers === 'string')req.body.suppliers = [req.body.suppliers];
            for(let i = 0; i < req.body.suppliers.length; i++){
                await db_conf.edca_db.none('insert into awardsupplier (award_id, parties_id) values($1, $2)',[req.body.id, req.body.suppliers[i]]);
            }         
        }

      
        console.log("Update award: ", data);
        await db_conf.edca_db.none('update datapnt set data_pnt = false where contractingprocess_id  = $1', [req.body.contractingprocess_id]);
        await updateStageGlobal(req.body.contractingprocess_id);
        await updateTags(req.body);
        updateHisitory(req.body.contractingprocess_id, req.user, Stages.award, getHost(req));
        return res.status(200).json({message: "La etapa de adjudicación ha sido actualizada"});

    }
    catch(e) {
        console.log("ERROR: ",e);
        return res.status(400).json({message: "ERROR"});
    }
});


// Delete award
router.post('/delete-award/:cpid/:id', isAuthenticated, async (req, res) => {
    try{

        const {total} = await db_conf.edca_db.oneOrNone('select count(*) total from award where contractingprocess_id = ${cpid}', req.params);

        if(total === "1") {
            return res.status(400).json({message: 'No se puede eliminar la última adjudicación.'});
        }

        const {enuso} = await db_conf.edca_db.oneOrNone('select count(*) enuso from contract where awardid = ${id}', req.params);

        if(enuso !== "0") {
            return res.status(400).json({message: 'No se puede eliminar esta adjudicación porque esta en uso'});
        }

        await db_conf.edca_db.none('delete from award where id = ${id}', req.params);

        updateHisitory(req.params.cpid, req.user, Stages.award, getHost(req));
        return res.status(200).json({message: 'Adjudicación eliminada'})
    }
    catch(e){
        return res.status(400).json({message: 'No se ha podido eliminar la adjudicación'})
    }
});




// partial view contract
router.get('/contract/:cpid/:id?', isAuthenticated, async (req, res) => {

    if(!req.params.id || req.params.id === '0'){
        req.params.id = (await db_conf.edca_db.one('insert into contract (contractingProcess_id) values(${cpid}) returning id', req.params)).id;
        await db_conf.edca_db.none('insert into implementation(contractingprocess_id, contract_id) values(${cpid}, ${id})', req.params);    
        updateHisitory(req.params.cpid, req.user, Stages.contract, getHost(req));
    }

    res.render('partials/contract', {
        contract: await db_conf.edca_db.oneOrNone('select * from contract where contractingprocess_id = ${cpid} and id = ${id}', req.params),
        cpid: req.params.cpid,
        currencies: await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
        awards: await db_conf.edca_db.manyOrNone("select id, awardid from award where contractingprocess_id = $1 and awardid is not null order by awardid", [req.params.cpid])
    });
});

// partial list selector contracts
router.get('/contract-list/:cpid', isAuthenticated, async (req, res) => {
    const contracts = await await db_conf.edca_db.manyOrNone('select id, status, contractid from contract where  contractingprocess_id = ${cpid} order by id', req.params);
    contracts.map(x => x.status = getValueStatus(TypesOfStatus.contratacion, x.status));
    const {current} = await db_conf.edca_db.oneOrNone('select id as current from contract where contractingprocess_id = ${cpid} order by datelastupdate desc limit 1', req.params);

    return res.render('partials/contract-list-selector', {
        contracts: contracts,
        cpid:  req.params.cpid,
        current: current
    });
});


/* Update Contract */
router.post('/update-contract', isAuthenticated, async function (req, res) {
    try{
    var register = await db_conf.edca_db.oneOrNone('select id from contract where contractingProcess_id = $1 and status is not null limit 1', [req.body.contractingprocess_id]) != null;

    await db_conf.edca_db.one("update contract set contractid=$2, awardid=$3, title=$4, description=$5, period_startdate=$7, period_enddate=$8, value_amount=$9, value_currency=$10," +
    " datesigned=$11, amendment_date=$12, amendment_rationale=$13, value_amountnet=$14, exchangerate_rate=$15, exchangerate_amount=$16, exchangerate_currency=$17, exchangerate_date=$18, exchangerate_source=$19, surveillanceMechanisms=$20, datelastupdate = now()" +
    " where ContractingProcess_id = $1  and id = $21  returning id", [
        req.body.contractingprocess_id,
        req.body.contractid,
        req.body.awardid,
        req.body.title,
        req.body.description,
        stringCol(req.body.status),
        dateCol(req.body.period_startdate),
        dateCol(req.body.period_enddate),
        numericCol(req.body.value_amount),
        req.body.value_currency,
        dateCol(req.body.datesigned),
        dateCol(req.body.amendment_date),
        req.body.amendment_rationale,
        numericCol(req.body.value_amountnet),
        numericCol(req.body.exchangerate_rate),
		numericCol(req.body.exchangerate_amount),
		req.body.exchangerate_currency,
		dateCol(req.body.exchangerate_date),
        req.body.exchangerate_source,
        req.body.surveillanceMechanisms,
        req.body.id
    ]);

    await updateStageGlobal(req.body.contractingprocess_id);
    await updateTags(req.body);
    updateHisitory(req.body.contractingprocess_id, req.user, Stages.contract, getHost(req));

    return res.status(200).json({message: 'La etapa de contratación ha sido actualizada'});
    console.log("Update contract id: ", data);
}
catch(e) {
    res.status(400).send({message:'ERROR'});
    console.log("ERROR: ",e);
}

});

// Delete contract
router.post('/delete-contract/:cpid/:id', isAuthenticated, async (req, res) => {
    try{
        const {total} = await db_conf.edca_db.oneOrNone('select count(*) total from contract where contractingprocess_id = ${cpid}', req.params);

        if(total === "1") {
            return res.status(400).json({message: 'No se puede eliminar el último contrato.'});
        }

        await db_conf.edca_db.none('delete from contract where id = ${id}', req.params);
        updateHisitory(req.params.cpid, req.user, Stages.contract, getHost(req));
        return res.status(200).json({message: 'Contrato eliminado'})
    }
    catch(e){
        return res.status(400).json({message: 'No se ha podido eliminar el contrato'})
    }
});


// New document
router.post('/new-document', isAuthenticated, function(req,res){
    let sql = '';
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    if(req.body.fkname && req.body.fkid){
        sql =  'insert into $1~ (contractingprocess_id, document_type, documentid, title, description, url, date_published, date_modified, format, language, $12~) ' +
        'values ($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$13) returning id';
    } else {
        sql = 'insert into $1~ (contractingprocess_id, document_type, documentid, title, description, url, date_published, date_modified, format, language) ' +
        'values ($2,$3,$4,$5,$6,$7,$8,$9,$10,$11) returning id';
    }

    db_conf.edca_db.one(sql,
        [
            req.body.table,
            req.body.ocid,
            req.body.document_type,
            "doc-"+uuid(),//req.body.documentid,
            req.body.title,
            req.body.description,
            req.body.url,
            dateCol(req.body.date_published),
            dateCol(req.body.date_modified),
            req.body.format,
            req.body.language,
            req.body.fkname, // nombre del campo de la llave foranea
            req.body.fkid // valor de la llave foranea
        ]).then(async function (data) {

        let cambiarEstatusPorDocumento = require('../utilities/changeStatus');
        let cambio = await cambiarEstatusPorDocumento(req.body.ocid, req.body.document_type, req.body.fkname, req.body.fkid);

        updateHisitory(req.body.ocid, req.user, stage, getHost(req));
        

        res.json({
            status: 'Ok',
            description:"Se ha creado un nuevo documento",
            cambio: cambio
        });
        console.log("new "+ req.body.table + ": ", data);

       
    }).catch(function (error) {
        res.json({
            status : "Error",
            description: "Ha ocurrido un error"
        });
        console.log("Error: ", error);
    });
});


router.post('/newdoc-fields', function (req,res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select * from language"),
            this.manyOrNone("select * from documenttype where stage = $1 order by title_esp", [req.body.stage])
        ]);
    }).then(function (data) {
        res.render('modals/newdoc-fields',{
            localid: req.body.localid, 
            table: req.body.table, 
            languages: data[0], 
            documenttypes: data[1],
            fkname: req.body.fkname,
            fkid: req.body.fkid
        });
    }).catch(function (error) {
        console.log(error);
    });
});

// Edit document
router.post('/edit-document', isAuthenticated, function(req,res){
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];

    let sql = `update $1~ set document_type = $3, title = $4, description = $5, url = $6, date_published = $7, date_modified = $8, format = $9, language = $10
        where id = $2 returning contractingprocess_id`;

    db_conf.edca_db.one(sql, [
        req.body.table,
        req.body.id,
        req.body.document_type,
        req.body.title,
        req.body.description,
        req.body.url,
        dateCol(req.body.date_published),
        dateCol(req.body.date_modified),
        req.body.format,
        req.body.language
    ]).then(function (data) {
        res.json({
            status: 'Ok',
            description:"Se ha actualizado el documento"
        });
        updateHisitory(data.contractingprocess_id, req.user, stage, getHost(req));
        console.log("update "+ req.body.table + ": ", data);
    }).catch(function (error) {
        res.json({
            status : "Error",
            description: "Ha ocurrido un error"
        });

        console.log("Error: ", error);
    });
});

router.post('/editdoc-fields', function (req,res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one("select *, to_char(date_published, 'YYYY-MM-DD HH:MI:SS') as date_published_text, to_char(date_modified, 'YYYY-MM-DD HH:MI:SS') as date_modified_text from $1~ where id = $2", [req.body.table, req.body.id]),
            this.manyOrNone("select * from language"),
            this.manyOrNone("select * from documenttype where stage = $1 order by title", [req.body.stage])
        ]);
    }).then(function (data) {
        res.render('modals/edit-document', {
            table: req.body.table,
            document: data[0],
            languages: data[1],
            documenttypes: data[2]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-item',isAuthenticated,function (req,res) {
    let sql = '';
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    if (req.body.fkname && req.body.fkid) {
        sql = 'insert into $1~ (contractingprocess_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri,' +
        ' quantity, unit_name, unit_value_amountnet, unit_value_amount, unit_value_currency, $14~, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) ' +
        'values ($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$15,$16,$17,$18,$19,$20,$21,$22) returning id';
    } else  {
        sql = 'insert into $1~ (contractingprocess_id, itemid, description, classification_scheme, classification_id, classification_description, classification_uri,' +
        ' quantity, unit_name, unit_value_amountnet, unit_value_amount, unit_value_currency, latitude, longitude, location_postalcode, location_countryname, location_streetaddress, location_region, location_locality) values ($2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$16,$17,$18,$19,$20,$21,$22) returning id';
    }

    db_conf.edca_db.one(sql,
        [
            req.body.table,
            req.body.localid,
            "item-"+uuid(),//req.body.itemid,
            req.body.description,
            req.body.classification_scheme,
            req.body.classification_id,
            req.body.classification_description,
            req.body.classification_uri,
            numericCol(req.body.quantity),
            req.body.unit_name,
            numericCol(req.body.unit_value_amountNet),
            numericCol(req.body.unit_value_amount),
            req.body.unit_value_currency,
            req.body.fkname,
            req.body.fkid,
            numericCol(req.body.latitude),
            numericCol(req.body.longitude),
            req.body.location_postalcode,
            req.body.location_countryname,
            req.body.location_streetaddress,
            req.body.location_region,
            req.body.location_locality
        ]).then(async function (data) {
        console.log("New item: ", data);
        updateHisitory(req.body.localid, req.user, stage, getHost(req));
        res.json({
            status: 'Ok',
            description:'Datos registrados'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status: 'Ok',
            description: 'Ha ocurrido un error al registrar el hito'
        });
    });
});

router.post('/newitem-fields', function (req,res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select distinct currency, alphabetic_code from currency order by currency")
        ]);
    }).then(function (data) {
        res.render('modals/newitem-fields', {
            localid: req.body.localid,
            table: req.body.table,
            currencies: data[0],
            fkname: req.body.fkname,
            fkid: req.body.fkid
        });
    }).catch (function (error) {
        console.log(error);
    })
});

router.post('/edit-item', isAuthenticated, function (req, res) {
    let sql = `update $1~ set description = $3, classification_scheme = $4, classification_id = $5, classification_description = $6, classification_uri = $7,
        quantity = $8, unit_name = $9, unit_value_amountnet = $10, unit_value_amount = $11, unit_value_currency = $12, latitude = $13, longitude = $14, 
        location_postalcode = $15, location_countryname = $16, location_streetaddress = $17, location_region = $18, location_locality = $19
        where id = $2 returning contractingprocess_id`;
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    db_conf.edca_db.one(sql, [
        req.body.table,
        req.body.id,
        req.body.description,
        req.body.classification_scheme,
        req.body.classification_id,
        req.body.classification_description,
        req.body.classification_uri,
        numericCol(req.body.quantity),
        req.body.unit_name,
        numericCol(req.body.unit_value_amountNet),
        numericCol(req.body.unit_value_amount),
        req.body.unit_value_currency,
        numericCol(req.body.latitude),
        numericCol(req.body.longitude),
        req.body.location_postalcode,
        req.body.location_countryname,
        req.body.location_streetaddress,
        req.body.location_region,
        req.body.location_locality
    ]).then(function (data) {
        updateHisitory(data.contractingprocess_id, req.user, stage, getHost(req));
        console.log("Update item: ", data);
        res.json({
            status: 'Ok',
            description:'Datos actualizados'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status: 'Ok',
            description: 'Ha ocurrido un error al actualizar el item'
        });
    });
});

router.post('/edititem-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one("select * from $1~ where id = $2", [req.body.table, req.body.id]),
            this.manyOrNone("select distinct currency, alphabetic_code from currency order by currency")
        ]);
    }).then(function (data) {
        res.render('modals/edit-item', {
            table: req.body.table,
            item: data[0],
            currencies: data[1]
        });
    }).catch (function (error) {
        console.log(error);
    })
});

router.post('/new-milestone', isAuthenticated,function (req,res) {
    let sql = '';
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    if(req.body.fkname) {
        sql = 'insert into $1~ (contractingprocess_id, milestoneid, title, description, duedate, date_modified, type, status, $10~) ' +
        'values ($2,$3,$4,$5,$6,$7,$8,$9, $11) returning id';
    } else {
        sql = 'insert into $1~ (contractingprocess_id, milestoneid, title, description, duedate, date_modified, type, status) ' +
        'values ($2,$3,$4,$5,$6,$7,$8,$9) returning id';
    }

    db_conf.edca_db.one(sql,
        [
            req.body.table,
            req.body.localid,
            "milestone-"+uuid(),//req.body.milestoneid,
            req.body.title,
            req.body.description,
            dateCol(req.body.duedate),
            dateCol(req.body.date_modified),
            req.body.type,
            req.body.status,
            req.body.fkname,
            req.body.fkid
        ]).then(async function (data) {
        updateHisitory(req.body.localid, req.user, stage, getHost(req));
        res.json({
            status: 'Ok',
            description: 'Se ha registrado un nuevo hito'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status : "Error",
            description:'Ha ocurrido un error al registrar el hito'
        });
    });

});

router.post('/newmilestone-fields', function (req,res) {
    res.render('modals/newmilestone-fields', { localid: req.body.localid , table : req.body.table, fkname: req.body.fkname, fkid: req.body.fkid });
});

router.post('/edit-milestone', isAuthenticated, function (req, res) {
    let sql = `update $1~ set title = $3, description = $4, duedate = $5, date_modified = $6, type = $7, status = $8 where id = $2 returning contractingprocess_id`;
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    db_conf.edca_db.one(sql, [
        req.body.table,
        req.body.id,
        req.body.title,
        req.body.description,
        dateCol(req.body.duedate),
        dateCol(req.body.date_modified),
        req.body.type,
        req.body.status
    ]).then(function (data) {
        console.log("Edit milestone: ", data);
        updateHisitory(data.contractingprocess_id, req.user, stage, getHost(req));
        res.json({
            status: 'Ok',
            description: 'Se ha actualizado el hito'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status : "Error",
            description:'Ha ocurrido un error al actualizar el hito'
        });
    });
});

router.post('/editmilestone-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one("select *, to_char(duedate, 'YYYY-MM-DD HH:MI:SS') as duedate_text, to_char(date_modified, 'YYYY-MM-DD HH:MI:SS') as date_modified_text from $1~ where id = $2", [req.body.table, req.body.id])
        ]);
    }).then(function (data) {
        res.render('modals/edit-milestone', {
            table: req.body.table,
            milestone: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-transaction', isAuthenticated,function (req,res) {

    db_conf.edca_db.one('insert into implementationtransactions (contractingprocess_id, transactionid, source, ' +
        'implementation_date, value_amountnet, value_amount, value_currency, payment_method, ' +
        'payer_name,payer_id,' +
        'payee_name,payee_id, uri, implementation_id) ' +
        'values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13, $14) returning id',[
        req.body.localid,
        "transaction-"+uuid(),//req.body.transactionid,
        req.body.source,
        dateCol(req.body.implementation_date),
        numericCol(req.body.value_amountNet),
        numericCol(req.body.value_amount),
        req.body.value_currency,
        req.body.payment_method,

        req.body.payer_name,
        req.body.payer_id,

        req.body.payee_name,
        req.body.payee_id,

        req.body.uri,

        req.body.fkid
    ]).then(async function (data) {
        console.log('New transaction: ', data);
        updateHisitory(req.body.localid, req.user, Stages.implementation, getHost(req));
        res.json({
            status: 'Ok',
            description: 'Se ha creado una nueva transacción'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status:'Error',
            description: 'Ha ocurrido un error al registrar la transacción'
        });
    });
});

router.post('/newtransaction-fields', function (req,res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
            this.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.payer = true order by parties.name", [req.body.localid]),
            this.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.payee = true order by parties.name", [req.body.localid])
        ]);
    }).then(function (data) {
        res.render('modals/newtransaction-fields', {
            localid: req.body.localid,
            fkid: req.body.fkid,
            currencies: data[0],
            transmitters: data[1],
            receivers: data[2]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-transaction', isAuthenticated, function (req, res) {
    let sql = `update $1~ set implementation_date = $3, value_amountnet = $4, value_amount = $5, value_currency = $6, payment_method = $7, payer_name = $8, payer_id = $9,
        payee_name = $10, payee_id = $11, uri = $12
        where id = $2 returning contractingprocess_id`;

    db_conf.edca_db.one(sql, [
        req.body.table,
        req.body.id,
        dateCol(req.body.implementation_date),
        numericCol(req.body.value_amountNet),
        numericCol(req.body.value_amount),
        req.body.value_currency,
        req.body.payment_method,
        req.body.payer_name,
        req.body.payer_id,
        req.body.payee_name,
        req.body.payee_id,
        req.body.uri,
    ]).then(function (data) {
        console.log('Edit transaction: ', data);
        updateHisitory(data.contractingprocess_id, req.user, Stages.implementation, getHost(req));
        res.json({
            status: 'Ok',
            description: 'Se ha actualizado la transacción'
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.json({
            status:'Error',
            description: 'Ha ocurrido un error al actualizar la transacción'
        });
    });
});

router.post('/edittransaction-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one("select *, to_char(implementation_date, 'YYYY-MM-DD HH:MI:SS') as implementation_date_text from $1~ where id = $2", [req.body.table, req.body.id]),
            this.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
            this.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.payer = true order by parties.name", [req.body.ocid]),
            this.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and roles.payee = true order by parties.name", [req.body.ocid])
        ]);
    }).then(function (data) {
        res.render('modals/edit-transaction', {
            table: req.body.table,
            transaction: data[0],
            currencies: data[1],
            transmitters: data[2],
            receivers: data[3]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

// new amendment change
router.post('/new-amendment-change',isAuthenticated, function (req, res) {

    let sql = '';
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];

    if (req.body.fkname && req.body.fkid) {
        sql = 'insert into $1~ (contractingprocess_id, amendments_rationale, amendments_date, amendments_description, amendments_id ,$7~) values ($2,$3,$4,$5,$6, $8)  returning id';
    } else  {
        sql = 'insert into $1~ (contractingprocess_id, amendments_rationale, amendments_date, amendments_description, amendments_id) values ($2,$3,$4,$5,$6)  returning id';
    }

    db_conf.edca_db.one(sql,[
        req.body.table,
        req.body.localid,
        req.body.amendments_rationale,
        dateCol(req.body.amendments_date),
        req.body.amendments_description,
        req.body.amendments_id,
        req.body.fkname,
        req.body.fkid
    ]).then(async function (data) {
        updateHisitory(req.body.localid, req.user, stage, getHost(req));
        res.json({
            status : 'Ok',
            description: 'La modificación ha sido registrada'
        });
        console.log('New amendment change: ',data);
    }).catch(function (error) {
        res.json({
            status : 'Error',
            description: 'Ha ocurrido un error al registrar la modificación'
        });
        console.log('ERROR',error );
    });
});

router.post('/newamendmentchange-fields', function (req,res) {
    res.render('modals/newamendmentchange-fields', { localid: req.body.localid, table : req.body.table, fkname: req.body.fkname, fkid: req.body.fkid });
});

// edit amendment change
router.post('/edit-amendment-change', isAuthenticated, function (req, res) {
    let sql = `update $1~ set amendments_rationale = $3, amendments_date = $4, amendments_description = $5, amendments_id = $6 where id = $2 returning contractingprocess_id`;
    let stage = Object.keys(Stages).filter(key => req.body.table.startsWith(key)).map(key => Stages[key])[0];
    db_conf.edca_db.one(sql, [
        req.body.table,
        req.body.id,
        req.body.amendments_rationale,
        dateCol(req.body.amendments_date),
        req.body.amendments_description,
        req.body.amendments_id
    ]).then(function (data) {
        updateHisitory(data.contractingprocess_id, req.user, stage, getHost(req));
        res.json({
            status : 'Ok',
            description: 'La modificación ha sido actualizada'
        });
        console.log('Update amendment change: ', data);
    }).catch(function (error) {
        res.json({
            status : 'Error',
            description: 'Ha ocurrido un error al actualizar la modificación'
        });
        console.log('ERROR', error);
    });
});

router.post('/editamendmentchange-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one("select *, to_char(amendments_date, 'YYYY-MM-DD HH:MI:SS') as amendments_date_text from $1~ where id = $2", [req.body.table, req.body.id])
        ]);
    }).then(function (data) {
        res.render('modals/edit-amendmentchange', {
            table: req.body.table,
            change: data[0]
        });
    }).catch (function (error) {
        console.log(error);
    })
});

router.post('/new-quote-request', function (req, res) {
    let queryRequest = `insert into $1~ (contractingprocess_id, requestforquotes_id, title, description, period_startdate, period_enddate)
        values ($2, $3, $4, $5, $6, $7) returning id`;
    let queryItems = `insert into $1~ (requestforquotes_id, itemid, quantity, item) values ($2, $3, $4, $5) returning id`;
    let querySuppliers = `insert into $1~ (requestforquotes_id, parties_id) values ($2, $3) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(queryRequest, [
            'requestforquotes',
            req.body.ocid,
            `request-${generateUUID()}`,
            req.body.title,
            req.body.description,
            dateCol(req.body.period_startdate),
            dateCol(req.body.period_enddate)
        ]).then(function (e) {
            var tasks = [];

            if (req.body.items != null) {
                req.body.items.forEach(function (e2) {
                    tasks.push(t.one(queryItems, [
                        'requestforquotesitems',
                        e.id,
                        e2.itemid,
                        numericCol(e2.quantity),
                        e2.item
                    ]));
                });
            }
        
            if (req.body.invitedsuppliers != null) {
                if (typeof req.body.invitedsuppliers === 'string') {
                    req.body.invitedsuppliers = [req.body.invitedsuppliers];
                }

                req.body.invitedsuppliers.forEach(function (e2) {
                    tasks.push(t.one(querySuppliers, [
                        'requestforquotesinvitedsuppliers',
                        e.id,
                        e2
                    ]));
                });
            }

            return t.batch(tasks);
        });
    }).then(function (data) {
        updateHisitory(req.body.ocid, req.user, Stages.planning, getHost(req));
        res.json({
            status: 'Ok',
            description: 'La solicitud ha sido registrada'
        });

        console.log('New quote request: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar la solicitud'
        });

        console.log('ERROR', error);
    });
});

router.post('/new-admin-years', function (req, res) {
    console.log(`/new-admin-years ${JSON.stringify(req.body)}`)
    cp_functions.createFiscalYears(req.body).then(() =>{
        res.json({
            status: 'Ok',
            description: 'Ejercicio fiscal actualizado.'
        });
    });
});

router.post('/newquoterequest-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and (roles.invitedSupplier = true or roles.supplier = true) order by parties.name", [req.body.localid])
        ]);
    }).then(function (data) {
        res.render('modals/newquoterequest-fields', {
            localid: req.body.localid,
            suppliers: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-quote-request', function (req, res) {
    let queryRequest = `update $1~ set title = $3, description = $4, period_startdate = $5, period_enddate = $6 where id = $2 returning id`;
    let queryItems = `insert into $1~ (requestforquotes_id, itemid, quantity, item) values ($2, $3, $4, $5) returning id`;
    let querySuppliers = `insert into $1~ (requestforquotes_id, parties_id) values ($2, $3) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(queryRequest, [
            'requestforquotes',
            req.body.id,
            req.body.title,
            req.body.description,
            dateCol(req.body.period_startdate),
            dateCol(req.body.period_enddate)
        ]).then(function (e) {
            var tasks = [
                t.result(`delete from $1~ where requestforquotes_id = $2`, [
                    'requestforquotesitems',
                    e.id,
                ]),
                t.result(`delete from $1~ where requestforquotes_id = $2`, [
                    'requestforquotesinvitedsuppliers',
                    e.id,
                ])
            ];

            if (req.body.items != null) {
                req.body.items.forEach(function (e2) {
                    tasks.push(t.one(queryItems, [
                        'requestforquotesitems',
                        e.id,
                        e2.itemid,
                        numericCol(e2.quantity),
                        e2.item
                    ]));
                });
            }
        
            if (req.body.invitedsuppliers != null) {
                if (typeof req.body.invitedsuppliers === 'string') {
                    req.body.invitedsuppliers = [req.body.invitedsuppliers];
                }

                req.body.invitedsuppliers.forEach(function (e2) {
                    tasks.push(t.one(querySuppliers, [
                        'requestforquotesinvitedsuppliers',
                        e.id,
                        e2
                    ]));
                });
            }

            return t.batch(tasks);
        });
    }).then(async function (data) {
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from requestforquotes where id = ${id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));
        res.json({
            status: 'Ok',
            description: 'La solicitud ha sido actualizada'
        });

        console.log('Update quote request: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar la solicitud'
        });

        console.log('ERROR', error);
    });
});

router.post('/editquoterequest-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select *, to_char(period_startdate, 'YYYY-MM-DD HH:MI:SS') as period_startdate_text, to_char(period_enddate, 'YYYY-MM-DD HH:MI:SS') as period_enddate_text from requestforquotes where id = $1", [req.body.id]),
            t.manyOrNone("select parties_id from requestforquotesinvitedsuppliers where requestforquotes_id = $1", [req.body.id]),
            t.manyOrNone("select requestforquotesitems.*, item.description || ' / ' || item.unit as itemname from requestforquotesitems inner join item on requestforquotesitems.itemid = item.classificationid where requestforquotesitems.requestforquotes_id = $1", [req.body.id]),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and (roles.invitedSupplier = true or roles.supplier = true) order by parties.name", [req.body.ocid])
        ]);
    }).then(function (data) {
        res.render('modals/edit-quoterequest', {
            id: req.body.id,
            request: data[0],
            invitedSuppliers: data[1],
            items: data[2],
            suppliers: data[3]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-quote', async function (req, res) {
    let queryQuote = `insert into $1~ (requestforquotes_id, quotes_id, description, date, value, quotePeriod_startdate, quotePeriod_enddate, issuingSupplier_id)
        values ($2, $3, $4, $5, $6, $7, $8, $9) returning id`;
    let queryItems = `insert into $1~ (quotes_id, itemid, quantity, item) values ($2, $3, $4, $5) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(queryQuote, [
            'quotes',
            req.body.requestforquotes_id,
            `quote-${generateUUID()}`,
            req.body.description,
            dateCol(req.body.date),
            numericCol(req.body.value),
            dateCol(req.body.quotePeriod_startdate),
            dateCol(req.body.quotePeriod_enddate),
            req.body.issuingSupplier_id
        ]).then(function (e) {
            var tasks = [];

            if (req.body.items != null) {
                req.body.items.forEach(function (e2) {
                    tasks.push(t.one(queryItems, [
                        'quotesitems',
                        e.id,
                        e2.itemid,
                        numericCol(e2.quantity),
                        e2.item
                    ]));
                });
            }

            return t.batch(tasks);
        });
    }).then(async function (data) {
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from requestforquotes where id = ${requestforquotes_id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));
        res.json({
            status: 'Ok',
            description: 'La cotización ha sido registrada'
        });

        console.log('New quote: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar la cotización'
        });

        console.log('ERROR', error);
    });
});

router.post('/newquote-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select id, title from requestforquotes where contractingprocess_id = $1", [req.body.localid])
        ]);
    }).then(function (data) {
        res.render('modals/newquote-fields', {
            localid: req.body.localid,
            quoteRequests: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-quote', async function (req, res) {
    let queryQuote = `update $1~ set requestforquotes_id = $3, description = $4, date = $5, value = $6, quotePeriod_startdate = $7,
        quotePeriod_enddate = $8, issuingSupplier_id = $9 where id = $2 returning id`;
    let queryItems = `insert into $1~ (quotes_id, itemid, quantity, item) values ($2, $3, $4, $5) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(queryQuote, [
            'quotes',
            req.body.id,
            req.body.requestforquotes_id,
            req.body.description,
            dateCol(req.body.date),
            numericCol(req.body.value),
            dateCol(req.body.quotePeriod_startdate),
            dateCol(req.body.quotePeriod_enddate),
            req.body.issuingSupplier_id
        ]).then(function (e) {
            var tasks = [
                t.result(`delete from $1~ where quotes_id = $2`, [
                    'quotesitems',
                    e.id,
                ])
            ];

            if (req.body.items != null) {
                req.body.items.forEach(function (e2) {
                    tasks.push(t.one(queryItems, [
                        'quotesitems',
                        e.id,
                        e2.itemid,
                        numericCol(e2.quantity),
                        e2.item
                    ]));
                });
            }

            return t.batch(tasks);
        });
    }).then(async function (data) {

        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from requestforquotes where id = ${requestforquotes_id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));

        res.json({
            status: 'Ok',
            description: 'La cotización ha sido actualizada'
        });

        console.log('Update quote: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar la cotización'
        });

        console.log('ERROR', error);
    });
});

router.post('/editquote-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select quotes.*, to_char(quotes.date, 'YYYY-MM-DD HH:MI:SS') as date_text, to_char(quotes.quoteperiod_startdate, 'YYYY-MM-DD HH:MI:SS') as quoteperiod_startdate_text, to_char(quotes.quoteperiod_enddate, 'YYYY-MM-DD HH:MI:SS') as quoteperiod_enddate_text, requestforquotes.title as requestTitle from quotes inner join requestforquotes on quotes.requestforquotes_id = requestforquotes.id where quotes.id = $1", [req.body.id]),
            t.manyOrNone("select item.classificationid, item.description || ' / ' || item.unit as itemname, requestforquotesitems.quantity from requestforquotesitems inner join item on requestforquotesitems.itemid = item.classificationid where requestforquotesitems.requestforquotes_id = $1", [req.body.rid]),
            t.manyOrNone("select * from quotesitems where quotes_id = $1", [req.body.id]),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join requestforquotesinvitedsuppliers on requestforquotesinvitedsuppliers.parties_id = parties.id where requestforquotesinvitedsuppliers.requestforquotes_id = $1 order by parties.name", [req.body.rid])
        ]);
    }).then(function (data) {
        res.render('modals/edit-quote', {
            id: req.body.id,
            quote: data[0],
            items: data[1],
            selectedItems: data[2],
            suppliers: data[3]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/load-quote-dependencies', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select item.classificationid, item.description || ' / ' || item.unit as itemname, requestforquotesitems.quantity from requestforquotesitems inner join item on requestforquotesitems.itemid = item.classificationid where requestforquotesitems.requestforquotes_id = $1", [req.body.id]),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join requestforquotesinvitedsuppliers on requestforquotesinvitedsuppliers.parties_id = parties.id where requestforquotesinvitedsuppliers.requestforquotes_id = $1 order by parties.name", [req.body.id])
        ]);
    }).then(function (data) {
        res.json({
            items: data[0],
            suppliers: data[1]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-guarantee', function (req, res) {
    let query = '';

    if (req.body.fkname && req.body.fkid) {
        query = `insert into $1~ (guarantee_id, type, date, obligations, value, guarantor, guaranteePeriod_startdate, guaranteePeriod_enddate, contractingprocess_id, $11~, currency)
            values ($2, $3, $4, $5, $6, $7, $8, $9, $10, $12, $13) returning id`;
    } else {
        query = `insert into $1~ (guarantee_id, type, date, obligations, value, guarantor, guaranteePeriod_startdate, guaranteePeriod_enddate, contractingprocess_id, currency)
            values ($2, $3, $4, $5, $6, $7, $8, $9, $10,$13) returning id`;
    }

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            req.body.table,
            "guarantee-"+uuid(),
            req.body.type,
            dateCol(req.body.date),
            req.body.obligations,
            numericCol(req.body.value),
            req.body.guarantor,
            dateCol(req.body.guaranteePeriod_startdate),
            dateCol(req.body.guaranteePeriod_enddate),
            req.body.ocid,
            req.body.fkname,
            req.body.fkid,
            req.body.currency
        ]);
    }).then(async function (data) {

        updateHisitory(req.body.ocid, req.user, Stages.contract, getHost(req));
        res.json({
            status: 'Ok',
            description: 'La garantía ha sido registrada'
        });

        console.log('New guarantee: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar la garantía'
        });

        console.log('ERROR', error);
    });
});

router.post('/newguarantee-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and (roles.guarantor = true) order by parties.name", [req.body.localid])
        ]);
    }).then(async function (data) {
        res.render('modals/newguarantee-fields', {
            localid: req.body.localid,
            table: req.body.table,
            fkname: req.body.fkname,
            fkid: req.body.fkid,
            guarantors: data[0],
            currencies: await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency")
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-guarantee', function (req, res) {
    let query = `update $1~ set guarantee_id = $3, type = $4, date = $5, obligations = $6, value = $7, guarantor = $8, guaranteePeriod_startdate = $9,
        guaranteePeriod_enddate = $10, currency = $11 where id = $2 returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            req.body.table,
            req.body.id,
            req.body.guarantee_id,
            req.body.type,
            dateCol(req.body.date),
            req.body.obligations,
            numericCol(req.body.value),
            req.body.guarantor,
            dateCol(req.body.guaranteePeriod_startdate),
            dateCol(req.body.guaranteePeriod_enddate),
            req.body.currency
        ]);
    }).then(async function (data) {
        updateHisitory(req.body.ocid, req.user, Stages.contract, getHost(req));

        res.json({
            status: 'Ok',
            description: 'La garantía ha sido actualizada'
        });

        console.log('Update guarantee: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar la garantía'
        });

        console.log('ERROR', error);
    });
});

router.post('/editguarantee-fields', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select *, to_char(date, 'YYYY-MM-DD HH:MI:SS') as date_text, to_char(guaranteePeriod_startdate, 'YYYY-MM-DD HH:MI:SS') as guaranteePeriod_startdate_text, to_char(guaranteePeriod_enddate, 'YYYY-MM-DD HH:MI:SS') as guaranteePeriod_enddate_text from $1~ where id = $2", [
                req.body.table, 
                req.body.id
            ]),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 and (roles.guarantor = true) order by parties.name", [req.body.ocid])
        ]);
    }).then(async function (data) {
        res.render('modals/edit-guarantee', {
            id: req.body.id,
            table: req.body.table,
            ocid: req.body.ocid,
            guarantee: data[0],
            guarantors: data[1],
            currencies: await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency")
        });
    }).catch(function (error) {
        console.log(error);
    });
});


router.post('/new-relatedprocedure', isAuthenticated, function (req, res) {
    let query = `insert into $1~ (relatedprocedure_id, relationship_type, title, identifier_scheme, relatedprocedure_identifier, url, contractingprocess_id)
        values ($2, $3, $4, $5, $6, $7, $8) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'relatedprocedure',
            req.body.relatedprocedure_id,
            req.body.relationship_type,
            req.body.title,
            req.body.identifier_scheme,
            req.body.relatedprocedure_identifier,
            req.body.url,
            req.body.ocid
        ]);
    }).then(async function (data) {
        updateHisitory(req.body.ocid, req.user, null, getHost(req));

        res.json({
            status: 'Ok',
            description: 'El procedimiento relacionado ha sido registrado'
        });

        console.log('New related procedure: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar el procedimiento relacionado'
        });

        console.log('ERROR', error);
    });
});
// insert related summary procedure project
router.post('/insert-related-summary-procedure-project', isAuthenticated, function (req, res) {
    console.log("######### /insert-related-summary-procedure-project BODY " + JSON.stringify(req.body, null,4))
    console.log("######### /insert-related-summary-procedure-project USER " + JSON.stringify(req.user, null,4))
    project.insertRelatedContractingProcessProject(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Se relacionó correctamente la contratación al proyecto.',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(req.body.project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al relacionar la contratación al proyecto.'
        });
        console.log("ERROR - /insert-related-summary-procedure-project " + err)
    });
});
// update related summary procedure project
router.post('/update-related-summary-procedure-project', isAuthenticated,async function (req, res) {
    console.log("######### /update-related-summary-procedure-project BODY " + JSON.stringify(req.body, null, 4))
    var relRelatedProjectProject = await db.edcapi_project_related_contracting_process_project.findAll({where: {edcapiProjectRelatedContractingProcessId: req.body.contracting_process_id}});
    project.updateRelatedContractingProcessProject(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Se actualizó correctamente.',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(relRelatedProjectProject[0].project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar los datos.'
        });
        console.log("ERROR - /update-related-summary-procedure-project " + err)
    });
});
// add location project
router.post('/insert-location-project', isAuthenticated, function (req, res) {
    console.log("######### /insert-location-project BODY " + JSON.stringify(req.body, null, 4))
    project.insertLocationProject(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Las ubicaciones fueron registradas',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(req.body.project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar las ubicaciones'
        });
        console.log("ERROR - /insert-location-project " + err)
    });
});
// add documnet project
router.post('/insert-document-project', isAuthenticated, function (req, res) {
    console.log("######### /insert-document-project BODY " + JSON.stringify(req.body, null, 4))
    project.insertDocumentProject(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Los documentos fueron registrados.',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(req.body.project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar los documentos'
        });
        console.log("ERROR - /insert-document-project " + err)
    });
});

//Insert additional classifications
router.post('/insert-additional-classification', isAuthenticated, function (req, res) {
    console.log("######### /insert-additional-classification BODY " + JSON.stringify(req.body, null, 4))
    project.insertAdditionalClassification(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Las clasificaciones adicionales fueron registradas',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(req.body.project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar las clasificaciones adicionales'
        });
        console.log("ERROR - /insert-additional-classification " + err)
    });
});
//Insert Proyectos relacionados
router.post('/insert-related-projects', isAuthenticated, function (req, res) {
    console.log("######### /insert-related-projects BODY " + JSON.stringify(req.body, null, 4))
    project.insertRelatedProject(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Los proyectos relacionados fueron registrados.',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(req.body.project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar los proyectos relacionados'
        });
        console.log("ERROR - /insert-related-projects " + err)
    });
});

router.post('/newrelatedprocedure-fields', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.oneOrNone(`select last_value + 1 as id from public.relatedprocedure_id_seq where is_called`)
        ]);
    }).then(function (data) {
        res.render('modals/newrelatedprocedure-fields', {
            localid: req.body.localid,
            procedure: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//add_related_summary_procedure_project
router.post('/add_related_summary_procedure_project', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.oneOrNone(`select last_value + 1 as id from public.relatedprocedure_id_seq where is_called`)
        ]);
    }).then(function (data) {
        res.render('modals/add_related_summary_procedure_project', {
            projectId: req.body.project_id,
            procedure: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//edit_related_summary_procedure_project
router.post('/edit_related_summary_procedure_project', isAuthenticated,async function (req, res) {
    var related_contracting_process = await db.edcapi_project_related_contracting_process.findByPk(req.body.contracting_process_id); 
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.oneOrNone(`select last_value + 1 as id from public.relatedprocedure_id_seq where is_called`)
        ]);
    }).then(function (data) {
        res.render('modals/edit_related_summary_procedure_project', {
            contractingProcessId: req.body.contracting_process_id,
            procedure: data[0],
            contractingProcess : related_contracting_process
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//add location project
router.post('/add-location-project', isAuthenticated, async function (req, res) {
    var geometry_type = await db.edcapi_cat_geometry_type.findAll({ order: [['title', 'ASC']],attributes: ['code','title']}).then(async function (geometry_type) {
        res.render('modals/add_location_project',{
            project_id: req.body.project_id,
            geometryTypes: geometry_type
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//add document project
router.post('/add-document-project', isAuthenticated, async function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select * from language")
        ]);
    }).then(async function (data) {
        var document_type = await db.edcapi_cat_document_type.findAll({ order: [['title', 'ASC']],attributes: ['code','title']});
        res.render('modals/add_document_project',{
            project_id: req.body.project_id,
            languages: data[0], 
            documentTypes: document_type
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//Additional classification
router.post('/add-additional-classification', isAuthenticated, function (req, res) {
    res.render('modals/add_additional_classification', {
        projectId: req.body.projectId
    });
});
//Related projects
router.post('/add-related-projects', isAuthenticated, async function (req, res) {
    var related_projects = await db.edcapi_cat_related_projects.findAll({ attributes: ['code','title']});
    var related_projects_scheme = await db.edcapi_cat_related_projects_scheme.findAll({ attributes: ['code','title']});
    var prefix = await db.edcapi_project_prefix.findAll({ attributes: ['prefix']});    
    res.render('modals/add_related_projects', {
        projectId: req.body.projectId,
        relatedProjects: related_projects,
        relatedProjectsScheme: related_projects_scheme,
        prefix: prefix
    });
    
});

router.post('/edit-relatedprocedure', isAuthenticated, function (req, res) {
    let query = `update $1~ set relatedprocedure_id = $3, relationship_type = $4, title = $5, identifier_scheme = $6, relatedprocedure_identifier = $7, url = $8
        where id = $2 returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'relatedprocedure',
            req.body.id,
            req.body.relatedprocedure_id,
            req.body.relationship_type,
            req.body.title,
            req.body.identifier_scheme,
            req.body.relatedprocedure_identifier,
            req.body.url
        ]);
    }).then(async function (data) {
        updateHisitory(req.body.ocid, req.user, null, getHost(req));

        res.json({
            status: 'Ok',
            description: 'El procedimiento relacionado ha sido actualizado'
        });

        console.log('Update related procedure: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar el procedimiento relacionado'
        });

        console.log('ERROR', error);
    });
});

router.post('/editrelatedprocedure-fields', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select * from $1~ where id = $2", ['relatedprocedure', req.body.id])
        ]);
    }).then(function (data) {
        res.render('modals/edit-relatedprocedure', {
            id: req.body.id,
            ocid: req.body.ocid,
            procedure: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-contactpoint', isAuthenticated, async function (req, res) {
    let query = `insert into $1~ (party_id, type, name, givenname, surname, additionalsurname, email, telephone, faxnumber, url, language)
        values ($2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'additionalcontactpoints',
            req.body.party_id,
            req.body.type,
            `${req.body.givenname} ${req.body.surname} ${req.body.additionalsurname}`.trim(),
            req.body.givenname,
            req.body.surname,
            req.body.additionalsurname,
            req.body.email,
            req.body.telephone,
            req.body.faxnumber,
            req.body.url,
            req.body.language && typeof(req.body.language) !== 'string' ? req.body.language.join(',') : req.body.language
        ]);
    }).then(async function (data) {
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from parties where id = ${party_id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));
        res.json({
            status: 'Ok',
            message: 'El punto de contacto adicional ha sido registrado'
        });

        console.log('New guarantee: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            message: 'Ha ocurrido un error al registrar el punto de contacto adicional'
        });

        console.log('ERROR', error);
    });
});

router.post('/newcontactpoint-fields', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            this.manyOrNone("select * from language")
        ]);
    }).then(function (data) {
        res.render('modals/newcontactpoint-fields', {
            partyid: req.body.partyid,
            languages: data[0]
        });
    }).catch(function (error) {
        console.log(error);
    });
});
//Aditional identifiers party project
router.post('/add-additional-identifiers', isAuthenticated, function (req, res) {
    res.render('modals/add_additional_identifiers', {
        partyId: req.body.partyId
    });
});
//Edit Aditional identifiers party project
router.post('/edit-additional-identifiers', isAuthenticated, function (req, res) {
    project.findParty(req.body.partyId).then(value => {
        console.log("#### findParty: " + JSON.stringify(value[0].additionalIdentifiers))
        res.render('modals/additional_identifiers_list',{
            data: value[0].additionalIdentifiers
        });
    });
});
//budget lines project
router.post('/add-budget-lines', isAuthenticated, function (req, res) {
    res.render('modals/add_budget_lines', {
        budgetBreakdownId: req.body.budgetBreakdownId
    });
});
//Edit lines project
router.post('/edit-budget-lines', isAuthenticated, function (req, res) {
    project.findBudgetBreakdown(req.body.budgetBreakdownId).then(value => {
        console.log("#### findBudgetBreakdown: " + JSON.stringify(value))
        res.render('modals/budget_lines_list',{
            data: value[0].budgetLines
        });
    });
});
//budget line measure project
router.post('/add-budget-line-measure', isAuthenticated,async function (req, res) {
    var currency = await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency");
    var budget_types = await db.edcapi_cat_budget_moment_type.findAll({ attributes: ['code','title']});
    res.render('modals/add_budget_line_measures', {
        budgetLineId: req.body.budgetLineId,
        currencies: currency,
        budgetTypes: budget_types
    });
});
//edit budget line measure project
router.post('/edit-budget-line-measure', isAuthenticated,async function (req, res) {
    console.log("#### edit-budget-lines-measures: " + JSON.stringify(req.body))
    project.findBudgetLineMeasure(req.body.budgetLineId).then(value => {
        console.log("#### findBudgetBreakdown: " + JSON.stringify(value[0].measures,null,4))
        res.render('modals/budget_lines_measure_list',{
            data: value[0].measures
        });
    });
});
router.post('/edit-contactpoint', isAuthenticated, async function (req, res) {
    let query = `update $1~ set type = $3, name = $4, givenname = $5, surname = $6, additionalsurname = $7, email = $8, telephone = $9, faxnumber = $10,
        url = $11, language = $12 where id = $2 returning party_id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'additionalcontactpoints',
            req.body.id,
            req.body.type,
            `${req.body.givenname} ${req.body.surname} ${req.body.additionalsurname}`.trim(),
            req.body.givenname,
            req.body.surname,
            req.body.additionalsurname,
            req.body.email,
            req.body.telephone,
            req.body.faxnumber,
            req.body.url,
            req.body.language && typeof(req.body.language) !== 'string' ?req.body.language.join(','):req.body.language
        ]);
    }).then(async function (data) {
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from parties where id in (select party_id from additionalcontactpoints where id = ${id}) limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));

        res.json({
            status: 'Ok',
            message: 'El punto de contacto adicional ha sido actualizado'
        });

        console.log('Update contact point: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            message: 'Ha ocurrido un error al actualizar el punto de contacto adicional'
        });

        console.log('ERROR', error);
    });
});

router.post('/editcontactpoint-fields', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            this.one("select * from $1~ where id = $2", ['additionalcontactpoints', req.body.id]),
            this.manyOrNone("select * from language")
        ]);
    }).then(function (data) {
        res.render('modals/edit-contactpoint', {
            id: req.body.id,
            data: data[0],
            languages: data[1]
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-budgetbreakdown', isAuthenticated, function (req, res) {
    let query = `insert into $1~ (description, amount, currency, url, budgetbreakdownPeriod_startdate, budgetbreakdownPeriod_enddate, source_id, contractingprocess_id, origin, fund_type)
        values ($2, $3, $4, $5, $6, $7, $8, $9, $10, $11) returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'budgetbreakdown',
            req.body.description,
            numericCol(req.body.amount),
            req.body.currency,
            req.body.url,
            dateCol(req.body.budgetbreakdownPeriod_startdate),
            dateCol(req.body.budgetbreakdownPeriod_enddate),
            req.body.source_id,
            req.body.ocid,
            req.body.origin,
            req.body.fundType
        ]);
    }).then(function (data) {
        console.log("#### budgetbreakdown ID " + JSON.stringify(data,null,4))
        updateHisitory(req.body.ocid, req.user, Stages.planning, getHost(req));

        res.json({
            status: 'Ok',
            description: 'El desglose del presupuesto ha sido registrado',
            id: data.id
        });

        console.log('New budget breakdown: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar el desglose del presupuesto'
        });

        console.log('ERROR', error);
    });
});
//new aditional identifiers party project
router.post('/1.1/new-additional-identifiers', isAuthenticated,async function (req, res) {
    console.log("######### /new-additional-identifiers BODY " + JSON.stringify(req.body, null, 4))
    var relProjectPartyProject = await db.edcapi_project_party_project.findAll({
        where: {edcapiProjectPartyId: req.body.party_id}
    }); 

    project.insertAdditionalIdentifier(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Los identificadores adicionales fueron registrados.',
        });
        return true;
    }).then(function(){
        project.updatePublishedDate(relProjectPartyProject[0].project_id,req.user);
    }).catch(function(err){
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar el desglose del presupuesto'
        });
        console.log("ERROR - /1.1/new-additional-identifiers" + err)
    });
});

//new budget lines project
router.post('/1.1/new-budget-lines', isAuthenticated,async function (req, res) {
    console.log("######### /new-budget-lines BODY " + JSON.stringify(req.body, null, 4))
    project.insertBudgetLinesComponent(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Las lineas presupuestarias fueron registradas.',
        });
    });
    // var relProjectPartyProject = await db.edcapi_project_party_project.findAll({
    //     where: {edcapiProjectPartyId: req.body.party_id}
    // }); 

    // project.insertAdditionalIdentifier(JSON.stringify(req.body)).then(function (){
    //     res.json({
    //         status: 'Ok',
    //         description: 'Los identificadores adicionales fueron registrados.',
    //     });
    //     return true;
    // }).then(function(){
    //     project.updatePublishedDate(relProjectPartyProject[0].project_id);
    // }).catch(function(err){
    //     res.json({
    //         status: 'Error',
    //         description: 'Ha ocurrido un error al registrar el desglose del presupuesto'
    //     });
    //     console.log("ERROR - /1.1/new-additional-identifiers" + err)
    // });
});

//new budget line moment project
router.post('/1.1/new-budget-line-measure', isAuthenticated,async function (req, res) {
    console.log("######### /new-budget-line-measure BODY " + JSON.stringify(req.body, null, 4))
    project.insertBudgetLinesMeasure(JSON.stringify(req.body)).then(function (){
        res.json({
            status: 'Ok',
            description: 'Los momentos presupuestarios fueron registrados.',
        });
    });
    // var relProjectPartyProject = await db.edcapi_project_party_project.findAll({
    //     where: {edcapiProjectPartyId: req.body.party_id}
    // }); 

    // project.insertAdditionalIdentifier(JSON.stringify(req.body)).then(function (){
    //     res.json({
    //         status: 'Ok',
    //         description: 'Los identificadores adicionales fueron registrados.',
    //     });
    //     return true;
    // }).then(function(){
    //     project.updatePublishedDate(relProjectPartyProject[0].project_id);
    // }).catch(function(err){
    //     res.json({
    //         status: 'Error',
    //         description: 'Ha ocurrido un error al registrar el desglose del presupuesto'
    //     });
    //     console.log("ERROR - /1.1/new-additional-identifiers" + err)
    // });
});

router.post('/newbudgetbreakdown-fields', isAuthenticated,async function (req, res) {
    var origin = await db.edca_cat_origin.findAll({ attributes: ['id','value']});
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 order by parties.name", [req.body.localid])
        ]);
    }).then(function (data) {
        res.render('modals/newbudgetbreakdown-fields', {
            localid: req.body.localid,
            currencies: data[0],
            sources: data[1],
            origins: origin
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-budgetbreakdown', isAuthenticated, async function (req, res) {
    let query = `update $1~ set budgetbreakdown_id = $3, description = $4, amount = $5, currency = $6, url = $7, budgetbreakdownPeriod_startdate = $8,
    budgetbreakdownPeriod_enddate = $9, source_id = $10, origin = $11, fund_type = $12 where id = $2 returning id`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'budgetbreakdown',
            req.body.id,
            req.body.budgetbreakdown_id,
            req.body.description,
            numericCol(req.body.amount),
            req.body.currency,
            req.body.url,
            dateCol(req.body.budgetbreakdownPeriod_startdate),
            dateCol(req.body.budgetbreakdownPeriod_enddate),
            req.body.source_id,
            req.body.origin,
            req.body.fundType
        ]);
    }).then(async function (data) {
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from budgetbreakdown where id = ${id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));
        res.json({
            status: 'Ok',
            description: 'El desglose del presupuesto ha sido actualizado'
        });

        console.log('Update budget breakdown: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar el desglose del presupuesto'
        });

        console.log('ERROR', error);
    });
});

router.post('/editbudgetbreakdown-fields', isAuthenticated,async function (req, res) {
    var origin = await db.edca_cat_origin.findAll({ attributes: ['id','value']});
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select *, to_char(budgetbreakdownPeriod_startdate, 'YYYY-MM-DD') as budgetbreakdownPeriod_startdate_text, to_char(budgetbreakdownPeriod_enddate, 'YYYY-MM-DD') as budgetbreakdownPeriod_enddate_text from $1~ where id = $2", ['budgetbreakdown', req.body.id]),
            t.manyOrNone("select distinct currency, alphabetic_code from currency order by currency"),
            t.manyOrNone("select parties.id, parties.partyid, parties.name from parties inner join roles on roles.parties_id = parties.id where parties.contractingprocess_id = $1 order by parties.name", [req.body.ocid])
        ]);
    }).then(function (data) {
        console.log("### DATA: " + JSON.stringify(data,null,4))
        res.render('modals/edit-budgetbreakdown', {
            id: req.body.id,
            budget: data[0],
            currencies: data[1],
            sources: data[2],
            origins: origin
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/new-budgetclassification', isAuthenticated, async function (req, res) {
    let query = `insert into $1~ (budgetbreakdown_id, year, trimester, branch, responsibleunit, finality, function, subfunction, institutionalactivity, budgetprogram, strategicobjective,
        requestingunit, specificactivity, spendingobject, spendingtype, budgetsource, region, portfoliokey, cve, approved, modified, executed, committed, reserved)
        values ($2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25) returning id`;

    let measure = await db_conf.edca_db.oneOrNone(`select approvedamount, modifiedamount, executedamount, committedamount, reservedamount from programaticstructure where year = $1 and requestingunit = $2 and
    specificactivity = $3 and spendingobject = $4 limit 1`, [req.body.year, req.body.requestingunit, req.body.specificactivity, req.body.spendingobject]);

    let cve = `${(req.body.year || '').toString().padStart(4, '0')}${(req.body.branch || '').padStart(2, '0')}${(req.body.responsibleunit || '').padStart(3, '0')}${(req.body.finality || '').padStart(1, '0')}${(req.body.function || '').padStart(1, '0')}${(req.body.subfunction || '').padStart(2, '0')}${(req.body.institutionalactivity || '').padStart(3, '0')}${(req.body.budgetprogram || '').padStart(4, '0')}${(req.body.strategicobjective || '').padStart(3, '0')}${(req.body.requestingunit || '').padStart(3, '0')}${(req.body.specificactivity || '').padStart(5, '0')}${(req.body.spendingobject || '').padStart(5, '0')}${(req.body.spendingtype || '').padStart(1, '0')}${(req.body.budgetsource || '').padStart(1, '0')}${(req.body.region || '').padStart(2, '0')}${(req.body.portfoliokey || '').padStart(1, '0')}`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'budgetclassifications',
            req.body.budget_id,
            req.body.year,
            req.body.trimester,
            req.body.branch,
            req.body.responsibleunit,
            req.body.finality,
            req.body.function,
            req.body.subfunction,
            req.body.institutionalactivity,
            req.body.budgetprogram,
            req.body.strategicobjective,
            req.body.requestingunit,
            req.body.specificactivity,
            req.body.spendingobject,
            req.body.spendingtype,
            req.body.budgetsource,
            req.body.region,
            req.body.portfoliokey,
            cve,
            numericCol(measure != null ? measure.approvedamount : null),
            numericCol(measure != null ? measure.modifiedamount : null),
            numericCol(measure != null ? measure.executedamount : null),
            numericCol(measure != null ? measure.committedamount : null),
            numericCol(measure != null ? measure.reservedamount : null)
        ]);
    }).then(async function (data) {
        await db_conf.edca_db.one(`update budgetbreakdown set budgetbreakdown_id = (select string_agg(cve, ',') from budgetclassifications where budgetbreakdown_id = $1), amount = (select round(sum(approved), 2) from budgetclassifications where budgetbreakdown_id = $1) where id = $1 returning id`, [req.body.budget_id]);
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from budgetbreakdown where id = ${budget_id} limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));

        res.json({
            status: 'Ok',
            description: 'La clasificación del presupuesto ha sido registrada'
        });

        console.log('New budget classification: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al registrar la clasificacion del presupuesto'
        });

        console.log('ERROR', error);
    });
});

router.post('/newbudgetclassification-fields', isAuthenticated, function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select year as value, year as name from programaticstructure where year is not null group by year order by year desc"),
            t.manyOrNone("select distinct requestingunit as value,  requestingunit || ' - ' || requestingunit_desc as name from programaticstructure order by requestingunit")]);
    }).then(function (data) {
        res.render('modals/newbudgetclassification-fields', {
            budgetid: req.body.budgetid,
            years: data[0],
            units: data[1],
            activities: []
        });
    }).catch(function (error) {
        console.log(error);
    });
});

router.post('/edit-budgetclassification', isAuthenticated, async function (req, res) {
    let query = `update $1~ set year = $3, trimester = $4, branch = $5, responsibleunit = $6, finality = $7, function = $8, subfunction = $9, institutionalactivity = $10, budgetprogram = $11,
        strategicobjective = $12, requestingunit = $13, specificactivity = $14, spendingobject = $15, spendingtype = $16, budgetsource = $17, region = $18, portfoliokey = $19,
        cve = $20, approved = $21, modified = $22, executed = $23, committed = $24, reserved = $25 where id = $2 returning id`;
    
    let measure = await db_conf.edca_db.oneOrNone(`select approvedamount, modifiedamount, executedamount, committedamount, reservedamount from programaticstructure where year = $1 and requestingunit like $2 and
    specificactivity like $3 and spendingobject like $4 limit 1`, [req.body.year, req.body.requestingunit, req.body.specificactivity, req.body.spendingobject]);

    let cve = `${(req.body.year || '').toString().padStart(4, '0')}${(req.body.branch || '').padStart(2, '0')}${(req.body.responsibleunit || '').padStart(3, '0')}${(req.body.finality || '').padStart(1, '0')}${(req.body.function || '').padStart(1, '0')}${(req.body.subfunction || '').padStart(2, '0')}${(req.body.institutionalactivity || '').padStart(3, '0')}${(req.body.budgetprogram || '').padStart(4, '0')}${(req.body.strategicobjective || '').padStart(3, '0')}${(req.body.requestingunit || '').padStart(3, '0')}${(req.body.specificactivity || '').padStart(5, '0')}${(req.body.spendingobject || '').padStart(5, '0')}${(req.body.spendingtype || '').padStart(1, '0')}${(req.body.budgetsource || '').padStart(1, '0')}${(req.body.region || '').padStart(2, '0')}${(req.body.portfoliokey || '').padStart(1, '0')}`;

    db_conf.edca_db.task(function (t) {
        return t.one(query, [
            'budgetclassifications',
            req.body.id,
            req.body.year,
            req.body.trimester,
            req.body.branch,
            req.body.responsibleunit,
            req.body.finality,
            req.body.function,
            req.body.subfunction,
            req.body.institutionalactivity,
            req.body.budgetprogram,
            req.body.strategicobjective,
            req.body.requestingunit,
            req.body.specificactivity,
            req.body.spendingobject,
            req.body.spendingtype,
            req.body.budgetsource,
            req.body.region,
            req.body.portfoliokey,
            cve,
            numericCol(measure != null ? measure.approvedamount : null),
            numericCol(measure != null ? measure.modifiedamount : null),
            numericCol(measure != null ? measure.executedamount : null),
            numericCol(measure != null ? measure.committedamount : null),
            numericCol(measure != null ? measure.reservedamount : null)
        ]);
    }).then(async function (data) {
        await db_conf.edca_db.one(`update budgetbreakdown set budgetbreakdown_id = (select string_agg(cve, ',') from budgetclassifications where budgetbreakdown_id = $1), amount = (select round(sum(approved), 2) from budgetclassifications where budgetbreakdown_id = $1) where id = $1 returning id`, [req.body.budget_id]);
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid  from budgetbreakdown where id in (select budgetbreakdown_id from budgetclassifications where id = ${id}) limit 1', req.body);
        updateHisitory(cpid, req.user, Stages.planning, getHost(req));

        res.json({
            status: 'Ok',
            description: 'La clasificación del presupuesto ha sido actualizada'
        });

        console.log('Update budget classification: ', data);
    }).catch(function (error) {
        res.json({
            status: 'Error',
            description: 'Ha ocurrido un error al actualizar la clasificacion del presupuesto'
        });

        console.log('ERROR', error);
    });
});

router.post('/editbudgetclassification-fields', isAuthenticated, async function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.one("select * from budgetclassifications where id = $1", [req.body.id]),
            db_conf.edca_db.manyOrNone("select year as value, year as name from programaticstructure where year is not null group by year order by year desc")
            ]);
    }).then(async function (data) {
       
        res.render('modals/edit-budgetclassification', {
            id: req.body.id,
            classification: data[0],
            years: data[1],
            activities: await db_conf.edca_db.manyOrNone("select distinct specificactivity as value, specificactivity || ' - ' ||  specificactivity_desc as name from programaticstructure where requestingunit = $1 order by specificactivity || ' - ' ||  specificactivity_desc", [data[0].requestingunit]),
            units: await db_conf.edca_db.manyOrNone("select distinct requestingunit as value, requestingunit || ' - '  || requestingunit_desc as name from programaticstructure where year = $1 order by requestingunit || ' - '  || requestingunit_desc", [data[0].year]),
            departures: await db_conf.edca_db.manyOrNone("select distinct spendingobject as value, spendingobject || ' - ' || spendingobject_desc as name, spendingtype, budgetsource from programaticstructure where specificactivity = $1 order by spendingobject || ' - ' || spendingobject_desc", [data[0].specificactivity])
        });
    }).catch(function (error) {
        console.log(error);
    });
});

// Update publisher
router.post('/update-publisher',isAuthenticated, function (req, res) {

    db_conf.edca_db.one("update publisher set name=$2, scheme=$3, uid=$4, uri=$5 where id = $1 returning id",
        [
            req.body.id,
            req.body.name,
            req.body.scheme,
            req.body.uid,
            req.body.uri
        ]
    ).then(function (data) {
        res.json({
            status : 'Ok',
            description : 'Los datos han sido actualizados'
        }); // envía la respuesta y presentala en un modal
        console.log("Update publisher", data);
    }).catch(function (error) {
        res.json({
            status: "Error",
            description: "Ha ocurrido un error"
        });
        console.log("ERROR: ",error);
    });
});

router.post('/publisher', function (req, res) {
    db_conf.edca_db.one("select * from publisher where contractingprocess_id=$1",[req.body.localid]).then(function (data) {
        res.render('modals/publisher',{data: data});
    }).catch(function (error) {
        console.log("ERROR: ", error);
    });
});
 
//Datos PNT   
router.post('/register-dataPNT', isAuthenticated, function (req, res) {
    let query = `insert into $1~ (contractingprocess_id, fiscalYear, reportingPeriodStartDate, reportingPeriodEndDate, dataResponsibleunit, valitationDate, updateDate, notes, data_pnt)
        values ($2, $3, $4, $5, $6, $7, $8, $9, $10) returning id`;
        db_conf.edca_db.task(function (t) {
            return t.one(query, [
                'datapnt',
                req.body.contractingprocess_id,
                req.body.fiscalYear,
                dateCol(req.body.reportingPeriodStartDate),
                dateCol(req.body.reportingPeriodEndDate),
                req.body.dataResponsibleunit,
                dateCol(req.body.valitationDate),
                dateCol(req.body.updateDate),
                req.body.notes,
                true
            ]);
        }).then(function (data) {
            res.json({
                status : 'Ok',
                description : 'Los datos han sido registrados'
            });
        }).catch(function (error) {
            res.json({
                status: "Error",
                description: "Ha ocurrido un error al registrar los datos de PNT"
            });
        console.log("ERROR: ",error);
    });
});

router.post('/data-PNT', function (req, res) {
    db_conf.edca_db.oneOrNone("select * from datapnt where contractingprocess_id=$1 order by id desc limit 1", [req.body.datapnt_cp_id]).then(function (data) {
        res.render('modals/data_pnt',{
            id: data === null ? '' :data.id,
            fiscalyear: data === null ? '' :data.fiscalyear,
            reportingperiodstartdate: data === null ? '' :data.reportingperiodstartdate,
            reportingperiodenddate: data === null ? '' :data.reportingperiodenddate,
            dataresponsibleunit: data === null ? '' :data.dataresponsibleunit,
            valitationdate: data === null ? '' :data.valitationdate,
            updatedate: data === null ? '' :data.updatedate,
            notes: data === null ? '' :data.notes,
            contractingprocess_id: req.body.datapnt_cp_id});
    }).catch(function (error) {
        console.log("ERROR: ", error);
    });
});

//project publisher
router.post('/project-publisher', function (req, res) {
    project.findProject(req.body.projectId).then(value => {
        res.render('modals/project_publisher',{publisher: value[0].publisher[0]}
        );
    }).catch(function (error) {
        console.log("ERROR: ", error);
    });
});

//buscar por periodo
router.post('/search-process-by-date', function (req, res) {
    db_conf.edca_db.manyOrNone("select * from ContractingProcess where fecha_creacion >= $1 and fecha_creacion <= $2",[
        req.body.fecha_inicial,
        req.body.fecha_final
    ]
    ).then(function (data) {
        //console.log(data);
        res.render('modals/process-list',{ data: data});
    }).catch(function (error) {
        console.log("ERROR: ",error);
        res.send('ERROR');
    });
});

router.post('/search-process-by-ocid',function(req, res){
    let select = 'select c.*, t.title tender_name, t.tenderid tender_id, ' +
    "((select string_agg(name, ', ') from parties p  join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true)) requestingunit_name from contractingprocess c " +
    ' left join tender t on t.contractingprocess_id = c.id ';
    let where = [];

    if (req.body.tender_name) where.push(" lower(t.title) like lower('%' || ${tender_name} || '%')");
    if (req.body.tender_id) where.push(" lower(t.tenderid) like lower('%' || ${tender_id} || '%')");
    if (req.body.requestingunit_name) where.push(" c.id in (select p.contractingprocess_id from parties p join roles r on r.parties_id = p.id where p.contractingprocess_id = c.id and requestingunit = true and lower(name) like lower('%' || ${requestingunit_name} || '%'))");
    if (req.body.ocid) where.push(" ocid like '%' || ${ocid} || '%'");

    db_conf.edca_db.manyOrNone(select + (where.length > 0 ? ' where ' + where.join(' and ') : ''), req.body).then(function (data) {
        res.render('modals/process-list',{ data : data});
    }).catch(function (error) {
        console.log(error);
        res.send('ERROR');
    });
});


router.post('/search/', function (req, res) {
    res.render('modals/search');
});

router.get('/manual', function (req, res) {
    res.render('modals/manual');
});


//get list of transactions
router.post('/transaction-list',function (req, res) {
    db_conf.edca_db.manyOrNone('select * from implementationtransactions where implementation_id=$1',[
        req.body.fkid
    ]).then(function(data){
        console.log(data);
        res.render('modals/transaction-list', {table : req.body.table, data: data});
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });

});

//get list of organizations
router.post('/organization-list',function (req, res) {
    db_conf.edca_db.manyOrNone('select * from $1~ where contractingprocess_id=$2',[
        req.body.table,
        req.body.ocid
    ]).then(function(data){
        console.log(data);
        res.render('modals/organization-list', {table: req.body.table, data: data});
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });

});

//get list of items
router.post('/item-list',function (req, res) {

    let sql = ''
    if(req.body.fkname && req.body.fkid) {
        sql = 'select * from $1~ where contractingprocess_id=$2 and $3~ = $4';
    } else {
        sql = 'select * from $1~ where contractingprocess_id=$2';
    }


    db_conf.edca_db.manyOrNone(sql,[
        req.body.table,
        req.body.ocid,
        req.body.fkname,
        req.body.fkid
    ]).then(function(data){
        console.log(data);
        res.render('modals/item-list', {table: req.body.table, data: data});
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

//get list of documents
router.post('/document-list',function (req, res) {

    let sql = ''
    if(req.body.fkname && req.body.fkid) {
        sql = 'select * from $1~ where contractingprocess_id=$2 and $3~ = $4';
    } else {
        sql = 'select * from $1~ where contractingprocess_id=$2';
    }

    db_conf.edca_db.manyOrNone(sql, [
        req.body.table,
        req.body.ocid,
        req.body.fkname,
        req.body.fkid
    ]).then(function(data){
        console.log(data);
        res.render('modals/document-list', { data: data, table: req.body.table, stage: req.body.stage });
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

//get list of milestones
router.post('/milestone-list',function (req, res) {

    let sql = '';

    if(req.body.fkname) {
        sql = 'select * from $1~ where contractingprocess_id=$2 and $3~ = $4'
    } else {
        sql = 'select * from $1~ where contractingprocess_id=$2';
    }

    db_conf.edca_db.manyOrNone(sql,[
        req.body.table,
        req.body.ocid,
        req.body.fkname,
        req.body.fkid
    ]).then(function(data){
        console.log(data);
        res.render('modals/milestone-list', {table: req.body.table, data: data});
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

//get list of amendment changes
router.post('/amendmentchange-list',function (req, res) {

    let sql = ''
    if(req.body.fkname && req.body.fkid) {
        sql = 'select * from $1~ where contractingprocess_id=$2 and $3~ = $4';
    } else {
        sql = 'select * from $1~ where contractingprocess_id=$2';
    }

    db_conf.edca_db.manyOrNone(sql,[
        req.body.table,
        req.body.ocid,
        req.body.fkname,
        req.body.fkid
    ]).then(function(data){
        console.log(data);
        res.render('modals/amendmentchange-list', {table: req.body.table, data: data});
    }).catch(function(error){
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/quoterequest-list', function (req, res) {
    let sql = `select * from requestforquotes where contractingprocess_id = $1`;

    db_conf.edca_db.manyOrNone(sql, [
        req.body.ocid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/quoterequest-list', {
            ocid: req.body.ocid,
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/quote-list', function (req, res) {
    let sql = `select quotes.*, requestforquotes.title as requestTitle from quotes inner join requestforquotes on quotes.requestforquotes_id = requestforquotes.id where requestforquotes.contractingprocess_id = $1`;

    db_conf.edca_db.manyOrNone(sql, [
        req.body.ocid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/quote-list', {
            ocid: req.body.ocid,
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/guarantee-list', function (req, res) {
    let sql = '';
    
    if (req.body.fkname && req.body.fkid) {
        sql = `select * from $1~ where contractingprocess_id = $2 and $3~ = $4`;
    } else {
        sql = `select * from $1~ where contractingprocess_id = $2`;
    }

    db_conf.edca_db.manyOrNone(sql, [
        req.body.table,
        req.body.ocid,
        req.body.fkname,
        req.body.fkid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/guarantee-list', {
            table: req.body.table,
            ocid: req.body.ocid,
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/contactpoint-list', function (req, res) {
    let sql = `select * from $1~ where party_id = $2`;

    db_conf.edca_db.manyOrNone(sql, [
        'additionalcontactpoints',
        req.body.partyid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/contactpoint-list', {
            partyid: req.body.partyid,
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/budgetbreakdown-list', function (req, res) {
    let sql = `select * from $1~ where contractingprocess_id = $2`;

    db_conf.edca_db.manyOrNone(sql, [
        'budgetbreakdown',
        req.body.ocid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/budgetbreakdown-list', {
            ocid: req.body.ocid,
            table: 'budgetbreakdown',
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/budgetclassification-list', function (req, res) {
    let sql = `select distinct $1~.*, requestingunit_desc as unitname from $1~ inner join programaticstructure on programaticstructure.requestingunit = $1~.requestingunit where $1~.budgetbreakdown_id = $2`;

    db_conf.edca_db.manyOrNone(sql, [
        'budgetclassifications',
        req.body.budgetid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/budgetclassification-list', {
            table: 'budgetclassifications',
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.post('/relatedprocedure-list', function (req, res) {
    let sql = 'select * from $1~ where contractingprocess_id = $2';

    db_conf.edca_db.manyOrNone(sql, [
        req.body.table,
        req.body.ocid
    ]).then(function (data) {
        console.log(data);
        res.render('modals/relatedprocedure-list', {
            table: req.body.table,
            ocid: req.body.ocid,
            data: data
        });
    }).catch(function (error) {
        console.log('ERROR: ', error);
        res.send('ERROR');
    });
});

router.delete('/contractingprocess',isAuthenticated, function (req, res) {

    db_conf.edca_db.one('delete from contractingprocess cascade where id = $1 returning id, ocid',[req.body.id]).then(function (cp) {
        console.log('Successfully deleted contracting process -> ', JSON.stringify(cp));
        res.json({
            status: 'Ok',
            id: cp.id,
            ocid: cp.ocid
        })
    }).catch(function (error) {
        res.json({
            status: 'Error',
            error: error
        });
    });

});

router.post('/delete', isAuthenticated, async function (req, res) {
    var tasks = [];

    let cp;

    try{
        // intentar obtener el id de la contratacion
        cp = await db_conf.edca_db.oneOrNone('select contractingprocess_id from $1~ where id = $2 limit 1', [req.body.table,
         req.body.id]);
    }catch(e){
 
    }

    switch(req.body.table){
        case 'budgetclassifications':
            let budgetid = await db_conf.edca_db.oneOrNone('select budgetbreakdown_id as id from budgetclassifications where id = $1 limit 1', [req.body.id]);
            if(budgetid){
                await db_conf.edca_db.one(`update budgetbreakdown set budgetbreakdown_id = (select string_agg(cve, ',') from budgetclassifications where budgetbreakdown_id = $1 and id != $2), 
                amount = (select round(sum(approved), 2) from budgetclassifications where budgetbreakdown_id = $1 and id != $2) 
                where id = $1 returning id`, [budgetid.id, req.body.id]);
            }
            
        break;
    }

    tasks.push(db_conf.edca_db.result('delete from $1~ where id = $2', [
        req.body.table,
        req.body.id
    ]));

  


    if (req.body.dependencies != null && req.body.dependencies != '' && req.body.dkey != null && req.body.dkey != '') {
        req.body.dependencies.split(';').forEach(function (v, i) {
            tasks.push(db_conf.edca_db.result('delete from $1~ where $2~ = $3', [
                v,
                req.body.dkey,
                req.body.id
            ]));
        });
    }

    db_conf.edca_db.task(function (t) {
        return this.batch(tasks);
    }).then(async function (data) {

        if(cp){
            updateHisitory(cp.contractingprocess_id, req.user, Stages.planning,getHost(req));
        }

        res.json({
            msg: "Registros eliminados: " + data[0].rowCount,
            status : 0
        });
    }).catch(function (error) {
        res.json({
            msg: 'ERROR',
            status: 1
        });
        console.log('ERROR',error);
    });
});

router.post('/search-item', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select * from item where $1~ like '%' || $2 || '%' order by $1~ limit 7", [req.body.prop, req.body.search])
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});

router.post('/search-contractingprocess', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select *, concat($2, '/record-package/', ocid) as record from contractingprocess as a join tender b on a.id = b.contractingprocess_id  where ocid like '%' || $1 || '%' order by ocid limit 7", [req.body.search, getHost(req)])
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});

router.post('/search-projects',async function (req, res) {

    await db.edcapi_project_package.findAll({
        include:[
            {
                model: db.edcapi_project, 
                as: 'projects', 
                attributes: { exclude: ['createdAt','updatedAt']},
                through: {attributes: []},
                where: {
                    oc4idsIdentifier: {
                        //[Op.like]: Sequelize.literal('\'%'+req.body.search+'%\'')
                        [Op.substring]: req.body.search
                    }
                }
                //where: {[Op.substring]: req.body.search}
            },
            {
                model: db.edcapi_publisher,
                as: 'publisher', 
                attributes: { exclude: ['createdAt','updatedAt']},
                through: {attributes: []}
            }
        ],
        order: [['id', 'ASC']],
        attributes: { exclude: ['createdAt','updatedAt']},
        limit: 7
    }).then(async function (data) {
        console.log("#### DATA " + JSON.stringify(data,null,2))
        res.status(200).json(data)
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});

router.post('/search-programaticstructure', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.oneOrNone("select * from programaticstructure where year = $1 and requestingunit = $2 limit 1", [req.body.year, req.body.requiredunit])
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json(null);
        console.log(error);
    });
});

router.post('/search-requestingunit', function (req, res) {
    db_conf.edca_db.task(function (t) {
        return t.batch([
            t.manyOrNone("select distinct requestingunit as value, requestingunit || ' - '|| requestingunit_desc as name from programaticstructure where year = $1 order by  requestingunit || ' - '|| requestingunit_desc", [req.body.year])
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});

router.post('/search-activitymir', function (req, res) {
    db_conf.edca_db.task(function (t) {
        let params = {
            ue: req.body.ue || '',
            mir: req.body.mir || '',
            year: req.body.year
        }
        return t.batch([
            t.manyOrNone("select distinct specificactivity as value, specificactivity || ' - ' || specificactivity_desc as name from programaticstructure where year = ${year} and requestingunit = ${ue} order by specificactivity || ' - ' || specificactivity_desc", params)
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});

router.post('/search-departure', function (req, res) {
    db_conf.edca_db.task(function (t) {
        let params = {
            ue: req.body.ue || '',
            mir: req.body.mir || '',
            year: req.body.year
        }
        return t.batch([
            t.manyOrNone("select spendingobject as value, spendingobject || ' - ' || spendingobject_desc as name, spendingtype, budgetsource from programaticstructure where year = ${year} and requestingunit = ${ue} and specificactivity = ${mir} order by spendingobject || ' - ' || spendingobject_desc", params)
        ]);
    }).then(function (data) {
        res.json(data[0]);
    }).catch(function (error) {
        res.json([]);
        console.log(error);
    });
});


var multer = require('multer');
var upload = multer({ dest: path.join(__dirname, './uploads')});

//Converter Class
var Converterv1 = require("csvtojson/v1").Converter;

router.post('/upload-stage', isAuthenticated, upload.single('datafile'), function (req, res) {

    console.log("Uploaded file: ", req.file);
    var converter = new Converterv1({});
    require('fs').createReadStream(req.file.path).pipe(converter);

    converter.on("error",function(errMsg,errData){
        //do error handling here
        console.log('Error: ', errMsg);
        console.log('Data: ', errData);
    });

    //end_parsed will be emitted once parsing finished
    converter.on("end_parsed", function (jsonArray) {

        if (req.body.stage === 'planning'){

            db_conf.edca_db.tx (function (t) {

                return t.one('update planning set rationale = $2 where contractingprocess_id = $1 returning id as planning_id',
                    [
                        req.body.localid,
                        jsonArray[0].FUNDAMENTO
                    ]).then(function (data) {
                    var budget = t.one('update budget set budget_source = $2, budget_budgetid = $3, budget_description = $4, budget_amount = $5, budget_currency = $6, budget_project = $7, budget_projectid = $8,' +
                        'budget_uri = $9 where contractingprocess_id = $1 returning id as budget_id',
                        [
                            req.body.localid,
                            jsonArray[0].FUENTE_PRESUPUESTARIA,
                            jsonArray[0].IDENTIFICADOR_PRESUPUESTO,
                            jsonArray[0].DESCRIPCION_PRESUPUESTO,
                            Number(jsonArray[0].MONTO_ASIGNADO),
                            jsonArray[0].MONEDA,
                            jsonArray[0].PROYECTO_PRESUPUESTARIO,
                            jsonArray[0].IDENTIFICADOR_PROYECTO_PRESUPUESTARIO,
                            jsonArray[0].URI_PRESUPUESTO

                        ]);

                    return t.batch([data , budget]);
                });


            }).then(async function (data) {
                console.log('PLanning stage loaded: ', data);
                updateHisitory(req.body.localid, req.user, Stages.planning, getHost(req));
                res.redirect(`/main/${req.body.localid}`);
            }).catch(function (error) {
                console.log('ERROR: ',error);
                res.redirect(`/main/${req.body.localid}`);
            });

        } else if (req.body.stage === 'tender'){

            db_conf.edca_db.one('update tender set tenderid =$2, title = $3, description  = $4, status = $5,  minvalue_amount = $6, minvalue_currency= $7, value_amount = $8, value_currency = $9, ' +
                'procurementmethod = $10, procurementmethod_rationale= $11, awardcriteria = $12, awardcriteria_details = $13, submissionmethod = $14, submissionmethod_details = $15, ' +
                'tenderperiod_startdate = $16 , enquiryperiod_startdate = $17, enquiryperiod_enddate = $18, hasenquiries = $19, ' +
                'eligibilitycriteria = $20, awardperiod_startdate = $21, numberoftenderers = $22' +
                ' where contractingprocess_id = $1 returning id as tender_id',
                [
                    req.body.localid,
                    jsonArray[0].IDENTIFICADOR_LICITACION,
                    jsonArray[0].TITULO_LICITACION,
                    jsonArray[0].DESCRIPCION_LICITACION,
                    'active', //jsonArray[0].ESTATUS_LICITACION
                    Number(jsonArray[0].VALOR_MINIMO),
                    jsonArray[0].MONEDA_VALOR_MINIMO,
                    Number(jsonArray[0].VALOR),
                    jsonArray[0].MONEDA_VALOR,

                    jsonArray[0].METODO_ADQUISICION,
                    jsonArray[0].JUSTIFICACION_METODO,
                    jsonArray[0].CRITERIO_ADJUDICACION,
                    jsonArray[0].DETALLES_CRITERIO_ADJUDICACION,
                    jsonArray[0].METODO_RECEPCION,
                    jsonArray[0].DETALLES_METODO_RECEPCION,
					
                    jsonArray[0].PERIODO_RECEPCION_PROPUESTAS,
                    jsonArray[0].FECHA_INICIO_ACLARACIONES,
                    jsonArray[0].FECHA_CIERRE_ACLARACIONES,
                    (jsonArray[0].TUVO_ACLARACIONES==="true")?true:false,

                    jsonArray[0].CRITERIOS_ELEGIBILIDAD,
                    jsonArray[0].PERIODO_ADJUDICACION,
                    Number (jsonArray[0].NUMERO_PARTICIPANTES)
                ]).then(async function (data) {
                    updateHisitory(req.body.localid, req.user, Stages.tender, getHost(req));
                console.log('Tender stage loaded: ', data);
                res.redirect('/main/'+ req.body.localid);
            }).catch(function (error) {
                console.log("ERROR: ", error);
                res.redirect('/main/'+ req.body.localid);
            });

        } else if (req.body.stage === 'award') {

          db_conf.edca_db.one('update award set awardid = $2, title = $3, description = $4, status = $5, award_date = $6, value_amountnet = $7, value_amount = $8, value_currency = $9 where contractingprocess_id = $1  and id = $10 returning id as award_id',
                [
                    req.body.localid,
                    jsonArray[0].IDENTIFICADOR_ADJUDICACION,
                    jsonArray[0].TITULO_ADJUDICACION,
                    jsonArray[0].DESCRIPCION_ADJUDICACION,
                    'active',//jsonArray[0].ESTATUS,
                    jsonArray[0].FECHA_ADJUDICACION || null,
                    Number(jsonArray[0].VALOR_ADJUDICACION_SINIVA),
                    Number(jsonArray[0].VALOR_ADJUDICACION),
                    jsonArray[0].MONEDA_ADJUDICACION,
                    req.body.id
                ]).then(async function (data) {
                console.log('Award stage loaded: ', data);
                updateHisitory(req.body.localid, req.user, Stages.award, getHost(req));
                res.redirect('/main/'+ req.body.localid);
            }).catch(function (error) {
                console.log("ERROR: ", error);
                res.redirect('/main/'+ req.body.localid);
            });

        } else if (req.body.stage === 'contract'){

            db_conf.edca_db.one('update contract set awardid =$2, contractid = $3 ,title = $4, description=$5, status = $6, period_startdate=$7, period_enddate=$8, value_amountnet=$9, value_amount=$10,' +
                ' datesigned=$11, exchangerate_rate=$12, exchangerate_amount=$13, exchangerate_currency=$14, exchangerate_date=$15, exchangerate_source=$16 where id = $1 returning id as contract_id',
                [
                    req.body.localid,
                    jsonArray[0].IDENTIFICADOR_ADJUDICACION,
                    jsonArray[0].IDENTIFICADOR_CONTRATO,
                    jsonArray[0].TITULO_CONTRATO,
                    jsonArray[0].DESCRIPCION_CONTRATO,
                    'active',//jsonArray[0].ESTATUS,
                    jsonArray[0].PERIODO_CONTRATO_INICIO,
                    jsonArray[0].PERIODO_CONTRATO_FINAL,
                    Number(jsonArray[0].VALOR_CONTRATO_SINIVA),
                    Number(jsonArray[0].VALOR_CONTRATO),                    
                    jsonArray[0].FECHA_FIRMA_CONTRATO,
                     Number(jsonArray[0].TIPO_CAMBIO),
					 Number(jsonArray[0].VALOR_CAMBIO),
					 jsonArray[0].MONEDA_TIPO_CAMBIO,
					 jsonArray[0].FECHA_TIPO_CAMBIO,
					 jsonArray[0].SOURCE
                ]).then(async function (data) {
                    updateHisitory(req.body.localid, req.user, Stages.contract, getHost(req));
                console.log('Contract stage loaded: ', data);
                res.redirect('/main/'+ req.body.localid);
            }).catch(function (error) {
                console.log("ERROR: ", error);
                res.redirect('/main/'+ req.body.localid);
            });
        }

        require('fs').unlinkSync(req.file.path);
    });
});

router.post('/uploadfile-fields', function (req,res) {
    res.render('modals/uploadfile-fields', { localid: req.body.localid, stage: req.body.stage, id: req.body.id });
});


// partial list selector implementations
router.get('/implementation-list/:cpid', isAuthenticated, async (req, res) => {
    const status = [
        {text: 'En planeación', code: 'planning'},
        {text: 'En progreso', code: 'ongoing'},
        {text: 'Terminado', code: 'concluded'},
    ];
    let implementations = await db_conf.edca_db.manyOrNone('select id, status, contract_id from implementation where  contractingprocess_id = ${cpid} order by id', req.params);
    for(let i = 0, x = implementations[i]; i < implementations.length; i++, x = implementations[i]){
        const i = status.findIndex(y => y.code == x.status);
        if(i !== -1){
            x.status = status[i].text;
        }
        const {contractid} = await db_conf.edca_db.oneOrNone('select contractid from contract where id = ${contract_id}', x);
        x.contractid = contractid;
    }
    const {current} = await db_conf.edca_db.oneOrNone('select id as current from implementation where contractingprocess_id = ${cpid} order by datelastupdate desc limit 1', req.params);

    return res.render('partials/implementations-list-selector', {
        implementations: implementations,
        cpid:  req.params.cpid,
        current: current
    });
});


// partial view implementation
router.get('/implementation/:cpid/:id?', isAuthenticated, async (req, res) => {
    try{
    const status = await db_conf.edca_db.manyOrNone('select* from implementationstatus')

    res.render('partials/implementation', {
        implementation: await db_conf.edca_db.oneOrNone('select i.* from implementation i where i.contractingprocess_id = ${cpid} and i.id = ${id}', req.params),
        cpid: req.params.cpid,
        status: status
    });
    }catch(e){
        console.log(e);
        res.send('');
    }
});



// update implementation
router.post('/update-implementation', async function (req,res) {
    var register = await db_conf.edca_db.oneOrNone('select id from implementation where contractingProcess_id = $1 and status is not null limit 1', [req.body.contractingprocess_id]) != null;

    db_conf.edca_db.tx(function (t) {
        return t.batch([
            t.one('update implementation set status=$1, datelastupdate = now() where id=$2 returning id',[
                req.body.status !== "None"?req.body.status:null,
                req.body.id
            ]),
            updateTags(req.body)
        ]);
    }).then(async function (data) {

        updateHisitory(req.body.contractingprocess_id, req.user, Stages.implementation, getHost(req));
        console.log(data[0]);
        res.json({message: "La etapa de implementación ha sido actualizada"});
    }).catch(function (error) {
        console.log(error);
        res.status(400).json({message: 'Ocurrió un error al actualizar la etapa de implementación'})
    })
});


/* *
 *  OCDS 1.1
 *  */

router.post('/1.1/add_party.html', function (req, res)  {
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select * from language")
        ])
    }).then(function (data) {
        res.render('modals/add_party.ejs', { 
            contractingprocess_id: req.body.contractingprocess_id,
            languages: data[0]
        });
    }).catch(function (error) {
        console.log(error);
        res.send("<b>Error</b>");
    });
});

//Add Party Project
router.post('/1.1/add_party_project.html', function (req, res)  {
    res.render('modals/add_party_project.ejs', { 
        project_id: req.body.project_id,
    });
});
//Add Budget Breakdown Project
router.post('/1.1/add_budget_breakdown_project.html',async function (req, res)  {
    var currency = await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency");
    project.findPartyFunder(req.body.project_id).then(value =>{
        console.log("/1.1/add_budget_breakdown_project.html " + JSON.stringify(value))
        res.render('modals/add_budget_breakdown_project.ejs', { 
            project_id: req.body.project_id,
            currencies: currency,
            parties : value
        });
    });
});

router.post('/1.1/parties.html', function (req, res) {
   let contractingprocess_id = req.body.contractingprocess_id;
   db_conf.edca_db.manyOrNone("select * from parties where contractingprocess_id = $1", [contractingprocess_id]).then(function (parties) {
    db_conf.edca_db.task(function () {
        return this.batch(
            parties.map(function (party) {
                return db_conf.edca_db.oneOrNone("select * from roles where parties_id = $1", [party.id]);
            })
        );
    }).then(function (roles) {
        parties.forEach(function (party, index) {
            var rol = roles[index];
            party.roles = [];

            if(rol){
                if (rol.buyer) party.roles.push('Entidad compradora');
                if (rol.procuringentity) party.roles.push('Entidad contratante');
                if (rol.supplier) party.roles.push('Proveedor o contratista');
                if (rol.tenderer) party.roles.push('Licitante');
                if (rol.guarantor) party.roles.push('Institución que expide la garantía');
                if (rol.enquirer) party.roles.push('Persona física o moral que solicita aclaraciones');
                if (rol.payer) party.roles.push('Emisor del pago');
                if (rol.payee) party.roles.push('Receptor de pago');
                if (rol.reviewbody) party.roles.push('Auditor');
                if (rol.attendee) party.roles.push('Asistente a junta de aclaraciones');
                if (rol.official) party.roles.push('Servidor público asistente a junta de aclaraciones');
                if (rol.invitedsupplier) party.roles.push('Persona física o moral invitada a cotizar (investigación de mercado)');
                if (rol.issuingsupplier) party.roles.push('Persona física o moral que envía cotización (investigación de mercado)');
                if (rol.requestingunit) party.roles.push('Área requirente');
                if (rol.contractingunit) party.roles.push('Área contratante');
                if (rol.technicalunit) party.roles.push('Área técnica');
                if (rol.responsibleunit) party.roles.push('Área responsable de la ejecución');
            }
        });
        console.log("··· PARTIES " + JSON.stringify(parties))
        res.render('modals/parties.ejs', { parties: parties });
    });
   });
});
//parties project
router.post('/1.1/parties_project.html', function (req, res) {
    let project_id = req.body.project_id;
    var arrayParties = new Array();
    console.log("#### project_id " + project_id)
    project.findProject(project_id).then(value => {
        value[0].projects[0].parties.forEach(element => {
            //Roles
            var arrayRoles = new Array();
            if(element.roles[0].buyer !== "" && element.roles[0].buyer !== null)
            arrayRoles.push("Área requirente")
            if(element.roles[0].reviewBody !== "" && element.roles[0].reviewBody !== null)
            arrayRoles.push("Auditor")
            if(element.roles[0].publicAuthority !== "" && element.roles[0].publicAuthority !== null)
            arrayRoles.push("Autoridad pública")
            if(element.roles[0].payer !== "" && element.roles[0].payer !== null)
            arrayRoles.push("Emisor de pago")
            if(element.roles[0].procuringEntity !== "" && element.roles[0].procuringEntity !== null)
            arrayRoles.push("Entidad contratante")
            if(element.roles[0].funder !== "" && element.roles[0].funder !== null)
            arrayRoles.push("Financiador")
            if(element.roles[0].tenderer !== "" && element.roles[0].tenderer !== null)
            arrayRoles.push("Licitante")
            if(element.roles[0].enquirer !== "" && element.roles[0].enquirer !== null)
            arrayRoles.push("Persona física o moral que solicita aclaraciones")
            if(element.roles[0].supplier !== "" && element.roles[0].supplier !== null)
            arrayRoles.push("Proveedor o contratista")
            if(element.roles[0].payee !== "" && element.roles[0].payee !== null)
            arrayRoles.push("Receptor de pago")
            //Party
            var objParty = new Object();
            objParty.name = element.name;
            objParty.identifier = element.identifier;
            objParty.id = element.id;
            objParty.roles = arrayRoles;
            arrayParties.push(objParty);
        });
        console.log("#### arrayParties " + JSON.stringify(arrayParties))
        res.render('modals/parties_project.ejs', { parties: arrayParties});
    });
 });
 //parties project
router.post('/1.1/budget_breakdown_project_list.html', function (req, res) {
    console.log("#### project_id " + req.body.project_id)
    let project_id = req.body.project_id;
    var budgetbreakdowns = new Array();
    
    project.findProject(project_id).then(value => {
        value[0].projects[0].budget[0].budgetBreakdown.forEach(element => {
            var objBudgetBreakdown = new Object();
            objBudgetBreakdown.id = element.id;
            objBudgetBreakdown.name = element.sourceParty[0].name;
            objBudgetBreakdown.description = element.description;
            objBudgetBreakdown.amount = element.amount;
            objBudgetBreakdown.currency = element.currency;
            budgetbreakdowns.push(objBudgetBreakdown);
        });
        console.log("#### budgetbreakdowns " + JSON.stringify(budgetbreakdowns))
        res.render('modals/budget_breakdown_project_list.ejs', { budgetbreakdowns: budgetbreakdowns});
    });
 });
 //additional classifications
router.post('/1.1/additional_classifications_list_project.html', function (req, res) {
    let project_id = req.body.project_id;
    var arrayAdditionalClassifications = new Array();
    console.log("#### project_id " + project_id)
    project.findProject(project_id).then(value => {
        value[0].projects[0].additionalClassifications.forEach(element => {
            var objAdditionalClassification = new Object();
            objAdditionalClassification.id = element.id;
            objAdditionalClassification.schema = element.schema;
            objAdditionalClassification.identifier = element.identifier;
            objAdditionalClassification.description = element.description;
            arrayAdditionalClassifications.push(objAdditionalClassification);
        });
        console.log("#### arrayAdditionalClassifications " + JSON.stringify(arrayAdditionalClassifications))
        res.render('modals/additional_classifications_list.ejs', { data: arrayAdditionalClassifications});
    });
 });
 //locations project
router.post('/1.1/locations_project.html', function (req, res) {
    let project_id = req.body.project_id;
    var arrayLocationsProject = new Array();
    console.log("#### project_id " + project_id)
    project.findProject(project_id).then(value => {
        value[0].projects[0].locations.forEach(element => {
            var objLocationProject = new Object();
            objLocationProject.id = element.id;
            objLocationProject.description = element.description;
            objLocationProject.type = element.type;
            arrayLocationsProject.push(objLocationProject);
        });
        console.log("#### arrayLocationsProject " + JSON.stringify(arrayLocationsProject))
        res.render('modals/locations_project_list.ejs', { data: arrayLocationsProject});
    });
 });
 //documents project
router.post('/1.1/documents_project.html', function (req, res) {
    let project_id = req.body.project_id;
    var arrayDocumentsProject = new Array();
    console.log("#### project_id " + project_id)
    project.findProject(project_id).then(value => {
        value[0].projects[0].documents.forEach(element => {
            var objDocumentProject = new Object();
            objDocumentProject.id = element.id;
            objDocumentProject.documentType = element.documentType;
            objDocumentProject.title = element.title;
            objDocumentProject.description = element.description;
            objDocumentProject.url = element.url;
            objDocumentProject.datePublished = element.datePublished;
            objDocumentProject.dateModified = element.dateModified;
            objDocumentProject.format = element.format;            
            objDocumentProject.language = element.language;
            objDocumentProject.pageStart = element.pageStart;
            objDocumentProject.pageEnd = element.pageEnd;
            objDocumentProject.accessDetails = element.accessDetails;
            objDocumentProject.author = element.author;
            arrayDocumentsProject.push(objDocumentProject);
        });
        console.log("#### arrayDocumentsProject " + JSON.stringify(arrayDocumentsProject))
        res.render('modals/documents_project_list.ejs', { data: arrayDocumentsProject});
    });
 });
 //Related projects
router.post('/1.1/related_projects.html', function (req, res) {
    let project_id = req.body.project_id;
    var arrayRelatedProjects = new Array();
    console.log("#### project_id " + project_id)
    project.findProject(project_id).then(value => {
        console.log(`value ${JSON.stringify(value,null,2)}`)
        value[0].projects[0].relatedProjects.forEach(element => {
            var objRelatedProjects = new Object();
            if(element.relationship !== "" && element.relationship !== null){
                if(element.relationship === "construction")
                objRelatedProjects.relationship = "Proyecto de construccion";
                if(element.relationship === "rehabilitation")
                objRelatedProjects.relationship = "Proyecto de rehabilitación";
                if(element.relationship === "replacement")
                objRelatedProjects.relationship = "Proyecto de reemplazo";
                if(element.relationship === "expansion")
                objRelatedProjects.relationship = "Proyecto de expansión";
            }
            if(element.title !== "" && element.title !== null)
            objRelatedProjects.title = element.title;
            if(element.identifier !== "" && element.identifier !== null)
            objRelatedProjects.identifier = element.identifier;
            objRelatedProjects.id = element.id;
            arrayRelatedProjects.push(objRelatedProjects);
        });
        console.log("#### arrayRelatedProjects " + JSON.stringify(arrayRelatedProjects))
        res.render('modals/related_projects_list.ejs', { relatedProjects: arrayRelatedProjects});
    });
 });

//get parties
router.get('/1.1/parties', function (req, res) {

    //all parties
    if ( !isNaN(req.query.contractingprocess_id) && isNaN(req.query.party_id) ) {
        db_conf.edca_db.one('select * from parties where contractingprocess_id = $1', [
            req.body.contractingprocess_id
        ]).then(function (parties) {
            //get party roles
            res.jsonp({
                status :'Ok',
                data: parties
            });
        }).catch(function (error) {
            console.log(error);
            res.status(400).jsonp({
                status: 'Error',
                error: error
            });
        });
    } else if(!isNaN(req.query.contractingprocess_id) && !isNaN(req.query.party_id)){
        db_conf.edca_db.one('select * from parties where contractingprocess_id = $1 and id = $2', [
            req.body.contractingprocess_id, req.body.party_id
        ]).then(function (party) {
            //get party roles
            res.jsonp({
                status :'Ok',
                data: party
            });
        }).catch(function (error) {
            console.log(error);
            res.status(400).jsonp({
                status: 'Error',
                error: error
            });
        });

    } else {
        //error
        res.status(400).jsonp({
            status: 'Error',
            message: 'Parámetros incorrectos'
        })
    }
});

let getNumberOfTenderes = async (cpid) => {
    return (await db_conf.edca_db.one('select count(*) from roles where contractingprocess_id = $1 and tenderer = true', [cpid])).count;
}

// new party
router.put('/1.1/party/', function (req,res) {
    //falta verificar que la organización no exista

    //regresar error si no se ha seleccionado al menos un rol
    if (!isChecked(req.body.buyer) &&
        !isChecked(req.body.procuringEntity) &&
        !isChecked(req.body.supplier) &&
        !isChecked(req.body.tenderer) &&
        !isChecked(req.body.guarantor) &&
        !isChecked(req.body.enquirer) &&
        !isChecked(req.body.payer) &&
        !isChecked(req.body.payee) &&
        !isChecked(req.body.reviewBody) &&
        !isChecked(req.body.attendee) &&
        !isChecked(req.body.official) &&
        !isChecked(req.body.invitedSupplier) &&
        !isChecked(req.body.issuingSupplier) &&
        !isChecked(req.body.requestingunit) &&
        !isChecked(req.body.responsibleunit) &&
        !isChecked(req.body.contractingunit) &&
        !isChecked(req.body.technicalunit) &&
        !isChecked(req.body.responsibleunit)){
        res.json({
            status: 'Error',
            description: 'Debes seleccionar al menos un rol'
        });
    } else {

        db_conf.edca_db.one('insert into parties (contractingprocess_id, name, partyid, naturalperson, position, identifier_scheme, ' +
            ' identifier_id, identifier_legalname, identifier_uri, address_streetaddress, address_locality, ' +
            ' address_region, address_postalcode, address_countryname, contactpoint_name, contactpoint_email, ' +
            ' contactpoint_telephone, contactpoint_faxnumber, contactpoint_url, surname, additionalsurname, contactpoint_surname, contactpoint_additionalsurname,' +
            ' givenname, contactpoint_givenname, contactpoint_type, contactpoint_language) values' +
            ' ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27) returning id', [
            req.body.contractingprocess_id,
            req.body.name, // name
            req.body.partyid,
            req.body.naturalperson === "true",
            req.body.position,
            req.body.identifier_scheme,
            req.body.identifier_id,
            req.body.identifier_legalname,
            req.body.identifier_uri,
            req.body.address_streetaddress,
            req.body.address_locality,
            req.body.address_region,
            req.body.address_postalcode,
            req.body.address_countryname,
            `${req.body.contactpoint_givenname} ${req.body.contactpoint_surname} ${req.body.contactpoint_additionalsurname}`.trim(), // contactpoint name
            req.body.contactpoint_email,
            req.body.contactpoint_telephone,
            req.body.contactpoint_faxnumber,
            req.body.contactpoint_url,
            req.body.surname,
            req.body.additionalsurname,
            req.body.contactpoint_surname,
            req.body.contactpoint_additionalsurname,
            req.body.givenname,
            req.body.contactpoint_givenname,
            req.body.contactpoint_type,
            req.body.contactpoint_language && typeof req.body.contactpoint_language !== 'string' ? req.body.contactpoint_language.join(','): req.body.contactpoint_language,
        ]).then(async function (party) {

            const result = await db_conf.edca_db.one('insert into roles(id, contractingprocess_id, parties_id, ' +
                'buyer, procuringentity, supplier, tenderer, guarantor, enquirer,' +
                'payer, payee, reviewbody, attendee, official, invitedSupplier, ' +
                'issuingSupplier,requestingunit,contractingunit,technicalunit,responsibleunit) values (default,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19) returning id, parties_id', [
                req.body.contractingprocess_id,
                party.id,
                isChecked(req.body.buyer),
                isChecked(req.body.procuringEntity),
                isChecked(req.body.supplier),
                isChecked(req.body.tenderer),
                isChecked(req.body.guarantor),
                isChecked(req.body.enquirer),
                isChecked(req.body.payer),
                isChecked(req.body.payee),
                isChecked(req.body.reviewBody),
                isChecked(req.body.attendee),
                isChecked(req.body.official),
                isChecked(req.body.invitedSupplier),
                isChecked(req.body.issuingSupplier),
                isChecked(req.body.requestingunit),
                isChecked(req.body.contractingunit),
                isChecked(req.body.technicalunit),
                isChecked(req.body.responsibleunit)
            ]);

            result.total = await getNumberOfTenderes(req.body.contractingprocess_id);

            // actualizar numero de tenders 
            if (req.body.tenderer) {
                await db_conf.edca_db.none('update tender set numberoftenderers = $2 '+
                'where contractingprocess_id = $1 ', [req.body.contractingprocess_id, result.total]);;
            }
            
            return result;

        }).then(async function (data) {

            updateHisitory(req.body.contractingprocess_id, req.user, Stages.planning, getHost(req));

            res.jsonp({
                status: 'Ok',
                description: "Parte registrada",
                data: data
            });
        }).catch(function (error) {
            console.log(error);
            res.status(400).jsonp({
                status: 'Error',
                error: error
            });
        });
    }

});

// new party project
router.put('/1.1/party_project/', function (req,res) {
    console.log("######### /1.1/party_project/ BODY " + JSON.stringify(req.body, null, 4))
    //regresar error si no se ha seleccionado al menos un rol
    if (!isChecked(req.body.buyer) &&
        !isChecked(req.body.reviewBody) &&
        !isChecked(req.body.publicAuthority) &&
        !isChecked(req.body.payer) &&
        !isChecked(req.body.procuringEntity) &&
        !isChecked(req.body.funder) &&
        !isChecked(req.body.tenderer) &&
        !isChecked(req.body.enquirer) &&
        !isChecked(req.body.supplier) &&
        !isChecked(req.body.payee)){
        res.json({
            status: 'Error',
            description: 'Debes seleccionar al menos un rol'
        });
    } 
    else {
        project.insertParties(JSON.stringify(req.body)).then(function(){
            res.jsonp({
                status: 'Ok',
                description: "Parte registrada"
            });
            return true;
        }).then(function(){
            project.updatePublishedDate(req.body.project_id,req.user);
        }).catch(function(err){console.log("ERROR - /1.1/party_project/ " + err)});
    }

});

// add budget breakdown project
router.put('/1.1/add_budget_breakdown_project/', function (req,res) {
    console.log("######### /1.1/add_budget_breakdown_project/ BODY " + JSON.stringify(req.body, null, 4))
    project.findProject(req.body.project_id).then(value => {
        if(value[0].projects[0].budget.length > 0 && value[0].projects[0].budget.length !== undefined && value[0].projects[0].budget[0].amount[0].amount !== null){
            var budgetId = value[0].projects[0].budget[0].amount[0].id;
            project.insertBudgetBreakdown(JSON.stringify(req.body),budgetId).then(function(){
                res.jsonp({
                    status: 'Ok',
                    description: "Desglose registrado"
                });
                return true;
            }).then(function(){
                project.updatePublishedDate(req.body.project_id,req.user);
            }).catch(function(err){console.log("ERROR - /1.1/add_budget_breakdown_project/ " + err)});
        }else{
            res.json({
                status: 'Error',
                description: 'Debe registrar la información solicitada en la sección Valor total del proyecto antes de realizar un registro en el formulario de Desglose del presupuesto.'
            });
        }
    })
});

router.post('/1.1/edit_party.html', function (req, res){
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one('select * from parties where id = $1',[req.body.parties_id ]),
            this.oneOrNone('select * from roles where parties_id = $1', [req.body.parties_id ]),
            this.manyOrNone("select * from language")
        ])
    }).then(function (data) {
        res.render('modals/edit_party',{
            data: data[0],
            roles: data[1] || [],
            languages: data[2]
        });
    }).catch(function (error) {
        console.log(error);
        res.send("<b>Error</b>");
    });
});
// Edit additional identifier
router.post('/1.1/edit_additional_identifier.html', function (req, res){
    console.log("######### /1.1/edit_additional_identifier.html BODY " + JSON.stringify(req.body, null, 4))
    project.findAdditionalIdentifier(req.body.identifier_id).then(value => {
        console.log("#### findAdditionalIdentifier: " + JSON.stringify(value[0]))
        res.render('modals/edit_additional_identifiers',{
            data: value[0]
        });
    });
});
// Edit budget line project
router.post('/1.1/edit_budget_line.html', function (req, res){
    console.log("######### /1.1/edit_budget_line.html BODY " + JSON.stringify(req.body, null, 4))
    project.findBudgetLineComponent(req.body.budget_line_component_id).then(value => {
        console.log("#### findBudgetLineComponent: " + JSON.stringify(value))
        res.render('modals/edit_budget_line',{
            data: value
        });
    });
});
// Edit budget line project
router.post('/1.1/edit_budget_line_measure.html',async function (req, res){
    console.log("######### /1.1/edit_budget_line_measure.html BODY " + JSON.stringify(req.body, null, 4))
    var currency = await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency");
    var budget_types = await db.edcapi_cat_budget_moment_type.findAll({ attributes: ['code','title']});
    project.findMeasure(req.body.budgetLineMeasureId).then(value => {
        console.log("#### findMeasure: " + JSON.stringify(value, null, 4))
        res.render('modals/edit_budget_line_measure',{
            data: value,
            currencies: currency,
            budgetTypes: budget_types
        });
    });
});
// Edit party project
router.post('/1.1/edit_party_project.html', function (req, res){
    console.log("######### /1.1/edit_party_project.html BODY " + JSON.stringify(req.body, null, 4))
    project.findParty(req.body.parties_id).then(value => {
        console.log("#### findParty: " + JSON.stringify(value[0]))
        res.render('modals/edit_party_project',{
            data: value[0]
        });
    });
});
// Edit budgetBreakdown project
router.post('/1.1/edit_budgetBreakdown_project.html',async function (req, res){
    console.log("######### /1.1/edit_budgetBreakdown_project.html BODY " + JSON.stringify(req.body, null, 4))
    project.findBudgetBreakdown(req.body.budgetbreakdown_id).then(async value => {
        return value[0];
    }).then(async function(data){
        project.findPartyFunder(data.sourceParty[0].project_id).then(async value =>{
            var currency = await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency");
            res.render('modals/edit_budget_breakdown_project',{
                data: data,
                currencies : currency,
                parties : value
            });    
        })
    });
});
// Edit additional classification
router.post('/1.1/edit_additional_classification.html', function (req, res){
    console.log("######### /1.1/edit_additional_classification.html BODY " + JSON.stringify(req.body, null, 4))
    project.findAdditionalClassification(req.body.classification_id).then(value => {
        console.log("#### findAdditionalClassification: " + JSON.stringify(value))
        res.render('modals/edit_additional_classification',{
            data: value
        });
    });
});
// Edit location project
router.post('/1.1/edit_location_project.html', async function (req, res){
    console.log("######### /1.1/edit_location_project.html BODY " + JSON.stringify(req.body, null, 4))
    var geometry_type = await db.edcapi_cat_geometry_type.findAll({ order: [['title', 'ASC']],attributes: ['code','title']}).then(async function (geometry_type) {
        project.findLocationProject(req.body.location_id).then(value => {
            console.log("#### findLocationProject: " + JSON.stringify(value))
            res.render('modals/edit_location_project',{
                location_id: req.body.location_id,
                geometryTypes: geometry_type,
                data: value
            });
        });
    }).catch(function (error) {
        console.log(error);
    });
});
// Edit document project
router.post('/1.1/edit_document_project.html', function (req, res){
    console.log("######### /1.1/edit_document_project.html BODY " + JSON.stringify(req.body, null, 4))
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.manyOrNone("select * from language")
        ]);
    }).then(async function(idiomas){
        var document_type = await db.edcapi_cat_document_type.findAll({  order: [['title', 'ASC']],attributes: ['code','title']});
        project.findDocumentProject(req.body.document_id).then(value => {
            console.log("#### findDocumentProject: " + JSON.stringify(value))
            res.render('modals/edit_document_project',{
                languages: idiomas[0], 
                documentTypes: document_type,
                data: value
            });
        });
    })
    .catch(function (error) {
        console.log(error);
    });
});
// Edit related project
router.post('/1.1/edit_related_projects.html', async function (req, res){
    console.log("######### /1.1/edit_related_projects.html BODY " + JSON.stringify(req.body, null, 4))
    var related_projects = await db.edcapi_cat_related_projects.findAll({ attributes: ['code','title']});
    var related_projects_scheme = await db.edcapi_cat_related_projects_scheme.findAll({ attributes: ['code','title']});

    project.findRelatedProjects(req.body.related_projects_id).then(value => {
        console.log("#### findRelatedProjects: " + JSON.stringify(value))
        res.render('modals/edit_related_projects',{
            data: value,
            relatedProjects: related_projects,
            relatedProjectsScheme: related_projects_scheme
        });
    });
});

//update party
router.post('/1.1/party', function(req,res){

    db_conf.edca_db.tx(function (t) {
        return t.batch([
            this.one('update parties set name=$1, partyid=$2, naturalperson=$3, position=$4, identifier_scheme=$5,' +
                ' identifier_id=$6, identifier_legalname=$7, identifier_uri=$8, address_streetaddress=$9, address_locality=$10,' +
                ' address_region=$11, address_postalcode=$12, address_countryname=$13, contactpoint_name=$14, contactpoint_email=$15,' +
                ' contactpoint_telephone=$16, contactpoint_faxnumber=$17, contactpoint_url=$18, surname = $20, additionalsurname= $21,' +
                ' contactpoint_surname = $22, contactpoint_additionalsurname= $23, givenname= $24, contactpoint_givenname = $25, contactpoint_type = $26,' +
                ' contactpoint_language = $27 where id = $19 returning id',[
                req.body.name, //  name
                req.body.partyid,
                (req.body.naturalperson==="true"),
                req.body.position,
                req.body.identifier_scheme,
                req.body.identifier_id,
                req.body.identifier_legalname,
                req.body.identifier_uri,
                req.body.address_streetaddress,
                req.body.address_locality,
                req.body.address_region,
                req.body.address_postalcode,
                req.body.address_countryname,
                `${req.body.contactpoint_givenname} ${req.body.contactpoint_surname} ${req.body.contactpoint_additionalsurname}`.trim(), // contactpoint name
                req.body.contactpoint_email,
                req.body.contactpoint_telephone,
                req.body.contactpoint_faxnumber,
                req.body.contactpoint_url,
                req.body.parties_id,
                req.body.surname,
                req.body.additionalsurname,
                req.body.contactpoint_surname,
                req.body.contactpoint_additionalsurname,
                req.body.givenname,
                req.body.contactpoint_givenname,
                req.body.contactpoint_type,
                req.body.contactpoint_language && typeof req.body.contactpoint_language !== 'string' ? req.body.contactpoint_language.join(','): req.body.contactpoint_language
            ]),
            this.one('update roles set buyer=$2, procuringentity=$3, supplier=$4, tenderer=$5, guarantor=$6,' +
                'enquirer=$7, payer=$8, payee=$9, reviewbody=$10, attendee=$11, ' +
                'official=$12, invitedSupplier=$13, issuingSupplier=$14, requestingunit=$15, contractingunit=$16, technicalunit=$17, responsibleunit=$18  where parties_id = $1 returning id', [
                req.body.parties_id,
                isChecked(req.body.buyer),
                isChecked(req.body.procuringEntity),
                isChecked(req.body.supplier),
                isChecked(req.body.tenderer),
                isChecked(req.body.guarantor),
                isChecked(req.body.enquirer),
                isChecked(req.body.payer),
                isChecked(req.body.payee),
                isChecked(req.body.reviewBody),
                isChecked(req.body.attendee),
                isChecked(req.body.official),
                isChecked(req.body.invitedSupplier),
                isChecked(req.body.issuingSupplier),
                isChecked(req.body.requestingunit),
                isChecked(req.body.contractingunit),
                isChecked(req.body.technicalunit),
                isChecked(req.body.responsibleunit)
            ]),
            this.none('update tender set numberoftenderers = (select count(*) from roles where contractingprocess_id = $1 and tenderer = true) ' + 
            'where contractingprocess_id = $1 ', [req.body.contractingprocess_id])
        ]);
    }).then(async function(data){
        updateHisitory(req.body.contractingprocess_id, req.user, Stages.planning, getHost(req));

        res.jsonp({
            status: 'Ok',
            description: "Los datos han sido actualizados",
            total: await getNumberOfTenderes(req.body.contractingprocess_id)
        });
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al actualizar los datos",
            error: error
        });
    });
});
//update party project
router.post('/1.1/party_project',async function(req,res){
    console.log("######### /1.1/party_project BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body);
    var relPartyProject = await db.edcapi_project_party_project.findAll({where: {edcapiProjectPartyId: req.body.party_id}}); 
    project.updateParty(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            project.updatePublishedDate(relPartyProject[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error - /1.1/update_budgetbreakdown_project " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update budget breakdown
router.post('/1.1/update_budgetbreakdown_project',async function(req,res){
    console.log("#### /1.1/update_budgetbreakdown_project " + JSON.stringify(req.body,null,4));
    var request = JSON.stringify(req.body);
    var relBudgetBreakdownBudget = new db.edcapi_project_budget_breakdown_budget(); 
    var relBudgetProject = new db.edcapi_budget_project(); 
    
    relBudgetBreakdownBudget = await db.edcapi_project_budget_breakdown_budget.findAll({
        where: {edcapiProjectBudgetBreakdownId: req.body.budget_budgetBreakdown_sourceParty}
    }).then(async function(data){
        if(data.length > 0){
            relBudgetProject = await db.edcapi_budget_project.findAll({
                where: {edcapiBudgetId: data[0].budget_id}
            }); 
        }
    }); 
    
    project.updateBudgetBreakdown(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            if(relBudgetProject.project_id !== null){
                project.updatePublishedDate(relBudgetProject[0].project_id,req.user);
            }
            
        }).catch(function (error) {
            console.log("Error - /1.1/update_budgetbreakdown_project " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update related project
router.post('/1.1/update_related_project',async function(req,res){
    console.log("######### /1.1/update_related_project BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body);
    var relRelatedProject = await db.edcapi_project_related_project_project.findAll({where: {edcapiProjectRelatedProjectId: req.body.related_project_id}});

    project.updateRelatedProject(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            project.updatePublishedDate(relRelatedProject[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error - /1.1/update_related_project " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update additional Identifier
router.post('/1.1/update_additional_identifier',async function(req,res){
    console.log("######### /1.1/update_additional_identifier BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    
    var relPartyAdditionalIdentifierParty = new db.edcapi_project_parties_additional_identifier_party();
    var relProjectPartyProject = new db.edcapi_project_party_project();

    relPartyAdditionalIdentifierParty = await db.edcapi_project_parties_additional_identifier_party.findAll({
        where: {edcapiProjectPartiesAdditionalIdentifierId: req.body.identifier_id}
    }).then(async function(data){
        relProjectPartyProject = await db.edcapi_project_party_project.findAll({
            where: {edcapiProjectPartyId: data[0].party_id}
        }); 
    }); 

    project.updateAdditionalIdentifier(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            project.updatePublishedDate(relProjectPartyProject[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error - /1.1/update_additional_identifier " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update budget line
router.post('/1.1/update_budget_line',async function(req,res){
    console.log("######### /1.1/update_budget_line BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 

    project.updateBudgetLineComponents(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).catch(function (error) {
            console.log("Error - /1.1/update_additional_identifier " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update budget line
router.post('/1.1/update_budget_line_measure',async function(req,res){
    console.log("######### /1.1/update_budget_line_measure BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    project.updateMeasure(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).catch(function (error) {
            console.log("Error - /1.1/update_additional_identifier " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update additional classification
router.post('/1.1/update_additional_classification',async function(req,res){
    console.log("######### /1.1/update_additional_classification BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    var relprojectAdditionalClassfication = await db.edcapi_project_additional_classification_project.findAll({where: {edcapiProjectAdditionalClassificationId: req.body.classification_id}});
    project.updateAdditionalClassification(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            project.updatePublishedDate(relprojectAdditionalClassfication[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error - /1.1/update_additional_classification " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
//update location project
router.post('/1.1/update_location_project',async function(req,res){
    console.log("######### /1.1/update_location_project BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    var relprojectLocation = await db.edcapi_project_location_project.findAll({where: {edcapiLocationProjectId: req.body.location_id}});
    console.log("######### relprojectLocation " + JSON.stringify(relprojectLocation, null, 4))
    project.updateLocationProject(request).then(async function(){
        return res.jsonp({
            status: 'Ok',
            description: "Los datos han sido actualizados",
        }).then(function(){
            project.updatePublishedDate(relprojectLocation[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error - /1.1/update_location_project " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
    })
});
//update document project
router.post('/1.1/update_document_project',async function(req,res){
    console.log("######### /1.1/update_document_project BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    var relprojectDocument = await db.edcapi_project_document_project.findAll({where: {edcapiProjectDocumentId: req.body.document_id}});
    project.updateDocumentProject(request).then(async function(){
            res.jsonp({
                status: 'Ok',
                description: "Los datos han sido actualizados",
            });
        }).then(function(){
            project.updatePublishedDate(relprojectDocument[0].project_id,req.user);
        }).catch(function (error) {
            console.log("Error /1.1/update_document_project " + error);
            res.status(400).jsonp({
                status : 'Error',
                description: "Ocurrió un error al actualizar los datos",
                error: error
            });
        });
});
router.delete('/1.1/party', isAuthenticated, function(req, res) {
    db_conf.edca_db.one('delete from parties where id = $1 returning id', [req.body.parties_id]).then(async function (party) {
        const total = await getNumberOfTenderes(req.body.contractingprocess_id);
        await db_conf.edca_db.none('update tender set numberoftenderers = $2 ' + 
            'where contractingprocess_id = $1 ', [req.body.contractingprocess_id, total]);

        updateHisitory(req.body.contractingprocess_id, req.user, Stages.planning, getHost(req));
        res.jsonp({
            status : 'Ok',
            description: "El registro ha sido eliminado",
            total: total
        });
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status: 'Error',
            description: "Ocurrió un error al borrar el registro"
        });
    })
});
//Delete party project
router.delete('/1.1/party_project', isAuthenticated,async function(req, res) {
    var relPartyProject = await db.edcapi_project_party_project.findAll({where: {edcapiProjectPartyId: req.body.parties_id}}); 
    project.deleteParty(req.body.parties_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relPartyProject[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete budget breakdown
router.delete('/1.1/delete_budget_breakdown_project', isAuthenticated,async function(req, res) {
    var relBudgetBreakdownBudget = new db.edcapi_project_budget_breakdown_budget(); 
    var relBudgetProject = new db.edcapi_budget_project(); 
    
    relBudgetBreakdownBudget = await db.edcapi_project_budget_breakdown_budget.findAll({
        where: {edcapiProjectBudgetBreakdownId: req.body.budgetbreakdown_id}
    }).then(async function(data){
        relBudgetProject = await db.edcapi_budget_project.findAll({
            where: {edcapiBudgetId: data[0].budget_id}
        }); 
    });
    project.deleteBudgetBreakdown(req.body.budgetbreakdown_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relBudgetProject[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete related project
router.delete('/1.1/delete_related_project', isAuthenticated,async function(req, res) {
    var relprojectRelatedProjectProject = await db.edcapi_project_related_project_project.findAll({where: {edcapiProjectRelatedProjectId: req.body.related_projects_id}});
    project.deleteRelatedProject(req.body.related_projects_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relprojectRelatedProjectProject[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete additional identifier
router.delete('/1.1/delete_additional_identifier', isAuthenticated,async function(req, res) {
    var relPartyAdditionalIdentifierParty = new db.edcapi_project_parties_additional_identifier_party();
    var relProjectPartyProject = new db.edcapi_project_party_project();

    relPartyAdditionalIdentifierParty = await db.edcapi_project_parties_additional_identifier_party.findAll({
        where: {edcapiProjectPartiesAdditionalIdentifierId: req.body.identifier_id}
    }).then(async function(data){
        relProjectPartyProject = await db.edcapi_project_party_project.findAll({
            where: {edcapiProjectPartyId: data[0].party_id}
        }); 
    }); 
    project.deleteAdditionalIdentifier(req.body.identifier_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relProjectPartyProject[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete additional identifier
router.delete('/1.1/delete_budget_line_measure', isAuthenticated,async function(req, res) {
    project.deleteBudgetLineMeasure(req.body.budget_line_measure_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete budget line
router.delete('/1.1/delete_budget_line', isAuthenticated,async function(req, res) {
    project.deleteBudgetLineComponents(req.body.budget_line_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete additional classification
router.delete('/1.1/delete_additional_classification', isAuthenticated,async function(req, res) {
    var relprojectAdditionalClassfication = await db.edcapi_project_additional_classification_project.findAll({where: {edcapiProjectAdditionalClassificationId: req.body.classification_id}});
    project.deleteAdditionalClassification(req.body.classification_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relprojectAdditionalClassfication[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete related contracting process
router.delete('/1.1/delete_related_contracting_process_project', isAuthenticated,async function(req, res) {
    var relRelatedProjectProject = await db.edcapi_project_related_contracting_process_project.findAll({where: {edcapiProjectRelatedContractingProcessId: req.body.contracting_process_id}});
    project.deleteRelatedContractingProcessProject(req.body.contracting_process_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relRelatedProjectProject[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete location project
router.delete('/1.1/delete_location_project', isAuthenticated,async function(req, res) {
    var relprojectLocation = await db.edcapi_project_location_project.findAll({where: {edcapiLocationProjectId: req.body.location_id}});
    project.deleteLocationProject(req.body.location_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relprojectLocation[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//Delete document project
router.delete('/1.1/delete_document_project', isAuthenticated,async function(req, res) {
    var relprojectDocument = await db.edcapi_project_document_project.findAll({where: {edcapiProjectDocumentId: req.body.document_id}});
    project.deleteDocumentProject(req.body.document_id).then(async function(){
        res.jsonp({
            status: 'Ok',
            description: "El registro ha sido eliminado",
        });
    }).then(function(){
        project.updatePublishedDate(relprojectDocument[0].project_id,req.user);
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status : 'Error',
            description: "Ocurrió un error al borrar el registro",
            error: error
        });
    });
});
//delete all parties per contracting process
router.delete('/1.1/parties', function (req, res) {

    db_conf.edca_db.manyOrNone('delete from parties where contractingprocess_id = $1 returning id ',[
        req.body.contractingprocess_id
    ]).then(async function(deleted_parties){
        updateHisitory(req.body.contractingprocess_id, req.user, Stages.planning, getHost(req));

        res.jsonp({
            status: 'Ok',
            parties: deleted_parties
        });
    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status: 'Error',
            error: error
        });
    });

});

//debe existir una restricción para que asignar no más de un party como buyer o procuringEntity

//get amenments
router.get('/1.1/:path/amendments', function (req, res) {
    var rel = '';
    switch ( req.params.path ){
        case 'tender':
            rel = 'TenderAmendments';
            break;
        case 'awards':
            rel = 'AwardsAmendments';
            break;
        case 'contracts':
            rel = 'ContractsAmendments';
            break;
        default:
            res.status(400).jsonp({
                status: 'Error',
                message: 'Parámetros incorrectos'
            });
    }


    db_conf.edca_db.manyOrNone('select * from ~$1 where award_id=$2, contractingprocess_id=$3',[
        rel,
        req.body.award_id,
        req.body.contractingprocess_id
    ]).then(function (amendments) {

    }).catch(function (error) {
        console.log(error);
        res.status(400).jsonp({
            status: 'Error',
            error: error
        })
    })
});

//new amendment
router.put('/1.1/:path/amendment', function(req, res){

    var rel = '';
    let stage = 0;
    switch ( req.params.path ){
        case 'tender':
            rel = 'TenderAmendments';
            stage = Stages.tender;
            break;
        case 'awards':
            rel = 'AwardAmendments';
            stage = Stages.award;
            break;
        case 'contracts':
            rel = 'ContractsAmendments';
            stage = Stages.contract;
            break;
        default:
            res.status(400).jsonp({
                status: 'Error',
                message: 'Parámetros incorrectos'
            });
    }

    db_conf.one('insert into ~$1(contractingprocess_id, contract_id, amendment_date, rationale, amendment_id, ' +
        'description, amendsReleaseID, releaseID) values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id',[
        rel,
        req.body.contractingprocess_id,
        req.body.contract_id,
        req.body.amendment_date,
        req.body.rationale,
        req.body.amendment_id,
        req.body.description,
        req.body.amendsReleaseID,
        req.body.releaseID
    ]).then(async function(data){
        updateHisitory(req.body.contractingprocess_id, req.user, stage, getHost(req));

        res.jsonp({
            status: 'Ok',
            data: data
        });
    }).catch(function (error) {
        res.status(400).jsonp({
            status: 'Error',
            error: error
        });
    });
});

//update amendment
router.post('/1.1/:path/amendment', function(req, res){
    var rel = '';
    let stage = 0;
    switch ( req.params.path ){
        case 'tender':
            rel = 'TenderAmendments';
            stage = Stages.tender;
            break;
        case 'awards':
            rel = 'AwardAmendments';
            stage = Stages.award;
            break;
        case 'contracts':
            rel = 'ContractsAmendments';
            stage = Stages.contract;
            break;
        default:
            res.status(400).jsonp({
                status: 'Error',
                message: 'Parámetros incorrectos'
            });
    }

    db_conf.one('update ~$1 set contractingprocess_id=$2, contract_id=$3, amendment_date=$4, rationale=$5, amendment_id=$6, ' +
        'description=$7, amendsReleaseID=$8, releaseID=$9 where id = $10 returning id',[
        rel,
        req.bod.id,
        req.body.contractingprocess_id,//?
        req.body.contract_id, //?
        req.body.amendment_date,
        req.body.rationale,
        req.body.amendment_id,
        req.body.description,
        req.body.amendsReleaseID,
        req.body.releaseID,
        req.body.id
    ]).then(async function(data){
        updateHisitory(req.body.contractingprocess_id, req.user, stage, getHost(req));
        res.jsonp({
            status: 'Ok',
            data: data
        });
    }).catch(function (error) {
        res.status(400).jsonp({
            status: 'Error',
            error: error
        });
    });
});

//delete amenment
router.delete('/1.1/:path/amendment', function(req, res){
    var rel = '';
    let stage = 0;
    switch ( req.params.path ){
        case 'tender':
            rel = 'TenderAmendments';
            stage = Stages.tender;
            break;
        case 'awards':
            rel = 'AwardAmendments';
            stage = Stages.award;
            break;
        case 'contracts':
            rel = 'ContractsAmendments';
            stage = Stages.contract;
            break;
        default:
            res.status(400).jsonp({
                status: 'Error',
                message: 'Parámetros incorrectos'
            });
    }

    db_conf.edca_db.one('delete from ~$1 where id = $2',[
        rel,
        req.body.amendment_id
    ]).then(async function (data) {
        updateHisitory(req.body.contractingprocess_id, req.user, stage, getHost(req));
        res.json({
            status: 'Ok',
            data: data
        })
    }).catch(function (error) {
        res.json({
            status: 'Error',
            error: error
        })
    });
});

router.get('/admin/metadata.html', isAuthenticated, async (req, res) => {
    if(req.user.isAdmin){
        const listMetadata = await db_conf.edca_db.manyOrNone('select *  from metadata');
        const metadata = {};
        listMetadata.map(x => metadata[x.field_name] = x.value);
        res.render('modals/metadata_modal', {data: metadata})  
    } else {
        res.send("<p><b>No estás autorizado para actualizar los metadatos</b></p>");
    }
});

router.post('/admin/update-metadata', isAuthenticated, async  (req, res) => {
    try{
        if ( req.user.isAdmin === true ) {

            const allMetadata = query = await db_conf.edca_db.manyOrNone('select * from metadata');

            Object.keys(req.body).map(async key => {
                const metadata = req.body[key];
                if(allMetadata.findIndex(m => m.field_name === key) === -1){
                    await db_conf.edca_db.none('insert into metadata (field_name, value) values($1, $2)', [key, metadata]);
                } else{
                    await db_conf.edca_db.none('update metadata set value = $2 where field_name = $1',  [key, metadata]);
                }
            });

            await db_conf.edca_db.none('update contractingprocess set publicationpolicy = $2 , license= $1' , [req.body.licencia_url, req.body.politica_url]);

            res.status(200).json({
                status: 'Ok',
                message: 'Metadatos actualizados'
            });
        } else {
            res.status(401).json({
                status: 'Error',
                message: 'No estás autorizado para actualizar los metadatos'
            });
        }
    }
    catch (e) {
        console.log(e);
        res.status(400).json({
            status: 'Error',
            message: 'Ha ocurrido un error al guardar los metadatos'
        });
    }
       
});

// list units
let listUnits = async () => await db_conf.edca_db.manyOrNone("select distinct unit as name, unit as value from item where unit is not null order by unit");

// list administrative units
let listAdministrativeUnits = async () => await db_conf.edca_db.manyOrNone("select distinct requestingunit || ' - ' || requestingunit_desc as name, requestingunit as value from programaticstructure order by requestingunit");

let listYears = async () => await db_conf.edca_db.manyOrNone("select  year as value, year as name from programaticstructure where year is not null group by year order by year desc");

let listMIRActivities = async (data) => {
    if (data != null && data.requestingunit) {
        return await db_conf.edca_db.manyOrNone("select distinct aspecificactivity as value, specificactivity || ' - ' || specificactivity_desc as name from programaticstructure order where requestingunit = ${requestingunit} and  by specificactivity", data);
    } else {
        return await db_conf.edca_db.manyOrNone("select distinct specificactivity as value, specificactivity  || ' - ' || specificactivity_desc  as name from programaticstructure order by specificactivity");
    }
};

let listDepartures = async () => await db_conf.edca_db.manyOrNone("select part as value, desp as name, mir as mir from departure order by part");

/**
 * Generar la clave para la estructura
 * @param {Object} structure Estructura programatica
 */
let genereteProgramaticstructureCve = (structure) => {
    if(structure.trimester){
        if(/primero|primer|1/.test(structure.trimester.toString().toLowerCase())) structure.trimester = 1;
        else if(/segundo|2/.test(structure.trimester.toString().toLowerCase())) structure.trimester = 2;
        else if(/tercero|tercer|3/.test(structure.trimester.toString().toLowerCase())) structure.trimester = 3;
        else structure.trimester = 4;
    } else {
        structure.trimester = trimesters[parseInt((new Date().getMonth() % 3))].value;
    }
    let regex = new RegExp(/[^0-9\.]/,'g');
    structure.approvedamount = parseFloat(structure.approvedamount.replace(regex,'')) || 0;
    structure.modifiedamount = parseFloat(structure.modifiedamount.replace(regex,'')) || 0;
    structure.executedamount = parseFloat(structure.executedamount.replace(regex,'')) || 0;
    structure.committedamount = parseFloat(structure.committedamount.replace(regex,'')) || 0;
    structure.reservedamount = parseFloat(structure.reservedamount.replace(regex,'')) || 0;
    return `${structure.year}${structure.trimester}${structure.branch}${structure.finality}${structure.function}` +
    `${structure.subfunction}${structure.institutionalactivity}${structure.budgetprogram}${structure.strategicobjective}` +
    `${structure.responsibleunit}${structure.requestingunit}${structure.spendingtype}${structure.specificactivity}` +
    `${structure.spendingobject}${structure.region}${structure.budgetsource}${structure.portfoliokey}`;
}

let trimesters = [
    {name: 'Primero', value: 1},
    {name: 'Segundo', value: 2},
    {name: 'Tercero', value: 3},
    {name: 'Cuarto', value: 4}
];

let typesOfCatalogs = {
    item: {
        label: 'Ítem',
        schema: [
            {label: 'Identificador', field: 'classificationid', required: true, class:'col-sm-3', type: 'string', pk: true },
            {label: 'Descripción', field: 'description', required: true, class:'col-sm-4', type: 'string' },
            {label: 'Tipo de Unidad', field: 'unit', fn: listUnits, data: [], class:'col-sm-3', type: 'string' }
        ]
    },
    programaticstructure: {
        label: 'Estructura Programática',
        schema: [
            {label: 'Clave', field: 'cve', readonly: true, pk: true, genereteKey: genereteProgramaticstructureCve, ignored: true, hidden: true},
            {label: 'Año', field: 'year', required: true, class: 'col-sm-3', type: 'number'},
            {label: 'Trimestre', field: 'trimester', data: trimesters, required: true, class: 'col-sm-3', type: 'number' },
            {label: 'Clave de Ramo', field: 'branch', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Ramo', field: 'branch_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Finalidad', field: 'finality', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Finalidad', field: 'finality_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Función', field: 'function', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Función', field: 'function_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Subfunción', field: 'subfunction', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Subfunción', field: 'subfunction_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Actividad Institucional', field: 'institutionalactivity', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Actividad Institucional', field: 'institutionalactivity_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Programa Presupuestario', field: 'budgetprogram', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Programa Presupuestario', field: 'budgetprogram_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Objetivo Estratégico', field: 'strategicobjective', required: true, class: 'col-sm-4', type: 'string', ignored: true},
            {label: 'Objetivo Estratégico', field: 'strategicobjective_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Unidad Responsable', field: 'responsibleunit', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Unidad Responsable', field: 'responsibleunit_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Unidad Administrativa', field: 'requestingunit', required: true, class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Unidad Administrativa', field: 'requestingunit_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Tipo de Gasto', field: 'spendingtype', class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Tipo de Gasto', field: 'spendingtype_desc', class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Actividad MIR', field: 'specificactivity', class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Actividad MIR', field: 'specificactivity_desc', class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Partida', field: 'spendingobject', class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Partida', field: 'spendingobject_desc', class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Entidad Federativa', field: 'region', class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Entidad Federativa', field: 'region_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Fuente de financiamiento', field: 'budgetsource', class: 'col-sm-3', type: 'string', ignored: true},
            {label: 'Fuente de financiamiento', field: 'budgetsource_desc', required: true, class: 'col-sm-3', type: 'string'},
            {label: 'Clave de cartera', field: 'portfoliokey', required: true, class: 'col-sm-3', type: 'string', ignored: true} ,
            {label: 'Original anualizado', field: 'approvedamount', type:'number', ignored: true} ,
            {label: 'Modificado anualizado', field: 'modifiedamount',type:'number', ignored: true} ,
            {label: 'Ejercido', field: 'executedamount',type:'number', ignored: true} ,
            {label: 'Comprometido anualizado', field: 'committedamount',type:'number', ignored: true},
            {label: 'Reservado anualizado', field: 'reservedamount',type:'number', ignored: true}
        ]
    },
    activitymir: {
        label: 'Actividad MIR',
        // esta propiedad indica la tabla original hacia donde apuntara el "catalogo"
        faketable: 'programaticstructure',
        schema: [
            {label: 'Clave', field: 'specificactivity', required: true, type: 'string', pk: true, class: 'col-sm-2' },
            {label: 'Nombre', field: 'specificactivity_desc', required: true, class: 'col-sm-5', type: 'string' },
            {label: 'Unidad Administrativa', field: 'requestingunit', required: true, class: 'col-sm-5', type: 'string', fn: listAdministrativeUnits, data: []}
        ]
    },
    departure: {
        label: 'Partida',
        faketable: 'programaticstructure',
        schema: [
            {label: 'Clave', field: 'spendingobject', required: true, pk: true, class: 'col-sm-2'},
            {label: 'Descripción', field: 'spendingobject_desc', required: true, class: 'col-sm-5', type: 'string'},
            {label: 'Clave de Actividad MIR', field: 'specificactivity', required: true, class: 'col-sm-5', type: 'string', fn: listMIRActivities, data: []},
            {label: 'Clave de Tipo de Gasto', field: 'spendingtype', class: 'col-sm-3', type: 'string'},
            {label: 'Tipo de Gasto', field: 'spendingtype_desc', class: 'col-sm-3', type: 'string'},
            {label: 'Clave de Fuente de Financimamiento', field: 'budgetsource', class: 'col-sm-4', type: 'string'},
            {label: 'Fuente de Financimamiento', field: 'budgetsource_desc', class: 'col-sm-3', type: 'string'}
        ]
    },
    administrativeunit: {
        label: 'Unidad Administrativa',
        faketable: 'programaticstructure',
        schema: [
            {label: 'Clave', field: 'requestingunit', class: 'col-sm-2', type: 'string', required:true, pk: true},
            {label: 'Nombre', field: 'requestingunit_desc', class: 'col-sm-3', type: 'string'}
        ]
    }
};

// view admin catalogos
router.get('/admin/catalog/:catalog/', isAuthenticated, async (req, res) => {
    if(req.user.isAdmin) {
        let catalog = typesOfCatalogs[req.params.catalog];
        if(!catalog){
            return res.send('No se ha encontrado el tipo de lista');
        }

        for(let x = 0, schema = catalog.schema[x]; x < catalog.schema.length; x++, schema = catalog.schema[x]){
            if(schema.fn && typeof schema.fn === 'function'){ 
                schema.data = await schema.fn();
            }
        }

        catalog.type = req.params.catalog;
        res.render('modals/admin_catalog', catalog);
    } else {
        res.render('No tiene permisos para acceder a esta sección');
    }
});

// search catalog
router.post('/admin/catalog/:catalog/search/', isAuthenticated, async (req, res) => {
    try{

        const filters = [];
        let catalog = typesOfCatalogs[req.params.catalog];
        
        if(!catalog){
            return res.status(400).json({message: 'No se ha encontrado el tipo de lista'});
        }

        const pk = catalog.schema.find(x => x.pk);
        let fields = [];

        catalog.schema.map(x => {
            fields.push(x.field);
            switch(x.type){
                case 'string':
                default:
                if(req.body[x.field]){
                    filters.push(`lower(${x.field}) like lower('%'||\${${x.field}}||'%')`);
                }
                break;
                case 'number':
                if(req.body[x.field]){
                    filters.push(`${x.field} = \${${x.field}}`);
                }
                break;
            }
        });

        filters.push(`${pk.field} is not null`);
        req.body.page = req.body.page || 1;
        req.body.pageSize = req.body.pageSize || 25;

        let sqlCount = catalog.faketable ?
         `select count(*) total from ( select ${fields.join(',')} from ${catalog.faketable} ${(filters.length > 0 ? 'where ' + filters.join(' and ') : '')} group by ${fields.join(',')}) as x` : 
         `select count(*) total from ${req.params.catalog} ${(filters.length > 0 ? 'where ' + filters.join(' and ') : '')}`;
        const {total} = (await db_conf.edca_db.oneOrNone(sqlCount, req.body));
        
 
        const sql = catalog.faketable ? 
        `select distinct ${pk.field} as id, ${fields.join(',')} from ${catalog.faketable} ${(filters.length > 0 ? 'where ' + filters.join(' and ') : '')} order by ${fields.join(',')} limit \${pageSize} offset \${page}` :
        `select * from ${req.params.catalog} ${(filters.length > 0 ? 'where ' + filters.join(' and ') : '')} order by id limit \${pageSize} offset \${page}`;
        const result = await db_conf.edca_db.manyOrNone(sql, req.body);

        return res.status(200).json({data: result, total: total});
    } catch(e) {
        return res.status(400).json({message: 'Error al consultar la lista'});
    }
});

// view new/edit code
router.get('/admin/catalog/:catalog/fields/:id?', isAuthenticated, async (req,res) => {
    try{

        let catalog = typesOfCatalogs[req.params.catalog];
        catalog.item = {};
        if(!catalog){
            return res.send('No se ha encontrado el tipo de lista');
        }

        let sql = catalog.faketable ? 
        `select ${catalog.schema.map(x => x.field).join(',')} from ${catalog.faketable} where ${catalog.schema.find(x => x.pk).field} = \${id} limit 1` :
        `select * from ${req.params.catalog} where id = \${id}`

        if(req.params.id) {
            catalog.item = await db_conf.edca_db.oneOrNone(sql, req.params);
            for(let x = 0, schema = catalog.schema[x]; x < catalog.schema.length; x++, schema = catalog.schema[x]){
                if(schema.fn && typeof schema.fn === 'function'){
                    schema.data = await schema.fn(catalog.item);
                }
            }
            catalog.item.id = req.params.id;
        } 
        res.render('modals/newcatalog-fields', catalog);
    } 
    catch(e){
        console.log();
        res.send('Error al cargar el código');
    }
    
});

let insertOrUpdateCatalog = async (table, catalog, item)  => {

    let sql = '';
    if(catalog.faketable) table = catalog.faketable;
    let pk = catalog.schema.find(x => x.pk);

    if(item.id) {
        let sets = [];
        catalog.schema.map(x => sets.push(`${x.field} = \${${x.field}}`));
        sql = catalog.faketable ? 
        `update ${table} set ${(sets.join(', '))} where ${pk.field} = \${id}` :
        `update ${table} set ${(sets.join(', '))} where id = \${id}`;
    } else {
        let inserts = [], values = [];
        catalog.schema.map(x => {
            inserts.push(x.field);
            values.push(`\${${x.field}}`);
        });
        sql = `insert into ${table} (${(inserts.join(', '))}) values (${(values.join(', '))})`;
    }

    await db_conf.edca_db.none(sql, item);
}
// create/edit catalog
router.post('/admin/catalog/:catalog', isAuthenticated, async (req,res) => {
    try{
        let catalog = typesOfCatalogs[req.params.catalog];
        if(!catalog){
            return res.status(400).json({message: 'No se ha encontrado el tipo de lista'});
        }

        
        let pk = catalog.schema.find(x => x.pk);
        if(pk && pk.genereteKey) {
            req.body[pk.field] = pk.genereteKey(req.body);
        }

        await insertOrUpdateCatalog(req.params.catalog, catalog, req.body);
        return res.status(200).json({message: 'Se ha registrado'});
    }
    catch(e) {
        let message = 'No se ha podido registrar el registro';
        if(e.routine === '_bt_check_unique') message = 'Ya existe un registro con el mismo identificador';
        return res.status(400).json({message: message });
    }
});


// delete code
router.post('/admin/catalog/:catalog/:id/delete', isAuthenticated, async (req,res) => {
    try{
        let catalog = typesOfCatalogs[req.params.catalog];
        if(!catalog){
            return res.status(400).json({message: 'No se ha encontrado el tipo de lista'});
        }

        let pk = catalog.schema.find(x => x.pk);
        let sql = catalog.faketable ?
        `delete from ${catalog.faketable} where ${pk.field} = \${id}` :
        `delete from ${req.params.catalog} where id = \${id}`;
        await db_conf.edca_db.none(sql, req.params);

        return res.status(200).json({message: 'Se ha eliminado'});
    }
    catch(e) {
        return res.status(400).json({message: 'No se ha podido eliminar'});
    }
});

// view import codes
router.get('/admin/catalog/:catalog/import', isAuthenticated, (req, res) => {
    res.render('modals/import-catalog', {catalog: req.params.catalog});
});


// view download template
router.get('/admin/catalog/:catalog/import/template', (req, res) => {
    let catalog = typesOfCatalogs[req.params.catalog];
    const codesTemplate = [];

    if(catalog){
        catalog.schema.map(x =>{if(!x.genereteKey){codesTemplate.push(x.label)};});
    }

    let buff = new Buffer(codesTemplate.join(','), 'latin1');  
    let readStream = new stream.PassThrough();
    readStream.end(buff);
    res.set('Content-disposition', 'attachment; filename=import-catalog.csv');
    res.set('Content-Type', 'text/plain; charset=latin1');

    readStream.pipe(res);
});

// import codes
router.post('/admin/catalog/:catalog/import', isAuthenticated,upload.single('datafile'), async (req,res) => {
    const fs = require('fs');
    try{
        let catalog = typesOfCatalogs[req.params.catalog];

        if(!catalog){
            return  res.status(400).send(`Tipo incorrecto de lista.`);
        }

        // increment timeout to 10min
        req.setTimeout(10000*60);
        let errors = [];
        let total = 0;
   
        // read file and parse to json
        let records = await csvtojsonV2().fromStream(fs.createReadStream(req.file.path, {encoding: 'latin1'}));
 
        if(req.body.clear === 'true') {
            await db_conf.edca_db.query(`delete from ${!catalog.faketable ? req.params.catalog : catalog.faketable}`);
        }
        console.log('importando...');

        for(let i = 0, item = records[0]; i < records.length; i++, item = records[i]){

            let pk = catalog.schema.find(x => x.pk);
            if(pk && (item[pk.label] || pk.genereteKey)){
                try{
                    let record = {};
                    catalog.schema.map(x => record[x.field] = item[x.label]);
                    // generar clave si requiere ser generada en el momento
                    if(pk.genereteKey) record[pk.field] = pk.genereteKey(record);

                    if(!catalog.faketable){
                        // si no es una tabla falta se busca el id del registro en base a la clave configurada
                        const exists = await db_conf.edca_db.oneOrNone(`select id from ${req.params.catalog} where ${pk.field} = \${${pk.field}} limit 1`, record);
                        if(exists) console.log('existe ', record[pk.field], record.trimester);
                        record.id = exists ? exists.id : undefined;
                    } else {
                        const exists = await db_conf.edca_db.oneOrNone(`select id from ${catalog.faketable} where ${pk.field} = \${${pk.field}} limit 1`, record);
                        if(exists) console.log('existe ', record[pk.field]);
                        record.id = exists ? record[pk.field] : undefined;
                    }

                    await insertOrUpdateCatalog(req.params.catalog, catalog, record);
                }
                catch(e){
                    let message = e.routine === '_bt_check_unique' ? 'Ya existe un código con el mismo identificador.' : e.message;
                    errors.push(`Revisar línea ${(i + 2)}. ${message}`);
                }
            } else{
                errors.push(`Revisar línea ${(i + 2)}. Debe ingresar identificador y descripción`);
            }
            total++;
        }
        return res.json({ message: `Se han importado ${total - errors.length} de ${total} códigos`, errors : errors});  
    }
    catch (e) {
        res.status(400).send(`No se ha podido realizar la importación.`);
    }
    finally {
        require('fs').unlinkSync(req.file.path);
    }
});


let getPrefixOCID = async () => {
    return (await db_conf.edca_db.oneOrNone('select * from prefixocid order by id  limit 1')) || {};
}

// view admin prefix ocid
router.get('/admin/ocid', isAuthenticated, async (req,res) => {
    res.render('modals/admin_ocid', {ocid: await getPrefixOCID()});
});

// update prefix ocid
router.post('/admin/ocid', isAuthenticated, async (req,res) => {
    let ocid = await getPrefixOCID();
    ocid.value = req.body.value ? req.body.value.trim() : '';
    if(ocid.id){
        await db_conf.edca_db.none('update prefixocid set value = ${value}', ocid);
    } else{
        await db_conf.edca_db.none('insert into prefixocid (value) values(${value})', ocid);
    }
    return res.status(200).json({message: 'Se ha registrado el prefijo'});
});
// OC4IDS

// view admin prefix ocid
router.get('/admin/oc4ids', isAuthenticated, async (req,res) => {
    project.generateOc4ids().then(async function(value){
        res.render('modals/admin_oc4ids', {oc4ids: value[0].prefix});
    });
});

router.get('/admin/policy', isAuthenticated, async (req,res) => {
    cp_functions.getPolicy().then(function(value){
        console.log('/admin/policy value ' + JSON.stringify(value))
        res.render('modals/admin_policy', {policy: value});
    })
});

router.post('/admin/policy', isAuthenticated, async (req,res) => {
    console.log('/admin/policy post ' + JSON.stringify(req.body.textarea))
    cp_functions.createPolicy(req.body.textarea).then(() => {
        return res.status(200).json({message: 'Se registro correctamente'});
    })
});

// update prefix ocid
router.post('/admin/oc4ids', isAuthenticated, async (req,res) => {
    var value = req.body.value ? req.body.value.trim() : '';
    project.updatePrefix(value.replace(/ /g,"")).then(async function(){
        return res.status(200).json({message: 'Se ha registrado el prefijo'});
    });
});

// view years to publish
router.get('/admin/years', isAuthenticated, async (req,res) => {
    cp_functions.getFiscalYears().then(async arrayFiscalYear => {
        console.log(`${JSON.stringify(arrayFiscalYear)}`)
        res.render('modals/admin_years',{
            fiscalYear : arrayFiscalYear
        });
    })
    
});

router.get('/validate/:cpid', async  (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(req.params.cpid, getHost(req));
        const vp = new VadalitionProcess(req.params.cpid, db_conf.edca_db);
        const validationResult = await vp.validate();
        res.send(validationResult);
    }
    catch(e) {
        console.log(e);
        res.send('No se han encontrado resultados');
    }
});

// view list process
router.get('/validate-process', isAuthenticated, async  (req, res) => {
    res.render('modals/validate_process_list');
});

router.post('/validate-process/search', isAuthenticated, async  (req, res) => {
    try{
        
        let where = [];

        if(req.body.id) {
            where.push('cp.id = ${id}');
        }

        if(req.body.ocid) {
            req.body.ocid = req.body.ocid.trim().toLowerCase()
            where.push("lower(trim(ocid)) like  '%' || ${ocid} || '%'");
        }

        if(req.body.publisher) {
            req.body.publisher = req.body.publisher.trim().toLowerCase();
            where.push("lower(trim(publisher)) like  '%' || ${publisher} || '%'");
        }

        let processes = await db_conf.edca_db.manyOrNone(`select distinct on (cp.id)
            cp.id,
            cp.ocid,
            cp.publisher,
            cp.updated,
            cp.published,
            cp.valid,
            to_char(cp.date_published, 'YYYY/MM/DD ') as date_published,
            cp.published_version,
            to_char(cp.updated_date, 'YYYY/MM/DD') as updated_date,
            cp.updated_version,
            cp.pnt_published,
            cp.pnt_version,
            to_char(cp.pnt_date, 'YYYY/MM/DD') as pnt_date,
            dp.data_pnt
        from contractingprocess cp full outer join datapnt dp on cp.id = dp.contractingprocess_id
        where cp.id in (select contractingprocess_id from tender where tenderid is not null)
        ${(where.length > 0 ? ' AND ' + where.join(' AND ') : '')} order by cp.id, dp.id desc`, req.body);
        res.json(processes);
    }
    catch(e) {
        console.log(e);
        res.send('No se han encontrado resultados');
    }
});

// validate process
router.post('/validate-process/validate/:id', isAuthenticated, async (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(req.params.id, getHost(req));
        const vp = new VadalitionProcess(req.params.id, db_conf.edca_db);
        const validationResult = await vp.validate();
        req.params.valid = validationResult.valid;
        await db_conf.edca_db.none('update contractingprocess set valid = ${valid} where id = ${id}', req.params);
        return res.render('modals/validation-result',{
            message: validationResult.valid ? 'El proceso ha pasado la validación' : 'El proceso no ha pasado la validación',
            data :  syntaxHighlight(JSON.stringify(validationResult.data ? validationResult.data : { 'Validación': 'Sin errores'}, undefined ,4)),
            capture :  syntaxHighlight(JSON.stringify(validationResult.capture ? validationResult.capture : { 'Validación': 'Sin errores'}, undefined ,4)),
            resume: validationResult.resume
        });
    }
    catch(e) {
        console.log(e);
        return res.status(400).json({message: 'No se ha podido validar. ' + e.message});
    }
});


let syntaxHighlight = json => {      
    return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
        var cls = 'number';
        if (/^"/.test(match)) {
            if (/:$/.test(match)) {
                cls = 'key';
            } else {
                cls = 'string';
            }
        } else if (/true|false/.test(match)) {
            cls = 'boolean';
        } else if (/null/.test(match)) {
            cls = 'null';
        }
        return '<span class="' + cls + '">' + match + '</span>';
    });
}

// publish process
router.post('/validate-process/publish/:id/:status?', isAuthenticated, async (req, res) => {
    try{

        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(req.params.id, getHost(req));
        const vp = new VadalitionProcess(req.params.id, db_conf.edca_db);
        const validationResult = await vp.validate();
        req.params.valid = validationResult.valid;
        await db_conf.edca_db.none('update contractingprocess set valid = ${valid} where id = ${id}', req.params);
        if(validationResult.valid){
            //  se indica cual log es el que esta publicado
            await db_conf.edca_db.none('update logs set published = true where id in (SELECT id from logs WHERE contractingprocess_id = ${id} ORDER BY update_date desc LIMIT 1 )', req.params);
            
            // se procede a clonar las bases para el dashboard
            await require('../utilities/export2Dashboard')(req.params.id);


            let {publisher}  = await db_conf.edca_db.one('SELECT publisher FROM logs WHERE contractingprocess_id = $1 AND published = true ORDER BY update_date DESC LIMIT 1',[req.params.id]);

            publisher = await User.findOne({'_id': publisher});

            // actualizar historial
            await db_conf.edca_db.none(`UPDATE contractingprocess SET
                                            published_version = (SELECT version FROM logs WHERE contractingprocess_id = $1 AND published = true ORDER BY update_date DESC LIMIT 1),
                                            date_published = now(),
                                            published = true,
                                            publisher = $2,
                                            updated = false
                                        WHERE id = $1`, [req.params.id, publisher ? publisher.publisherName : 'Sin publicador']);

            return res.json({message: 'Proceso publicado'});
        } else {
            return res.status(400).json({message: 'No se ha pasado la validación. Para ver mas detalle darle clic en la opción de validar.'});
        }
    }
    catch(e) {
        console.log(e);
        return res.status(400).json({message: 'No se ha podido publicar'});
    }
});

// generate json of process
router.get('/validate-process/:id', async (req, res) => {
    try{
        const vp = new VadalitionProcess(req.params.id, db_conf.edca_db);
        return res.json(await vp.validate());
    }
    catch(e) {
        console.log(e);
        return res.json();
    }
});


// view Clarification Meetings
router.get('/clarificationmeetings/:cp', isAuthenticated, async (req, res) => {
    try{
        if(!req.params.cp) return res.send('No se ha especificado la contratación');
        let data = await db_conf.edca_db.manyOrNone('select * from clarificationmeeting where contractingprocess_id = ${cp}', req.params);
        
        return res.render('modals/clarificationmeetings-list',{data: data});
    }
    catch(e){
        console.log(e);
        return res.send('Error al cargar las juntas de aclaraciones');
    }
});

// get partial view clarification meetings
router.get('/clarificationmeetings/:cp/fields/:id?', isAuthenticated, async (req, res) => {
    try{
        let data = {
            id: '',
            clarificationmeetingid: '',
            contractingprocess_id: req.params.cp,
            date_text: '',
            attenders: [],
            officials: []
        };
        if(req.params.id){
            data = await db_conf.edca_db.oneOrNone("select *, to_char(date, 'YYYY-MM-DD HH:MI:SS') as date_text from clarificationmeeting where id = ${id} and contractingprocess_id = ${cp}", req.params);
            data.attenders = (await db_conf.edca_db.manyOrNone('select parties_id id from clarificationmeetingactor where clarificationmeeting_id = ${id} and attender = true', req.params)).map(x => x.id);
            data.officials = (await db_conf.edca_db.manyOrNone('select parties_id id from clarificationmeetingactor where clarificationmeeting_id = ${id} and official = true', req.params)).map(x => x.id);
        }
        
        data.listAttenders = await db_conf.edca_db.manyOrNone('select id, name, position from parties where contractingprocess_id = ${cp} and id in (select parties_id from roles where attendee = true)', req.params);
        data.listOfficials = await db_conf.edca_db.manyOrNone('select id, name, position from parties where contractingprocess_id = ${cp} and id in (select parties_id from roles where official = true)', req.params);

        return res.render('modals/newclarificationmeeting', data);
    }catch (e){
        return res.send('Error al cargar formulario');
    }
});

// create or update clarification meeting
router.post('/clarificationmeetings/:cp/fields', isAuthenticated, async (req, res) => {
    try{

        if(req.body.id){
           await db_conf.edca_db.none('update clarificationmeeting set date = ${date} where id = ${id} and contractingprocess_id = ${contractingprocess_id}  ',req.body);
           await db_conf.edca_db.none('delete from clarificationmeetingactor where clarificationmeeting_id = ${id}',req.body);
        } else {
            req.body.id = (await db_conf.edca_db.one('insert into clarificationmeeting (contractingprocess_id, date, clarificationmeetingid) values($1, $2, $3) returning id', [
                req.body.contractingprocess_id,
                req.body.date,
                `clarificationMeeting-${generateUUID()}`
            ])).id;
        }

        if(req.body.attenders){
            for(let i = 0, attender = {id: req.body.attenders[i]}; i < req.body.attenders.length; i++, attender = {id: req.body.attenders[i]}){
                attender.clarificationmeeting_id = req.body.id;
                await db_conf.edca_db.none('insert into clarificationmeetingactor(clarificationmeeting_id, parties_id, attender) values(${clarificationmeeting_id}, ${id}, true)',attender);
            }
        }

        if(req.body.officials){
            for(let i = 0, official = {id: req.body.officials[i]}; i < req.body.officials.length; i++, official = {id: req.body.officials[i]}){
                official.clarificationmeeting_id = req.body.id;
                await db_conf.edca_db.none('insert into clarificationmeetingactor(clarificationmeeting_id, parties_id, official) values(${clarificationmeeting_id}, ${id}, true)',official);
            }
        }

        updateHisitory(req.body.contractingprocess_id, req.user, Stages.tender, getHost(req));
        return res.json({message: 'Se ha registrado la junta de aclaración'});
    }catch(e){
        return res.status(400).json({message: 'No se ha podido registrar la junta'});
    }
});

// delete clarification meeting
router.post('/clarificationmeetings/:cp/:id/delete', isAuthenticated, async(req, res) => {
    try{
        await db_conf.edca_db.none('delete from clarificationmeeting where id = ${id} and contractingprocess_id = ${cp}', req.params);
        updateHisitory(req.params.cp, req.user, Stages.tender, getHost(req));
        return res.json({message: 'Se ha eliminado la junta de aclaración'});
    } catch(e) {
        return res.status(400).json({message: 'Error al eliminar la junta de aclaración'});
    }
});


// view memberof
router.get('/members/:actor', isAuthenticated, async (req, res) => {
    try{
        let members = await db_conf.edca_db.manyOrNone('select m.*, p.name, p.partyid from memberof m join parties p on p.id = m.parties_id  where principal_parties_id = ${actor} order by m.id', req.params);
        return res.render('modals/list-members', { members: members});
    }catch(e){
        console.log(e);
        return res.send('Error al cargar los miembros');
    }
});

// view fields memberof
router.get('/member/fields/:actor/:member?', isAuthenticated, async (req, res) => {
    try{
        let member = {
            id: undefined,
            memberofid: undefined,
            parties_id: undefined
        };
        if(req.params.member){
            member = await db_conf.edca_db.oneOrNone('select * from memberof where principal_parties_id = ${actor} and id = ${member} limit 1', req.params);
        }

        member.actores = await db_conf.edca_db.manyOrNone('select id, name, partyid from parties where contractingprocess_id  in (select contractingprocess_id from parties where id = ${actor})  and id != ${actor}', req.params);

        return res.render('modals/newmember', member);
    }
    catch(e){
        console.log(e);
        return res.send('Error al cargar el miembro');
    }
});

// create/update memberof
router.post('/member/fields/:actor', isAuthenticated, async (req, res) => {
    try{
        
        if(req.body.id) {
            db_conf.edca_db.none('update memberof set memberofid = ${memberofid}, parties_id = ${parties_id} where id = ${id}', req.body);
        } else {
            db_conf.edca_db.none('insert into memberof (memberofid, parties_id ,principal_parties_id) values (${memberofid}, ${parties_id}, ${actor})', {
                memberofid: req.body.memberofid,
                parties_id: req.body.parties_id,
                actor: req.params.actor
            });
        }
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from  parties where id = $1',[req.body.parties_id]);
        updateHisitory( cpid, req.user, Stages.planning, getHost(req));
        return res.json({message: 'Se ha guardado el miembro'});
    }
    catch(e){
        console.log(e);
        return res.status(400).json({message: 'No se ha podido registrar el miembro'})
    }
});

// delete memberof
router.post('/member/delete/:id', isAuthenticated, async (req, res) => {
    try{
        let {cpid} = await db_conf.edca_db.oneOrNone('select contractingprocess_id cpid from parties where id in (select parties_id from memberof where id = $1)', [req.params.id]);
        await db_conf.edca_db.none('delete from memberof where id = ${id}', req.params);
        updateHisitory(cpid , req.user, Stages.planning, getHost(req));
        return res.json({message: 'Se ha eliminado el miembro'});
    }catch(e){
        console.log(e);
        return res.status(400).json({message: 'No se ha podido eliminar el miembro'});
    }
});

let getHost = req => {
    return req.protocol + '://' + (req.headers != null && req.headers.host != null ? req.headers.host : (req.hostname || req.host));
}

// public version
router.get('/version/:version/:releasefile', async (req, res) => {
    try {
        let log = await db_conf.edca_db.one('select version_json from logs where version = $1 and release_file = $2 limit 1', [req.params.version, req.params.releasefile]);
        return res.json(log.version_json != null && log.version_json.compiledRelease != null ? log.version_json.compiledRelease : { message: 'No se han encontrado los cambios' });
    } catch(e) {
        console.log(e);
        return res.json({ message: 'No se han encontrado los cambios' });
    }
});

// public release
router.get('/release/:version/:releasefile', async (req, res) => {
    try{
        let log = await db_conf.edca_db.one('select release_json from logs where version = $1 and release_file = $2 limit 1',[req.params.version, req.params.releasefile]);
        return res.json(log.release_json || {message: 'No se ha encontrado el release'});
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el release'});
    }
});

// public package release
router.get('/release-package/:version/:releasefile', async (req, res) => {
    try{
        let release = require('../io/release')(db_conf.edca_db);
        return res.json(await release.getPackage(req.params.version, req.params.releasefile, getHost(req)));
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el release'});
    }
});

// last release
router.get('/release/:ocid', async (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(await getCpidFromOcid(req.params.ocid), getHost(req));

        let release = require('../io/release')(db_conf.edca_db);
        let log = await db_conf.edca_db.one('select release_json from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1)  order by id desc limit 1',[req.params.ocid]);
        return res.json(log.release_json || {message: 'No se ha encontrado el release'});
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el release'});
    }
});

// last package
router.get('/release-package/:ocid', async (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(await getCpidFromOcid(req.params.ocid), getHost(req));

        let release = require('../io/release')(db_conf.edca_db);
        let log = await db_conf.edca_db.one('select version, release_file from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1)  order by id desc limit 1',[req.params.ocid]);
        
        return res.json(await release.getPackage(log.version, log.release_file,  getHost(req)));
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el release'});
    }
});

// 
router.get('/release-package-all/:ocid', async (req, res) => {
    try{
        let release = require('../io/release')(db_conf.edca_db);
        return res.json(await release.getPackageAll(req.params.ocid,  getHost(req)));
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el release'});
    }
});

// view import contrating process
router.get('/main/:cpid/import/:stage?/:id?', isAuthenticated, (req, res) => {
    let texto = 'Entrega(Release)';
    switch(parseInt(req.params.stage)){
        case Stages.planning: texto = 'Planeación(Planning)'; break;
        case Stages.tender: texto = 'Licitación(Tender)'; break;
        case Stages.award: texto = 'Adjudicación(Award)'; break;
        case Stages.contract: texto = 'Contrato(Contract)'; break;
        case Stages.implementation: texto = 'Ejecución(Implementation)'; break;
    }
    res.render('modals/import-contractingprocess', {text: texto});
});

// import contracting process
router.post('/main/:cpid/import/:stage?/:id?',upload.single('datafile'), isAuthenticated, async (req, res) => {
    try{
        req.params.stage = req.params.stage === 'undefined' ? undefined : req.params.stage;
        req.params.id = req.params.id === 'undefined' ? undefined : req.params.id;
        const imports = require('../utilities/import')(req.params.cpid, db_conf.edca_db, req.params.stage, req.params.id);
        const fs = require('fs');
        let text = fs.readFileSync(req.file.path, {encoding: 'utf8'});
        let json;
       

        if(text){
            try{
                text = text.replace(/\s+/,'');
                json = JSON.parse(text);
            }catch(e){
                throw new Error(' No es un json valido');
            }
            await imports.importAll(json);

            updateHisitory(req.params.cpid, req.user, req.params.stage || Stages.planning);

        } else{
            throw new Error('El archivo esta vacio');
        }

        return res.send('Datos importados');
    }
    catch(e){
        console.log(e);
        return res.status(400).send('Error al importar.' + e.message)
    }finally{
        require('fs').unlinkSync(req.file.path);
    }
});

//Remueve información de una persona física en el record
let removeInfoSensible = record => {
    const jp = require('jsonpath');

    if(record) {
        jp.query(record.compiledRelease, '$.parties[?(@.identifier.juridicalPersonhood==="naturalPerson")]').map(actor => {
            if( !(  actor.roles.includes('official') ||
                    actor.roles.includes('supplier') ||
                    actor.roles.includes('issuingSupplier') ||
                    actor.roles.includes('tenderer')) 
            ) {
                delete actor.identifier;
                delete actor.id;
            }

            delete actor.address;
            delete actor.contactPoint;
        });
    }
    return record;
}

// descarga desde dashboard
router.get('/record-package/:ocid', async (req, res) => {
    try {
        let record = require('../io/record')(db_conf.edca_db);    
        await record.checkRecordIfExists(await getCpidFromOcid(req.params.ocid), getHost(req));
        let log = await db_conf.edca_db.oneOrNone(`select version,release_file from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1) order by id desc limit 1`, [req.params.ocid]);
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-disposition', `attachment;filename=record-package_${log.release_file.split('.').shift()}.json`);
        return res.json(await record.getPackage(log.version, log.release_file, getHost(req)));
    } catch(e) {
        console.log(e);
        return res.json({
            message: 'No se ha encontrado el record',
            error: e.message
        });
    }
});

// public record
router.get('/record/:version/:releasefile', async (req, res) => {
    try{
        let log = await db_conf.edca_db.one('select record_json from logs where version = $1 and release_file = $2 limit 1', [req.params.version, req.params.releasefile]);
        return res.json(log.record_json || { message: 'No se ha encontrado el record' });
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el record'});
    }
});



// public package record
router.get('/record-package/:version/:releasefile', async (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        return res.json(await record.getPackage(req.params.version, req.params.releasefile, getHost(req)));
    }catch(e){
        console.log(e);
        return res.json({message: 'No se ha encontrado el record'});
    }
});

// last record
router.get('/record/:ocid', async (req, res) => {
    try {
        let record = require('../io/record')(db_conf.edca_db);
        await record.checkRecordIfExists(await getCpidFromOcid(req.params.ocid), getHost(req));
        let log = await db_conf.edca_db.one(`select record_json from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1) order by id desc limit 1`, [req.params.ocid]);
        return res.json(log.record_json || { message: 'No se ha encontrado el record' });
    } catch(e) {
        console.log(e);
        return res.json({
            message: 'No se ha encontrado el record',
            error: e.message
        });
    }
});

let getCpidFromOcid = async ocid => {
    let {cpid} = await db_conf.edca_db.oneOrNone('select id cpid from contractingprocess where ocid = $1 limit 1',[ocid]);
    return cpid;
}

// package record
router.get('/record-package/:ocid', async (req, res) => { // ES AQUI NINA
    console.log("/record-package/ :ocid " + req.params.ocid);
    try {
        let record = require('../io/record')(db_conf.edca_db);    
        await record.checkRecordIfExists(await getCpidFromOcid(req.params.ocid), getHost(req));
        let log = await db_conf.edca_db.oneOrNone(`select version,release_file from logs where contractingprocess_id in (select id from contractingprocess where ocid = $1) order by id desc limit 1`, [req.params.ocid]);
        
        var recordPackage = await record.getPackage(log.version, log.release_file, getHost(req));
        console.log("/record-package/-RECORD " + JSON.stringify(recordPackage.records));

        return res.json(await record.getPackage(log.version, log.release_file, getHost(req)));
    } catch(e) {
        console.log(e);
        return res.json({
            message: 'No se ha encontrado el record',
            error: e.message
        });
    }
});

// view package record for period
router.get('/record-package-period-selector/:ocid', isAuthenticated, async  (req, res) => {
    let years = await db_conf.edca_db.manyOrNone("select distinct date_part('year', fecha_creacion) as year  from contractingprocess where fecha_creacion is not null order by date_part('year', fecha_creacion) desc");
    res.render('modals/record-package-selector', {years: years, ocid: req.params.ocid});
});

router.get('/record-package-period/:ocid/:mode/:value?', async (req, res) => {
    try{
        let record = require('../io/record')(db_conf.edca_db);
        return res.json(await record.getPackageForPeriod(req.params.ocid, req.params.mode, req.params.value || '', getHost(req)));
    }
    catch(e){
        console.log(e);
        return res.status(200).send({message: e.message});
    }
});

router.get('/pnt-status/:cpid', isAuthenticated, async (req, res) => {
    try{
        let result = await db_conf.edca_db.manyOrNone("select contractid, format, error, to_char(date, 'YYYY-MM-DD HH:MI:SS') as date from pntreference where contractingprocess_id = $1 and isroot = true order by contractid, format", [req.params.cpid]);
       
        result.map(pnt => {
            if(pnt.error){
                pnt.format = pnt.format === 4335 ? 
                'Resultados adjudicaciones, invitaciones y licitaciones_Procedimientos de adjudicación directa': 
                'Resultados adjudicaciones, invitaciones y licitaciones_Procedimientos de licitación pública e invitación a cuando menos tres personas';
                pnt.error = syntaxHighlight(JSON.stringify(JSON.parse(pnt.error), null, 4));
            }
        });

        return res.render('modals/pnt-status', {result: result});
    }
    catch(e){
        return res.send('<h3 class="text-center">No se ha generado la conexión al servicio PNT</h3>');
    }
});

let gdmxCatalog = {
    dictionary: { 
            A: 'document', 
            B: 'variable', 
            C: 'tablename', 
            D: 'field', 
            E: 'type', 
            F: 'index', 
            G: 'classification', 
            H: 'catalog', 
            I: 'catalog_field',
            J: 'parent',
            K: 'storeprocedure'
    },
    document: { 
        A: 'name', 
        B: 'stage', 
        C: 'type', 
        D: 'tablename', 
        E: 'identifier',
        F: 'title',
        G: 'description',
        H: 'format',
        I: 'language'
    },

};

let readJsonFromXLSX = async (req) => {
    let json;
    try {
        const fs = require('fs');

        const excelToJson = require('convert-excel-to-json');

        const result = excelToJson({
            sourceFile: req.file.path,
            header:{
                rows: 1
            },
            columnToKey: gdmxCatalog[req.params.type],
        });

        json = result[Object.keys(result)[0]];
    }
    catch (e) {

    }
    finally {
        require('fs').unlinkSync(req.file.path);
    }
    return json;
}

let updateGDMX = async (json, type) => {
    let result = {
        errors: [],
        total: json.length,
        registrados: 0,
        message: ''
    };

    let catalog = gdmxCatalog[type];
    let keys = Object.keys(catalog).map(x=> catalog[x]);

    let sql = `insert into gdmx_${type}(${keys.join(',')})
               values (${keys.map(x => '${' + x + '}').join(',')})`;

    await db_conf.edca_db.none(`delete from gdmx_${type}`);

    for(let i = 0; i < json.length; i++){
        try{
            // completar campos faltantes
            keys.map(x => json[i][x] = json[i][x]);

            await db_conf.edca_db.none(sql,json[i]);
            result.registrados++;
        }
        catch(e){
            result.errors.push(e.message);
        }
    }

    result.message = `Se han importado ${result.registrados} de ${result.total}`;

    return result;
}

router.post('/gdmx/:type', upload.single('datafile'), isAuthenticated, async (req, res) => {
    let json;
    try{
        json = await readJsonFromXLSX(req)
    }catch(e){
        console.log(e);
    }
    
    if(!json) return res.status(400).send('No se ha podido leer el archivo');

    let result = await updateGDMX(json, req.params.type);
   
    return res.status(200).json(result);
});

// enviar a pnt
router.post('/validate-process/pnt/:id', async (req, res) => {
    try{
        const pnt = require('../pnt/process-pnt');
        await pnt.send(req.params.id);
        return res.json(true);
    }
    catch(e) {
        return res.status(500).json( {message: e.message});
    }
});


// vista de configuracion de carpetas de gdmx
router.get('/gdmx-folders', async (req, res) => {

    const existe = await db_conf.edca_db.oneOrNone(`SELECT EXISTS 
    (
        SELECT 1 
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = 'gdmx_folders'
    )`);
    if (!existe.exists) {
        await db_conf.edca_db.none('CREATE TABLE gdmx_folders(id serial primary key, name text, active bool)');
    }


    return res.render('modals/gdmx-folders')
});

// listado de carpetas
router.get('/gdmx-folders/list', async (req,res) => {
    try{
        
        const results = await db_conf.edca_db.manyOrNone('SELECT * FROM gdmx_folders ORDER BY name desc');

        return res.json(results);
    }
    catch(e) {
        return res.json([]);
    }
    
});

// registrar/actualizar carpeta
router.post('/gdmx-folders', async (req, res) => {
    try{
        
        const existe = await db_conf.edca_db.oneOrNone('SELECT * FROM gdmx_folders WHERE name like ${name} AND (${id} IS NULL OR id != ${id})', {
            name: req.body.name,
            id: req.body.id || 0
        });
        if (existe) {
            return res.json('Ya existe una carpeta con la misma ruta');
        }

        if(!req.body.id) {
            await db_conf.edca_db.none('INSERT INTO gdmx_folders(name, active) VALUES(${name}, true)', req.body);
        } else {
            await db_conf.edca_db.none('UPDATE gdmx_folders SET name = ${name}, active = ${active} WHERE id = ${id}', req.body);
        }

        return res.json(true);
    }
    catch(e) {
        return res.json(e.message);
    }
    
});

// eliminar carpeta
router.post('/gdmx-folders/:id/delete', async (req, res) => {
    try{
        
        await db_conf.edca_db.none('DELETE FROM gdmx_folders WHERE id = ${id}', req.params);

        return res.json(true);
    }
    catch(e) {
        return res.json(false);
    }
});


// actualizar estatus al subir documento

// *** I N F R A E R S T R U C T U R A *** 
// RUTAS
router.post('/new-project', isAuthenticated, async function (req, res) {
    try {
        if(req.user.publisherName !== '' || req.user.isAdmin){
            const allMetadata = await db_conf.edca_db.manyOrNone('select * from metadata');
            var publisher = project.createPublisher(req.user);
            var projectPackage = project.createProjectPackage(allMetadata);
            var projectEdcapi = project.createProject();
            
            Promise.all([publisher, projectPackage, projectEdcapi]).then(values => { 
                project.createPublisherProjectPackage(values[0].id,values[1].id).then(function(){
                    return project.createProjectPackageProject(values[2].id,values[1].id,getHost(req));
                }).catch(function(err){console.log("ERROR - " + err)});
                    res.json( { url: `/project/${values[2].id}` } );
                }, reason => {
                    console.log("/new-project REASON " + reason)
                });
        }else{
            res.json( { url: `/main/` } );
        }    
    } catch (error) {
        console.log("ERROR al construir un nuevo proyecto: " + error);
    }
    
});
//#region [Llenado de catalogos para creacion de projecto] 
router.get('/project/:projectEdcapiId', isAuthenticated, async (req, res) => {
    console.log("'/project/:projectEdcapiId'")
    var prefijo;
    project.generateOc4ids().then(async function(value){
        prefijo = value[0].prefix;
    });
    
    var projectID = req.params.projectEdcapiId;
    try {
        var status = await db.edcapi_project_status.findAll({ attributes: ['code','title']});
        var project_type = await db.edcapi_project_type.findAll({ attributes: ['code','title']});
        var sector = await db.edcapi_project_sector.findAll({ attributes: ['code','title']});
        var currency = await db_conf.edca_db.manyOrNone("select distinct currency, alphabetic_code from currency order by currency");
        project.findProject(projectID).then(value => {
            if(value[0] === undefined){
                res.redirect(`/main/`);
            }else{
                var objCompletion = new Object();
                //console.log("/project/ findProject " + JSON.stringify(value,null,4))
                if(value[0].projects[0].completion.length < 1){
                    objCompletion.endDate = null;
                    objCompletion.endDateDetails = null;
                    objCompletion.amount = null;
                    objCompletion.currency = null;
                    objCompletion.finalValueDetails = null;
                    objCompletion.finalScope = null;
                    objCompletion.finalScopeDetails = null;
                }else{
                    objCompletion.endDate = value[0].projects[0].completion[0].endDate;
                    objCompletion.endDateDetails = value[0].projects[0].completion[0].endDateDetails;
                    objCompletion.amount = value[0].projects[0].completion[0].amount;
                    objCompletion.currency = value[0].projects[0].completion[0].currency;
                    objCompletion.finalValueDetails = value[0].projects[0].completion[0].finalValueDetails;
                    objCompletion.finalScope = value[0].projects[0].completion[0].finalScope;
                    objCompletion.finalScopeDetails = value[0].projects[0].completion[0].finalScopeDetails;
                }
                var contractingProcesses = new Array();
                if(value[0].projects[0].contractingProcesses.length < 1){
                    contractingProcesses = null;
                }else{
                    contractingProcesses = value[0].projects[0].contractingProcesses;
                }
                res.render('project', {
                    projectId: projectID,
                    user: req.user,
                    currencies: currency,
                    statuses: status,
                    types: project_type,
                    sectors: sector,
                    relatedContractingProcesses : contractingProcesses,
                    prefix: ((value[0].projects[0].oc4ids === null ? prefijo : value[0].projects[0].oc4ids)  + "-" + (value[0].projects[0].identifier === null ? '' :value[0].projects[0].identifier)),
                    identifier : (value[0].projects[0].identifier === null ? '' :value[0].projects[0].identifier),
                    title : (value[0].projects[0].title === null ? '' :value[0].projects[0].title),
                    descriptionB : (value[0].projects[0].description === null ? '' :value[0].projects[0].description),
                    startDate : (value[0].projects[0].period[0] === undefined ? '' :value[0].projects[0].period[0].startDate),
                    endDate : (value[0].projects[0].period[0] === undefined ? '' :value[0].projects[0].period[0].endDate),
                    maxExtentDate : (value[0].projects[0].period[0] === undefined ? '' :value[0].projects[0].period[0].maxExtentDate),
                    durationInDays : (value[0].projects[0].period[0] === undefined ? '' :value[0].projects[0].period[0].durationInDays),
                    purposeB : (value[0].projects[0].purpose === null ? '' :value[0].projects[0].purpose),
                    startDateAssetLifeTime : (value[0].projects[0].assetLifetime[0] === undefined ? '' :value[0].projects[0].assetLifetime[0].startDate),
                    endDateAssetLifeTime : (value[0].projects[0].assetLifetime[0] === undefined ? '' :value[0].projects[0].assetLifetime[0].endDate),
                    maxExtentDateAssetLifeTime : (value[0].projects[0].assetLifetime[0] === undefined ? '' :value[0].projects[0].assetLifetime[0].maxExtentDate),
                    durationInDaysAssetLifeTime : (value[0].projects[0].assetLifetime[0] === undefined ? '' :value[0].projects[0].assetLifetime[0].durationInDays),
                    requestDate : (value[0].projects[0].budget[0] === undefined ? '' :value[0].projects[0].budget[0].requestDate),
                    approvalDate : (value[0].projects[0].budget[0] === undefined ? '' :value[0].projects[0].budget[0].approvalDate),
                    amount : (value[0].projects[0].budget[0] === undefined ? '' :value[0].projects[0].budget[0].amount[0].amount),
                    currency : (value[0].projects[0].budget[0] === undefined ? '' :value[0].projects[0].budget[0].amount[0].currency),
                    status : (value[0].projects[0].status === null ? '' :value[0].projects[0].status),
                    sector : (value[0].projects[0].sector === null ? '' :value[0].projects[0].sector),
                    type : (value[0].projects[0].type === null ? '' :value[0].projects[0].type),
                    is_update : (value[0].projects[0].title === null ? false : true),
                    completion_is_update : (objCompletion.endDate === null ? false : true),
                    completion_endDate : (objCompletion.endDate === null ? '' : objCompletion.endDate),
                    completion_endDateDetails : (objCompletion.endDateDetails === null ? '' : objCompletion.endDateDetails),
                    completion_amount : (objCompletion.amount === null ? '' : objCompletion.amount),
                    completion_currency : (objCompletion.currency === null ? '' : objCompletion.currency),
                    completion_finalValueDetails : (objCompletion.finalValueDetails === null ? '' : objCompletion.finalValueDetails),
                    completion_finalScope : (objCompletion.finalScope === null ? '' : objCompletion.finalScope),
                    completion_finalScopeDetails : (objCompletion.finalScopeDetails === null ? '' : objCompletion.finalScopeDetails)
                });    
            }
        });
        
    } catch (error) {
        console.log("ERROR al consultar informacion referente al proyecto: " + error);
    }
});
//#endregion

//project 
router.post('/project/',isAuthenticated, async (req, res) => {
    console.log("######### /project/ BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    var form = JSON.parse(request);

    function update(value){
        return new Promise(function (fulfill, reject){
            setTimeout(function() {
                fulfill(project.updateProject(value));
            }, 0 | Math.random() * 100);
        });
    }
    
    if(form.is_update === 'true'){
        console.log('············ Es actualización de un proyecto existente')
        update(request).then(function(){
            return res.redirect(`/project/${form.project_id}`);
        }).then(function(){
            project.updatePublishedDate(req.body.project_id,req.user);
        }).catch(async function(err){console.log("ERROR Update /project/ - " + err)});
    }else{
        console.log('············ Es nuevo proyecto')
        await project.insertProject(request).then(async function(){
            res.redirect(`/project/${form.project_id}`);
        }).then(function(){
            project.updatePublishedDate(req.body.project_id,req.user);
        }).catch(async function(err){console.log("ERROR Create /project/ - " + err)});
    }
    
}),
//project 
router.post('/completion_project/',isAuthenticated, async (req, res) => {
    console.log("######### /completion_project/ BODY " + JSON.stringify(req.body, null, 4))
    var request = JSON.stringify(req.body); 
    var form = JSON.parse(request);
    
    if(form.completion_is_update === 'true'){
        console.log('············ Es actualización de un proyecto COMPLETO existente')
        project.updateCompletionProject(request).then(function(){
            res.redirect(`/project/${form.project_id}`);
        }).then(function(){
            project.updatePublishedDate(req.body.project_id,req.user);
        }).catch(function(err){console.log("ERROR Update /completion_project/ - " + err)});
    }else{
        console.log('············ Es nuevo proyecto COMPLETO')
        project.insertCompletionProject(request).then(function(){
            res.redirect(`/project/${form.project_id}`);
        }).then(function(){
            project.updatePublishedDate(req.body.project_id,req.user);
        }).catch(function(err){console.log("ERROR Create /completion_project/ - " + err)});
    }
}),

router.post('/validate-project-amount/',isAuthenticated, async (req, res) => {
    project.findProject(req.body.project_id).then(value =>{
        var existAmount = false;
        var existParties = false;

        if (value[0].projects[0].budget.length > 0){
            if (value[0].projects[0].budget[0].amount[0].amount !== null)
            existAmount = true;
        }
        if (value[0].projects[0].parties.length > 0) {
            value[0].projects[0].parties.forEach(element => {
                if (element.roles[0].funder === 'on')
                existParties = true;    
            });
        }
        if(existAmount && existParties){
            res.json({
                status: 'Ok',
                message: 'Si existe monto relacionado al proyecto.'
            });
        } else if(existAmount === true  && existParties === false) {
            res.json({
                status: 'Error1',
                message: 'Debe registrar la información solicitada en la sección Actores involucrados del proyecto con el rol de financiador antes de realizar un registro en el formulario de Desglose del presupuesto.'
            });
        } else if(existAmount === false  && existParties === true){
            res.json({
                status: 'Error',
                message: 'Debe registrar la información solicitada en la sección Valor total del proyecto antes de realizar un registro en el formulario de Desglose del presupuesto.'
            });
        } else {
            res.json({
                status: 'Error',
                message: 'Debe registrar la información solicitada en la sección Valor total del proyecto antes de realizar un registro en el formulario de Desglose del presupuesto.'
            });
        }          
    }).catch(function(err){
            console.log("ERROR /validate-project-amount/ - " + err)
    });    
});


// API METHODS FOR EDCAPI 
router.get('/edcapi/projectPackage/:id', function(req, res){
    project.findRelatedContractingProcess(req.params.id).then(function(ocids){
        return project.generateRecordPackage(ocids, getHost(req));
    }).then(function(RecordPackages){
        var arrayContractingProcesses = new Array(); 
        RecordPackages.forEach(element => {
            var objContractingProcess  = new Object();
            var arrayReleases  = new Array();
            arrayReleases.push(element.releases)
            objContractingProcess.id = element.id.id;
            objContractingProcess.releases = arrayReleases;
            arrayContractingProcesses.push(objContractingProcess);
        });
        return project.imprimeProjectPackage(req.params.id, arrayContractingProcesses, true);
    }).then(function(projectPackage){
        return res.json(projectPackage)    
    }).catch(function(err){
        console.log("ERROR /edcapi/project/:id - " + err)
    });
});

router.get('/edcapi/project/:id', function(req, res){
    project.findRelatedContractingProcess(req.params.id).then(function(ocids){
        return project.generateRecordPackage(ocids, getHost(req));
    }).then(function(RecordPackages){
        console.log("### RecordPackages " + JSON.stringify(RecordPackages))
        var arrayContractingProcesses = new Array(); 
        RecordPackages.forEach(element => {
            var objContractingProcess  = new Object();
            var arrayReleases  = new Array();
            arrayReleases.push(element.releases)
            objContractingProcess.id = element.id.id;
            objContractingProcess.releases = arrayReleases;
            arrayContractingProcesses.push(objContractingProcess);
        });
        return project.imprimeProjectPackage(req.params.id, arrayContractingProcesses,false);
    }).then(function(projectPackage){
        console.log("### projectPackage " + JSON.stringify(projectPackage))
        if(Object.entries(projectPackage).length === 0){
            return res.status(404).send();
        }else{
            return res.json(projectPackage)    
        }
    }).catch(function(err){
        console.log("ERROR /edcapi/project/:id - " + err)
        return res.status(404).send();
    });
});

router.get('/edcapi/project/', function(req, res){
    var projectPackages = new Array();
    project.findProjectsAPI().then(projects =>{
        projects.forEach(element => {
            project.findRelatedContractingProcess(element.projects[0].id,getHost(req)).then(function(ocids){
                if(ocids !== false){
                    return project.generateRecordPackage(ocids, getHost(req));
                }else{
                    return false;
                }
            }).then(function(RecordPackages){
                var objProject = null;
                if(RecordPackages !== false){
                    objProject = project.imprimeProjectPackage(element.projects[0].id, RecordPackages,true);
                }else{
                    objProject = project.imprimeProjectPackage(element.projects[0].id, new Array(),true);
                }
                return objProject
            }).then(function(projectPackage){
                projectPackages.push(projectPackage)
                return projectPackages;    
            });
        });
        return projectPackages;
    }).then(value =>{
        return new Promise(resolve => {
            setTimeout(() => {
                resolve(res.json(value));
            }, 1500);
        });
    });
});


router.get('/edcapi/projectpackage/:id', function(req, res){
    console.log("························· /edcapi/projectpackage/:id PARAMS "  + JSON.stringify(req.params));
    console.log("························· /edcapi/projectpackage/:id HOST "  + getHost(req));
    var id = req.params.id;
    console.log("························· "  + id);
    project.findProjectAPI(id).then((project) => {
        res.json(project)
    });
});

router.get('/edcapi/projectpackage', function(req, res){
    project.findProjectsAPI().then((project) => {
        res.json(project)
    });
});

router.get('/edca/contractingprocess/procurementmethod/:procurementmethod/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/procurementmethod/:procurementmethod PARAMS "  + JSON.stringify(req.params));
    cp_functions.getProcurementMethod(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/contractingprocess/additionalprocurementcategories/:additionalprocurementcategories/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/additionalprocurementcategories/:additionalprocurementcategories PARAMS "  + JSON.stringify(req.params));
    cp_functions.getAdditionalProcurementCategories(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/contractingprocess/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/:year PARAMS "  + JSON.stringify(req.params));
    cp_functions.getContractingProcess(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/cp/:id',async function(req, res){
    console.log("························· /edca/contractingprocess/:id PARAMS "  + JSON.stringify(req.params));
    cp_functions.getOneContractingProcess(req.params, getHost(req), res).then(arrayReleasePackage => {
        console.log("arrayReleasePackage "  + JSON.stringify(arrayReleasePackage, null, 2));
        
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/contractingprocess/csv/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/csv/:year PARAMS "  + JSON.stringify(req.params));
    cp_functions.getContractingProcess(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/contractingprocess/additionalprocurementcategories/csv/:additionalprocurementcategories/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/additionalprocurementcategories/csv/:additionalprocurementcategories/:year PARAMS "  + JSON.stringify(req.params));
    cp_functions.getAdditionalProcurementCategories(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/edca/contractingprocess/procurementmethod/csv/:procurementmethod/:year',async function(req, res){
    console.log("························· /edca/contractingprocess/procurementmethod/csv/:procurementmethod/:year PARAMS "  + JSON.stringify(req.params));
    cp_functions.getProcurementMethod(req.params, getHost(req), res).then(arrayReleasePackage => {
        if(arrayReleasePackage){
            return res.status(200).json({arrayReleasePackage});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
    })
});

router.get('/generate/releases',async function(req, res){
    console.log("························· /generate-releases/ "  + JSON.stringify(req.user));
    cp_functions.getAllIdContractingProcess().then(async arrayReleasePackage => {
        var totalRegistros = arrayReleasePackage.length;
        var contador = 0;
        var done = false;
        if(arrayReleasePackage){
            arrayReleasePackage.forEach(element => {
                id_cp = element.contractingprocess_id;
                var publisher = new Object({
                    _id : element.publisher,
                    publisherName : element.name,
                    publisherScheme : element.scheme,
                    publisherUid : element.uid,
                    publisherUri : element.uri
                })
                validatedAll(id_cp, publisher, 1, getHost(req));
                contador++;
                if(contador == totalRegistros)
                done = true;
            });
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
        if(done)
        return res.json({status: 200,message: 'Procesos validados'});
    })

    
});
router.get('/generate/publishes',async function(req, res){
    console.log("························· /generate-releases/ "  + JSON.stringify(req.user));
    cp_functions.getAllIdContractingProcess().then(async arrayReleasePackage => {
        var totalRegistros = arrayReleasePackage.length;
        var contador = 0;
        var done = false;
        if(arrayReleasePackage){
            arrayReleasePackage.forEach(element => {
                id_cp = element.contractingprocess_id;
                var publisher = new Object({
                    _id : element.publisher,
                    publisherName : element.name,
                    publisherScheme : element.scheme,
                    publisherUid : element.uid,
                    publisherUri : element.uri
                })
                publishedAll(id_cp, publisher, getHost(req));
                sendToPNT(id_cp);
                contador++;
                if(contador == totalRegistros)
                done = true;
            });
            await require('../utilities/export2Dashboard')(id_cp);
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón resultados con el parámetro seleccionado.`
            }
        )}
        if(done)
        return res.json({status: 200,message: 'Procesos publicados'});
    })
});

router.get('/edca/fiscalYears',async function(req, res){
    console.log("························· /edca/fiscalYears ");
    cp_functions.getFiscalYears().then(fiscalYears =>{
        if(fiscalYears){
            console.log(`RES ${JSON.stringify(fiscalYears)}`)
            return res.status(200).json({fiscalYears});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón registros.`
            }
        )}
    });
});

router.get('/edca/policy', async (req,res) => {
    cp_functions.getPolicy().then(function(value){
        if(value){
            console.log(`RES ${JSON.stringify(value[0])}`)
            var policy = value[0].policy;
            return res.status(200).json({policy});
        }else{
            return res.status(404).json({
                status: 404,
                message: `No se encontrarón registros.`
            }
        )}
    })
});

router.get('/edca/amounts/',async function(req, res){
    console.log("························· /edca/amounts/ "  + JSON.stringify(req.params));
    db_conf.edca_db.task(function (t) {
        return this.batch([
            this.one('select count(*) as total from (select distinct partyid from contractingprocess, contract, parties, roles where contract.contractingprocess_id = contractingprocess.id and parties.contractingprocess_id = contractingprocess.id and parties.id = roles.parties_id and roles.supplier = true) as t;'), 
            this.one('select count(*) as total from (select distinct contractingprocess.id from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id) t'),
            this.one('select count(*) as total from contractingprocess, contract where contractingprocess.id = contract.contractingprocess_id and contract.exchangerate_amount > 0' ),
            this.one('select sum((select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id)) as total from contractingprocess where 1 = 1' ),
            this.manyOrNone(`select t.procurementmethod_details, count(*) as conteo, sum(t.total) as total
                from (select tender.procurementmethod_details,
                    (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as total
                    from contractingprocess
                    inner join tender on tender.contractingprocess_id = contractingprocess.id
                    where tender.procurementmethod_details is not null and tender.procurementmethod_details != '') as t 
                group by t.procurementmethod_details order by total desc`),
            this.manyOrNone(`select t.additionalprocurementcategories, count(*) as conteo, sum(t.total) as total
                from (select tender.additionalprocurementcategories,
                    (select sum(exchangerate_amount) from contract where contractingprocess_id = contractingprocess.id) as total
                    from contractingprocess
                    inner join tender on tender.contractingprocess_id = contractingprocess.id
                    where tender.additionalprocurementcategories is not null and tender.additionalprocurementcategories != '') as t 
                group by t.additionalprocurementcategories order by total desc`)
        ]);
    }).then(function (data) {
        var amount = new Object();
        amount.supplier_count= +data[0].total;
        amount.cp_count= +data[1].total;
        amount.contract_count= +data[2].total;
        amount.contract_exchangerate_amount_total= data[3].total;
        amount.total_procedimiento= data[4];
        amount.total_destino= data[5];
        return res.status(200).json({amount});
    }).catch(function (error) {
        console.log("ERROR: ", error);
        return res.status(404).json({
            status: 404,
            message: `No se encontrarón resultados con el parámetro seleccionado.`
        })
    });

});

module.exports = router;