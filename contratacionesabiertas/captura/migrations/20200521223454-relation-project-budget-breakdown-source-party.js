'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_budget_breakdown_source_party_budgets', ['edcapiProjectBudgetBreakdownId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_budget_breakdown_source_party_budgets_budget_breakdown_1',
          references: {
            table: 'edcapi_project_budget_breakdowns',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_budget_breakdown_source_party_budgets', ['edcapiProjectBudgetBreakdownSourcePartyId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_budget_breakdown_source_party_budgets_source_party_1',
          references: {
            table: 'edcapi_project_budget_breakdown_source_parties',
            field: 'id',
          },
          onDelete: 'cascade',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_source_party_budgets', 'FK_edcapi_project_budget_breakdown_source_party_budgets_budget_breakdown_1'), 
      await queryInterface.removeConstraint('edcapi_project_budget_breakdown_source_party_budgets', 'FK_edcapi_project_budget_breakdown_source_party_budgets_source_party_1'),
    ]
  }
};
