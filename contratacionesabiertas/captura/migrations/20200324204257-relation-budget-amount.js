'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_budget_amount_budgets', ['budget_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_budget_amount_budgets_budget_1',
          references: {
            table: 'edcapi_budgets',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_budget_amount_budgets', ['edcapiBudgetAmountId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_budget_amount_budgets_amount_1',
          references: {
            table: 'edcapi_budget_amounts',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_budget_amount_budgets', 'FK_edcapi_budget_amount_budgets_budget_1'), 
      await queryInterface.removeConstraint('edcapi_budget_amount_budgets', 'FK_edcapi_budget_amount_budgets_amount_1'),
    ]
  }
};
