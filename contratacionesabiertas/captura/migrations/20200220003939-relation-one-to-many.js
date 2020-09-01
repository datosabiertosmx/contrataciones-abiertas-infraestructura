'use strict';
 
module.exports = {
  up: async (queryInterface, Sequelize) => {
   return [
    await queryInterface.addConstraint('edcapi_publisher_project_packages', ['edcapiPublisherId'], {
      type: 'FOREIGN KEY',
      name: 'FK_edcapi_publisher_project_packages_publisher_1',
      references: {
        table: 'edcapi_publishers',
        field: 'id',
      },
      onDelete: 'no action',
      onUpdate: 'no action',
    }),
    await queryInterface.addConstraint('edcapi_publisher_project_packages', ['project_package_id'], {
      type: 'FOREIGN KEY',
      name: 'FK_edcapi_publisher_project_packages_project_packages_1',
      references: {
        table: 'edcapi_project_packages',
        field: 'id',
      },
      onDelete: 'no action',
      onUpdate: 'no action',
    }),
  ]
  },
 
  down: async (queryInterface, Sequelize) => {
   return [
    await queryInterface.removeConstraint('edcapi_publisher_project_packages', 'FK_edcapi_publisher_project_packages_publisher_1'),
    await queryInterface.removeConstraint('edcapi_publisher_project_packages', 'FK_edcapi_publisher_project_packages_project_packages_1'),
  ]
  }
};