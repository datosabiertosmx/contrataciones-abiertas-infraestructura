'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_budget_breakdown_budget_lines_measure = sequelize.define('edcapi_project_budget_breakdown_budget_lines_measure', {
    type: DataTypes.STRING,
    amount: DataTypes.INTEGER,
    currency: DataTypes.STRING,
    date: DataTypes.STRING
  }, {});
  edcapi_project_budget_breakdown_budget_lines_measure.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_budget_breakdown_budget_lines_measure;
};