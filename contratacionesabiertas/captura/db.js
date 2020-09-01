var linkedStorage = (process.env.MONGODB_PORT_27017_TCP_ADDR || 'localhost' )
linkedStorage += ':' + (process.env.MONGODB_PORT_27017_TCP_PORT || '27017' )
module.exports = {
    'url' : 'mongodb://' + linkedStorage + '/passport'
}
