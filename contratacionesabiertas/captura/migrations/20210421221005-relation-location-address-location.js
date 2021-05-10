'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_locations_address_locations', ['edcapiLocationProjectId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_locations_address_locations_location_1',
          references: {
            table: 'edcapi_location_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_locations_address_locations', ['edcapiProjectLocationAddressId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_locations_address_locations_address_1',
          references: {
            table: 'edcapi_project_location_addresses',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_locations_address_locations', 'FK_edcapi_project_locations_address_locations_location_1'), 
      await queryInterface.removeConstraint('edcapi_project_locations_address_locations', 'FK_edcapi_project_locations_address_locations_address_1'),
    ]
  }
};
