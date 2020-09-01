var mongoose = require('mongoose');

const shema = mongoose.model('User',{
    name: String,
    lastname: String,
    username: String,
    password: String,
    email: String,
    address: String,
    isAdmin: Boolean,
    publisherName: String,
    publisherScheme: String,
    publisherUid: String,
    publisherUri: String,
    modificaEstatus: Boolean,
    isActive: Boolean
});

module.exports = shema;

