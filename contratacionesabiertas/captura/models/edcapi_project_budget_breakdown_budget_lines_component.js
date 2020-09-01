'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_budget_lines_component = sequelize.define('edcapi_project_budget_breakdown_budget_lines_component', {
    year: DataTypes.INTEGER,
    branch: DataTypes.STRING,
    kBranch: DataTypes.STRING,
    responsibleUnit: DataTypes.STRING,
    kResponsibleUnit: DataTypes.STRING,
    finality: DataTypes.STRING,
    kFinality: DataTypes.STRING,
    function: DataTypes.STRING,
    kFunction: DataTypes.STRING,
    subFunction: DataTypes.STRING,
    kSubFunction: DataTypes.STRING,
    instAct: DataTypes.STRING,
    kInstAct: DataTypes.STRING,
    budgetProgram: DataTypes.STRING,
    kBudgetProgram: DataTypes.STRING,
    spendingObject: DataTypes.STRING,
    kSpendingObject: DataTypes.STRING,
    spendingType: DataTypes.STRING,
    kSpendingType: DataTypes.STRING,
    budgetSource: DataTypes.STRING,
    kBudgetSource: DataTypes.STRING,
    region: DataTypes.STRING,
    kRegion: DataTypes.STRING,
    portfolio: DataTypes.STRING,
    kPortfolio: DataTypes.STRING
  }, {});
  edcapi_project_budget_breakdown_budget_lines_component.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_budget_lines_component;
};