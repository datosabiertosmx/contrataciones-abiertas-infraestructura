'use strict';
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('planning_party_units', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      contractingprocess_id: {
        type: Sequelize.INTEGER
      },
      party_code: {
        type: Sequelize.STRING
      },
      party_name: {
        type: Sequelize.STRING
      },
      party_legal_name: {
        type: Sequelize.STRING
      },
      requesting_unit: {
        type: Sequelize.BOOLEAN
      },
      contracting_unit: {
        type: Sequelize.BOOLEAN
      },
      responsible_unit: {
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
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('planning_party_units');
  }
};