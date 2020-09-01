'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_period_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_period_projects_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_period_projects', ['project_period_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_period_projects_project_period_1',
          references: {
            table: 'edcapi_project_periods',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_period_projects', 'FK_edcapi_project_period_projects_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_period_projects', 'FK_edcapi_project_period_projects_project_period_1'),
    ]
  }
};
