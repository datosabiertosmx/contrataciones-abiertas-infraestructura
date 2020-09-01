'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_parties_identifier_project = sequelize.define('edcapi_project_parties_identifier_project', {
    edcapiProjectPartiesIdentifierId: DataTypes.INTEGER,
    party_id: DataTypes.INTEGER
  }, {});
  edcapi_project_parties_identifier_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_parties_identifier_project;
};