'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_budget_breakdown_budgets', ['budget_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_budget_breakdown_budgets_budget_1',
          references: {
            table: 'edcapi_budgets',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_budget_breakdown_budgets', ['edcapiProjectBudgetBreakdownId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_budget_breakdown_budgets_budget_breakdown_1',
          references: {
            table: 'edcapi_project_budget_breakdowns',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budgets', 'FK_edcapi_project_budget_breakdown_budgets_budget_1'), 
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budgets', 'FK_edcapi_project_budget_breakdown_budgets_budget_breakdown_1'),
    ]
  }
};
