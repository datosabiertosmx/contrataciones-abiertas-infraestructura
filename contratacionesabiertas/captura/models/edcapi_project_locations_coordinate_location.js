'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_locations_coordinate_location = sequelize.define('edcapi_project_locations_coordinate_location', {
    edcapiLocationProjectId: DataTypes.INTEGER,
    edcapiProjectLocationCoordinateId: DataTypes.INTEGER
  }, {});
  edcapi_project_locations_coordinate_location.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_locations_coordinate_location;
};