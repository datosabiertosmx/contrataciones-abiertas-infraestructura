'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_budget = sequelize.define('edcapi_project_budget_breakdown_budget', {
    edcapiProjectBudgetBreakdownId: DataTypes.INTEGER,
    budget_id: DataTypes.INTEGER
  }, {});
  edcapi_project_budget_breakdown_budget.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_budget;
};