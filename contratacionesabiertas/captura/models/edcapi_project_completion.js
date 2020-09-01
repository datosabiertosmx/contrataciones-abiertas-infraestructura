'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_completion = sequelize.define('edcapi_project_completion', {
    endDate: DataTypes.STRING,
    endDateDetails: DataTypes.STRING,
    amount: DataTypes.INTEGER,
    currency: DataTypes.STRING,
    finalValueDetails: DataTypes.STRING,
    finalScope: DataTypes.STRING,
    finalScopeDetails: DataTypes.STRING
  }, {});
  edcapi_project_completion.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_completion;
};