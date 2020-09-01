'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_budget_breakdown_budget_lines_component_budgets', ['edcapiProjectBudgetBreakdownBudgetLineId'], {
          type: 'FOREIGN KEY',
          name: 'FK_budget_breakdown_line_breakdown_2',
          references: {
            table: 'edcapi_project_budget_breakdown_budget_lines',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_budget_breakdown_budget_lines_component_budgets', ['edcapiProjectBudgetBreakdownBudgetLinesComponentId'], {
          type: 'FOREIGN KEY',
          name: 'FK_budget_breakdown_line_component_breakdown_1',
          references: {
            table: 'edcapi_project_budget_breakdown_budget_lines_components',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budget_lines_component_budgets', 'FK_budget_breakdown_line_breakdown_2'), 
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_budget_lines_component_budgets', 'FK_budget_breakdown_line_component_breakdown_1'),
    ]
  }
};
