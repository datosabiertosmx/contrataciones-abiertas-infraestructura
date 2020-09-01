'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_additional_classification = sequelize.define('edcapi_project_additional_classification', {
    schema: DataTypes.STRING,
    identifier: DataTypes.STRING,
    description: DataTypes.STRING
  }, {});
  edcapi_project_additional_classification.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_additional_classification;
};