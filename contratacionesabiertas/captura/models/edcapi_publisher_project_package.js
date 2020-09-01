'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_publisher_project_package = sequelize.define('edcapi_publisher_project_package', {
    edcapiPublisherId: DataTypes.INTEGER,
    project_package_id: DataTypes.INTEGER
  }, {});
  edcapi_publisher_project_package.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_publisher_project_package;
};