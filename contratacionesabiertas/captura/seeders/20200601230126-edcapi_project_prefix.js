'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_project_prefixes', [
      {
        prefix: 'oc4ids',
        description: 'Prefijo base de EDCAPI.',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_prefixes', null, {});
  }
};
