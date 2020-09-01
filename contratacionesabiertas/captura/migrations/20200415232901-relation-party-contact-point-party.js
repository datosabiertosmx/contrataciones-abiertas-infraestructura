'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_parties_contact_point_parties', ['party_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_parties_contact_point_parties_party_1',
          references: {
            table: 'edcapi_project_parties',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_parties_contact_point_parties', ['edcapiProjectPartiesContactPointId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_parties_contact_point_parties_contactpoint_1',
          references: {
            table: 'edcapi_project_parties_contact_points',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_parties_contact_point_parties', 'FK_edcapi_project_parties_contact_point_parties_party_1'), 
      await queryInterface.removeConstraint('edcapi_project_parties_contact_point_parties', 'FK_edcapi_project_parties_contact_point_parties_contactpoint_1'),
    ]
  }
};
