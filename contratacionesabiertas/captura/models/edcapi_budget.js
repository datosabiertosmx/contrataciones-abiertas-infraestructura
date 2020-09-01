'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_budget = sequelize.define('edcapi_budget', {
    requestDate: DataTypes.STRING,
    approvalDate: DataTypes.STRING
  }, {});
  edcapi_budget.associate = function(models) {
    // associations can be defined here
    edcapi_budget.belongsToMany(models.edcapi_budget_amount, {
      through: 'edcapi_budget_amount_budgets',
      as: 'amount',
      foreignKey: 'budget_id',
    }),
    edcapi_budget.belongsToMany(models.edcapi_project_budget_breakdown, {
      through: 'edcapi_project_budget_breakdown_budgets',
      as: 'budgetBreakdown',
      foreignKey: 'budget_id',
    })
  };
  return edcapi_budget;
};