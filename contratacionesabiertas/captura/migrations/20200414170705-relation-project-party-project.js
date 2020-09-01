'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_party_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_party_project_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_party_projects', ['edcapiProjectPartyId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_party_project_party_1',
          references: {
            table: 'edcapi_project_parties',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_party_projects', 'FK_edcapi_project_party_project_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_party_projects', 'FK_edcapi_project_party_project_party_1'),
    ]
  }
};
