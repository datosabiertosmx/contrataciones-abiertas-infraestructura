'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_prefix = sequelize.define('edcapi_project_prefix', {
    prefix: DataTypes.STRING,
    description: DataTypes.STRING
  }, {});
  edcapi_project_prefix.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_prefix;
};