'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('edcapi_project_parties_roles', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      buyer: {
        type: Sequelize.STRING
      },
      reviewBody: {
        type: Sequelize.STRING
      },
      publicAuthority: {
        type: Sequelize.STRING
      },
      payer: {
        type: Sequelize.STRING
      },
      procuringEntity: {
        type: Sequelize.STRING
      },
      funder: {
        type: Sequelize.STRING
      },
      tenderer: {
        type: Sequelize.STRING
      },
      enquirer: {
        type: Sequelize.STRING
      },
      supplier: {
        type: Sequelize.STRING
      },
      payee: {
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
    return queryInterface.dropTable('edcapi_project_parties_roles');
  }
};