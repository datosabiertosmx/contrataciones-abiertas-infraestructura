'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_package = sequelize.define('edcapi_project_package', {
    uri: DataTypes.STRING,
    publishedDate: DataTypes.STRING,
    version: DataTypes.STRING,
    license: DataTypes.STRING,
    publicationPolicy: DataTypes.STRING
  }, {});
  edcapi_project_package.associate = function(models) {
    // associations can be defined here
    edcapi_project_package.belongsToMany(models.edcapi_publisher, {
      through: 'edcapi_publisher_project_packages',
      as: 'publisher',
      foreignKey: 'project_package_id'
    }),
    edcapi_project_package.belongsToMany(models.edcapi_project, {
      through: 'edcapi_project_package_projects',
      as: 'projects',
      foreignKey: 'project_package_id'
    })
  };
  return edcapi_project_package;
};