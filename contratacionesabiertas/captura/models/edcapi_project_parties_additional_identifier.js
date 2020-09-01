'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_parties_additional_identifier = sequelize.define('edcapi_project_parties_additional_identifier', {
    scheme: DataTypes.STRING,
    identifier: DataTypes.STRING,
    legalName: DataTypes.STRING,
    uri: DataTypes.STRING
  }, {});
  edcapi_project_parties_additional_identifier.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_parties_additional_identifier;
};