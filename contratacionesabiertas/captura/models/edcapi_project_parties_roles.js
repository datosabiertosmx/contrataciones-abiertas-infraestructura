'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_parties_roles = sequelize.define('edcapi_project_parties_roles', {
    buyer: DataTypes.STRING,
    reviewBody: DataTypes.STRING,
    publicAuthority: DataTypes.STRING,
    payer: DataTypes.STRING,
    procuringEntity: DataTypes.STRING,
    funder: DataTypes.STRING,
    tenderer: DataTypes.STRING,
    enquirer: DataTypes.STRING,
    supplier: DataTypes.STRING,
    payee: DataTypes.STRING
  }, {});
  edcapi_project_parties_roles.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_parties_roles;
};