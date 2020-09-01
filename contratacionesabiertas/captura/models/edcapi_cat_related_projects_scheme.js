'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_cat_related_projects_scheme = sequelize.define('edcapi_cat_related_projects_scheme', {
    code: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING(900)
  }, {});
  edcapi_cat_related_projects_scheme.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_cat_related_projects_scheme;
};