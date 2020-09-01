'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_additional_classification_project = sequelize.define('edcapi_project_additional_classification_project', {
    edcapiProjectAdditionalClassificationId: DataTypes.INTEGER,
    project_id: DataTypes.INTEGER
  }, {});
  edcapi_project_additional_classification_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_additional_classification_project;
};