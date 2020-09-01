'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_location_coordinate = sequelize.define('edcapi_project_location_coordinate', {
    point: DataTypes.FLOAT              
  }, {});
  edcapi_project_location_coordinate.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_location_coordinate;
};