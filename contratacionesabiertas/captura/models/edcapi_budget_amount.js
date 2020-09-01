'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_budget_amount = sequelize.define('edcapi_budget_amount', {
    amount: DataTypes.STRING,
    currency: DataTypes.STRING
  }, {});
  edcapi_budget_amount.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_budget_amount;
};