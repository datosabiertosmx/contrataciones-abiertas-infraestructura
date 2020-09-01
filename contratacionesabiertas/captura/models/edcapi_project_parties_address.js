'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_parties_address = sequelize.define('edcapi_project_parties_address', {
    streetAddress: DataTypes.STRING,
    locality: DataTypes.STRING,
    region: DataTypes.STRING,
    postalCode: DataTypes.STRING,
    countryName: DataTypes.STRING
  }, {});
  edcapi_project_parties_address.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_parties_address;
};