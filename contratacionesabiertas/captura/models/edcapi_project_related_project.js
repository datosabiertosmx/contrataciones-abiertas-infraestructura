'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_related_project = sequelize.define('edcapi_project_related_project', {
    relationship: DataTypes.STRING,
    title: DataTypes.STRING,
    scheme: DataTypes.STRING,
    identifier: DataTypes.STRING,
    uri: DataTypes.STRING
  }, {});
  edcapi_project_related_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_related_project;
};