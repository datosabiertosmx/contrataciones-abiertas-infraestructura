'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_source_party_budget = sequelize.define('edcapi_project_budget_breakdown_source_party_budget', {
    edcapiProjectBudgetBreakdownSourcePartyId: DataTypes.INTEGER,
    edcapiProjectBudgetBreakdownId: DataTypes.INTEGER
  }, {});
  edcapi_project_budget_breakdown_source_party_budget.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_source_party_budget;
};