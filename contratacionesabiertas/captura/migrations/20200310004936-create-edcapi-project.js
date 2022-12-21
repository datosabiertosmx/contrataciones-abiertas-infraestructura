'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('edcapi_projects', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      oc4ids: {
        type: Sequelize.STRING
      },
      identifier: {
        type: Sequelize.STRING
      },
      updated: {
        type: Sequelize.DATE
      },
      title: {
        type: Sequelize.STRING
      },
      description: {
        type: Sequelize.TEXT
      },
      status: {
        type: Sequelize.STRING
      },
      purpose: {
        type: Sequelize.TEXT
      },
      sector: {
        type: Sequelize.ARRAY(Sequelize.TEXT)
      },
      type: {
        type: Sequelize.STRING
      },
      oc4idsIdentifier: {
        type: Sequelize.STRING
      },
      is_public: {
        type: Sequelize.BOOLEAN
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
    return queryInterface.dropTable('edcapi_projects');
  }
};