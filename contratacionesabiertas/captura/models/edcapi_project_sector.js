'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_sector = sequelize.define('edcapi_project_sector', {
    code: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING(900)
  }, {});
  edcapi_project_sector.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_sector;
};