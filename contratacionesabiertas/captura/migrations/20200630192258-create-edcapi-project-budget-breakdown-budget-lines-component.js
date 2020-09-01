'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('edcapi_project_budget_breakdown_budget_lines_components', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      year: {
        type: Sequelize.INTEGER
      },
      branch: {
        type: Sequelize.STRING
      },
      kBranch: {
        type: Sequelize.STRING
      },
      responsibleUnit: {
        type: Sequelize.STRING
      },
      kResponsibleUnit: {
        type: Sequelize.STRING
      },
      finality: {
        type: Sequelize.STRING
      },
      kFinality: {
        type: Sequelize.STRING
      },
      function: {
        type: Sequelize.STRING
      },
      kFunction: {
        type: Sequelize.STRING
      },
      subFunction: {
        type: Sequelize.STRING
      },
      kSubFunction: {
        type: Sequelize.STRING
      },
      instAct: {
        type: Sequelize.STRING
      },
      kInstAct: {
        type: Sequelize.STRING
      },
      budgetProgram: {
        type: Sequelize.STRING
      },
      kBudgetProgram: {
        type: Sequelize.STRING
      },
      spendingObject: {
        type: Sequelize.STRING
      },
      kSpendingObject: {
        type: Sequelize.STRING
      },
      spendingType: {
        type: Sequelize.STRING
      },
      kSpendingType: {
        type: Sequelize.STRING
      },
      budgetSource: {
        type: Sequelize.STRING
      },
      kBudgetSource: {
        type: Sequelize.STRING
      },
      region: {
        type: Sequelize.STRING
      },
      kRegion: {
        type: Sequelize.STRING
      },
      portfolio: {
        type: Sequelize.STRING
      },
      kPortfolio: {
        type: Sequelize.STRING
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
    return queryInterface.dropTable('edcapi_project_budget_breakdown_budget_lines_components');
  }
};