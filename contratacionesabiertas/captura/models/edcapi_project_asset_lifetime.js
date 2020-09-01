'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_asset_lifetime = sequelize.define('edcapi_project_asset_lifetime', {
    startDate: DataTypes.STRING,
    endDate: DataTypes.STRING,
    maxExtentDate: DataTypes.STRING,
    durationInDays: DataTypes.INTEGER
  }, {});
  edcapi_project_asset_lifetime.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_asset_lifetime;
};