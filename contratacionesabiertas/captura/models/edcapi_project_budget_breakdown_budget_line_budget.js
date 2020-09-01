'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_budget_line_budget = sequelize.define('edcapi_project_budget_breakdown_budget_line_budget', {
    edcapiProjectBudgetBreakdownBudgetLineId: DataTypes.INTEGER,
    edcapiProjectBudgetBreakdownId: DataTypes.INTEGER
  }, {});
  edcapi_project_budget_breakdown_budget_line_budget.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_budget_line_budget;
};