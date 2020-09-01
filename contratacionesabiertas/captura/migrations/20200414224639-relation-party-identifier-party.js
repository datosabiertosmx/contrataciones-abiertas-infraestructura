'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_parties_identifier_projects', ['party_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_parties_identifier_project_project_1',
          references: {
            table: 'edcapi_project_parties',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_parties_identifier_projects', ['edcapiProjectPartiesIdentifierId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_parties_identifier_project_identifier_1',
          references: {
            table: 'edcapi_project_parties_identifiers',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_parties_identifier_projects', 'FK_edcapi_project_parties_identifier_project_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_parties_identifier_projects', 'FK_edcapi_project_parties_identifier_project_identifier_1'),
    ]
  }
};
