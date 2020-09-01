'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_period_project = sequelize.define('edcapi_project_period_project', {
    project_id: DataTypes.INTEGER,
    project_period_id: DataTypes.INTEGER
  }, {});
  edcapi_project_period_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_period_project;
};