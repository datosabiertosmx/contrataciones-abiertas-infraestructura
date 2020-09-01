'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_budget_line = sequelize.define('edcapi_project_budget_breakdown_budget_line', {}, {});
  edcapi_project_budget_breakdown_budget_line.associate = function(models) {
    // associations can be defined here
    edcapi_project_budget_breakdown_budget_line.belongsToMany(models.edcapi_project_budget_breakdown_budget_lines_component, {
      through: 'edcapi_project_budget_breakdown_budget_lines_component_budgets',
      as: 'c',
      foreignKey: 'edcapiProjectBudgetBreakdownBudgetLineId',
    }),
    edcapi_project_budget_breakdown_budget_line.belongsToMany(models.edcapi_project_budget_breakdown_budget_lines_measure, {
      through: 'edcapi_project_budget_breakdown_budget_lines_measure_budgets',
      as: 'measures',
      foreignKey: 'edcapiProjectBudgetBreakdownBudgetLineId',
    })
  };
  return edcapi_project_budget_breakdown_budget_line;
};