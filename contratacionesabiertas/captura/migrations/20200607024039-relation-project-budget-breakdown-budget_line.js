'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_budget_breakdown_budget_line_budgets', ['edcapiProjectBudgetBreakdownId'], {
          type: 'FOREIGN KEY',
          name: 'FK_budget_breakdown_line_budget_breakdown_1',
          references: {
            table: 'edcapi_project_budget_breakdowns',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_budget_breakdown_budget_line_budgets', ['edcapiProjectBudgetBreakdownBudgetLineId'], {
          type: 'FOREIGN KEY',
          name: 'FK_budget_breakdown_line_1',
          references: {
            table: 'edcapi_project_budget_breakdown_budget_lines',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budget_line_budgets', 'FK_budget_breakdown_line_budget_breakdown_1'), 
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budget_line_budgets', 'FK_budget_breakdown_line_1'),
    ]
  }
};
