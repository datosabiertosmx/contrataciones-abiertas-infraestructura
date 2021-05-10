'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_location_project = sequelize.define('edcapi_location_project', {
    description: DataTypes.STRING,
    type: DataTypes.STRING
  }, {});
  edcapi_location_project.associate = function(models) {
    // associations can be defined here
    edcapi_location_project.belongsToMany(models.edcapi_project_location_coordinate, {
      through: 'edcapi_project_locations_coordinate_location',
      as: 'coordinates',
      foreignKey: 'edcapiLocationProjectId',
    }),
    edcapi_location_project.belongsToMany(models.edcapi_project_location_address, {
      through: 'edcapi_project_locations_address_location',
      as: 'address',
      foreignKey: 'edcapiLocationProjectId',
    })
  };
  return edcapi_location_project;
};