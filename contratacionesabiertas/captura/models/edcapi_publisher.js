'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_publisher = sequelize.define('edcapi_publisher', {
    name: DataTypes.STRING,
    scheme: DataTypes.STRING,
    uid: DataTypes.STRING,
    uri: DataTypes.STRING(500)
  }, {});
  edcapi_publisher.associate = function(models) {
    // associations can be defined here
    edcapi_publisher.belongsToMany(models.edcapi_project_package,{
      through: 'edcapi_publisher_project_packages',
      as: 'paquetes',
      foreingKey: 'edcapiPublisherId',
    })
  };
  return edcapi_publisher;
};