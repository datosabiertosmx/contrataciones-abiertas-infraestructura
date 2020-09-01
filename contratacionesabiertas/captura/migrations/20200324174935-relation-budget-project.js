'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_budget_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_budget_projects_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_budget_projects', ['edcapiBudgetId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_budget_projects_budget_1',
          references: {
            table: 'edcapi_budgets',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_budget_projects', 'FK_edcapi_budget_projects_project_1'), 
      await queryInterface.removeConstraint('edcapi_budget_projects', 'FK_edcapi_budget_projects_budget_1'),
    ]
  }
};
