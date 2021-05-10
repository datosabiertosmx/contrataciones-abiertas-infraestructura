'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class edcapi_project_locations_address_location extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  };
  edcapi_project_locations_address_location.init({
    edcapiLocationProjectId: DataTypes.INTEGER,
    edcapiProjectLocationAddressId: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'edcapi_project_locations_address_location',
  });
  return edcapi_project_locations_address_location;
};