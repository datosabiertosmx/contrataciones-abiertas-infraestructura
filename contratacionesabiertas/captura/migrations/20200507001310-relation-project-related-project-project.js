'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_related_project_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_related_project_project_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_related_project_projects', ['edcapiProjectRelatedProjectId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_related_project_projects_related_project_1',
          references: {
            table: 'edcapi_project_related_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_related_project_projects', 'FK_edcapi_project_related_project_project_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_related_project_projects', 'FK_edcapi_project_related_project_projects_related_project_1'),
    ]
  }
};
