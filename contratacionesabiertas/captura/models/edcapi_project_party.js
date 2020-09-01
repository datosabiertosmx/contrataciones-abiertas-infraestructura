'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_party = sequelize.define('edcapi_project_party', {
    identifier: DataTypes.STRING,
    name: DataTypes.STRING
  }, {});
  edcapi_project_party.associate = function(models) {
    // associations can be defined here
    edcapi_project_party.belongsToMany(models.edcapi_project_parties_identifier, {
      through: 'edcapi_project_parties_identifier_project',
      as: 'identifierR',
      foreignKey: 'party_id',
    }),
    edcapi_project_party.belongsToMany(models.edcapi_project_parties_address, {
      through: 'edcapi_project_parties_address_party',
      as: 'address',
      foreignKey: 'party_id',
    }),
    edcapi_project_party.belongsToMany(models.edcapi_project_parties_contact_point, {
      through: 'edcapi_project_parties_contact_point_party',
      as: 'contactPoint',
      foreignKey: 'party_id',
    }),
    edcapi_project_party.belongsToMany(models.edcapi_project_parties_roles, {
      through: 'edcapi_project_parties_roles_party',
      as: 'roles',
      foreignKey: 'party_id',
    }),
    edcapi_project_party.belongsToMany(models.edcapi_project_parties_additional_identifier, {
      through: 'edcapi_project_parties_additional_identifier_party',
      as: 'additionalIdentifiers',
      foreignKey: 'party_id',
    })
  };
  return edcapi_project_party;
};