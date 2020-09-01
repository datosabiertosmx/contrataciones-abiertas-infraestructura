'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_completion_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_completion_project_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_completion_projects', ['edcapiProjectCompletionId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_completion_project_completion_1',
          references: {
            table: 'edcapi_project_completions',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_completion_projects', 'FK_edcapi_project_completion_project_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_completion_projects', 'FK_edcapi_project_completion_project_completion_1'),
    ]
  }
};
