'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_parties_contact_point = sequelize.define('edcapi_project_parties_contact_point', {
    name: DataTypes.STRING,
    email: DataTypes.STRING,
    telephone: DataTypes.STRING,
    faxNumber: DataTypes.STRING,
    url: DataTypes.STRING
  }, {});
  edcapi_project_parties_contact_point.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_parties_contact_point;
};