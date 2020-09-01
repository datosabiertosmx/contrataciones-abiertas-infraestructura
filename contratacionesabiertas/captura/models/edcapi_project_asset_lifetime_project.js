'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_asset_lifetime_project = sequelize.define('edcapi_project_asset_lifetime_project', {
    project_id: DataTypes.INTEGER,
    edcapiProjectAssetLifetimeId: DataTypes.INTEGER
  }, {});
  edcapi_project_asset_lifetime_project.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_asset_lifetime_project;
};