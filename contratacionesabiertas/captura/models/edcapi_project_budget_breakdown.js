'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown = sequelize.define('edcapi_project_budget_breakdown', {
    description: DataTypes.STRING,
    amount: DataTypes.INTEGER,
    currency: DataTypes.STRING,
    uri: DataTypes.STRING,
    startDate: DataTypes.STRING,
    endDate: DataTypes.STRING,
    maxExtentDate: DataTypes.STRING,
    durationInDays: DataTypes.INTEGER
  }, {});
  edcapi_project_budget_breakdown.associate = function(models) {
    // associations can be defined here
    edcapi_project_budget_breakdown.belongsToMany(models.edcapi_project_budget_breakdown_source_party, {
      through: 'edcapi_project_budget_breakdown_source_party_budgets',
      as: 'sourceParty',
      foreignKey: 'edcapiProjectBudgetBreakdownId',
    }),
    edcapi_project_budget_breakdown.belongsToMany(models.edcapi_project_budget_breakdown_budget_line, {
      through: 'edcapi_project_budget_breakdown_budget_line_budgets',
      as: 'budgetLines',
      foreignKey: 'edcapiProjectBudgetBreakdownId',
    })
  };
  return edcapi_project_budget_breakdown;
};