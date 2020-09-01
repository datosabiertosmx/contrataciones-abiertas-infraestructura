'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edca_cat_origins', [
      {
        value: 'Federales',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        value: 'Estatales',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        value: 'Municipales',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edca_cat_origins', null, {});
  }
};
