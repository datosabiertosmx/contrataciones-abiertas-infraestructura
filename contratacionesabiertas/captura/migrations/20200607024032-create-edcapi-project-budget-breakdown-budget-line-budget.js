'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('edcapi_project_budget_breakdown_budget_line_budgets', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      edcapiProjectBudgetBreakdownBudgetLineId: {
        type: Sequelize.INTEGER
      },
      edcapiProjectBudgetBreakdownId: {
        type: Sequelize.INTEGER
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  down: (queryInterface, Sequelize) => {
    return queryInterface.dropTable('edcapi_project_budget_breakdown_budget_line_budgets');
  }
};