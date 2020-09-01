'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_status = sequelize.define('edcapi_project_status', {
    code: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING(900)
  }, {});
  edcapi_project_status.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_status;
};