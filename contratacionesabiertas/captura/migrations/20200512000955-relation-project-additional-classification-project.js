'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_additional_classification_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_additional_classification_projects_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_additional_classification_projects', ['edcapiProjectAdditionalClassificationId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_additional_classification_projects_additional_classification_1',
          references: {
            table: 'edcapi_project_additional_classifications',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_additional_classification_projects', 'FK_edcapi_project_additional_classification_projects_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_additional_classification_projects', 'FK_edcapi_project_additional_classification_projects_additional_classification_1'),
    ]
  }
};
