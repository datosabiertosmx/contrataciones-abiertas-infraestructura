'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class edcapi_project_location_address extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  };
  edcapi_project_location_address.init({
    streetAddress: DataTypes.STRING,
    locality: DataTypes.STRING,
    region: DataTypes.STRING,
    postalCode: DataTypes.STRING,
    countryName: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'edcapi_project_location_address',
  });
  return edcapi_project_location_address;
};