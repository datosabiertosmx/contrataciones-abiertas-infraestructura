'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_completion_project = sequelize.define('edcapi_project_completion_project', {
    edcapiProjectCompletionId: DataTypes.INTEGER,
    project_id: DataTypes.INTEGER
  }, {});
  edcapi_project_completion_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_completion_project;
};