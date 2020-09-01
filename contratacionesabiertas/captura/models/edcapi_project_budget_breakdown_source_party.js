'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_source_party = sequelize.define('edcapi_project_budget_breakdown_source_party', {
    relation_id: DataTypes.INTEGER,
    relation_identifier: DataTypes.STRING,
    project_id: DataTypes.INTEGER,
    name: DataTypes.STRING
  }, {});
  edcapi_project_budget_breakdown_source_party.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_source_party;
};