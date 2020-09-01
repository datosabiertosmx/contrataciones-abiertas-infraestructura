'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
    await queryInterface.addConstraint('edcapi_project_package_projects', ['project_package_id'], {
        type: 'FOREIGN KEY',
        name: 'FK_edcapi_project_package_projects_project_packages_1',
        references: {
          table: 'edcapi_project_packages',
          field: 'id',
        },
        onDelete: 'no action',
        onUpdate: 'no action',
      }),
      await queryInterface.addConstraint('edcapi_project_package_projects', ['project_id'], {
        type: 'FOREIGN KEY',
        name: 'FK_edcapi_project_package_projects_projects_1',
        references: {
          table: 'edcapi_projects',
          field: 'id',
        },
        onDelete: 'no action',
        onUpdate: 'no action',
      }),
    ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_package_projects', 'FK_edcapi_project_package_projects_project_packages_1'), 
      await queryInterface.removeConstraint('edcapi_project_package_projects', 'FK_edcapi_project_package_projects_projects_1'),
    ]
  }
};
