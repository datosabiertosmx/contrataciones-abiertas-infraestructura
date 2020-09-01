'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_related_contracting_process_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_related_contracting_process_project_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_related_contracting_process_projects', ['edcapiProjectRelatedContractingProcessId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_related_contracting_process_project_contracting_process_1',
          references: {
            table: 'edcapi_project_related_contracting_processes',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_related_contracting_process_projects', 'FK_edcapi_project_related_contracting_process_project_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_related_contracting_process_projects', 'FK_edcapi_project_related_contracting_process_project_contracting_process_1'),
    ]
  }
};
