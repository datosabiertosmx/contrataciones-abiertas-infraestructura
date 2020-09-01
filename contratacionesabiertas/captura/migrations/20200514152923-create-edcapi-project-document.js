'use strict';
module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.createTable('edcapi_project_documents', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      documentType: {
        type: Sequelize.STRING
      },
      title: {
        type: Sequelize.STRING
      },
      description: {
        type: Sequelize.STRING
      },
      url: {
        type: Sequelize.STRING
      },
      datePublished: {
        type: Sequelize.STRING
      },
      dateModified: {
        type: Sequelize.STRING
      },
      format: {
        type: Sequelize.STRING
      },
      language: {
        type: Sequelize.STRING
      },
      pageStart: {
        type: Sequelize.INTEGER
      },
      pageEnd: {
        type: Sequelize.INTEGER
      },
      accessDetails: {
        type: Sequelize.STRING
      },
      author: {
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
    return queryInterface.dropTable('edcapi_project_documents');
  }
};