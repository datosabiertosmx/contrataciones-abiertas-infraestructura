'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_budget_project = sequelize.define('edcapi_budget_project', {
    project_id: DataTypes.INTEGER,
    edcapiBudgetId: DataTypes.INTEGER
  }, {});
  edcapi_budget_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_budget_project;
};