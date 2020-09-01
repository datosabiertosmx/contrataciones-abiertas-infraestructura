'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_budget_amount_budget = sequelize.define('edcapi_budget_amount_budget', {
    budget_id: DataTypes.INTEGER,
    edcapiBudgetAmountId: DataTypes.INTEGER
  }, {});
  edcapi_budget_amount_budget.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_budget_amount_budget;
};