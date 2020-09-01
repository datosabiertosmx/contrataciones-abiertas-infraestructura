'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_project_types', [
      {
        code: 'construction',
        title: 'Construcción',
        description: 'El enfoque principal de este proyecto es la construcción de un nuevo activo.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'rehabilitation',
        title: 'Rehabilitación',
        description: 'El enfoque principal de este proyecto es la rehabilitación de un activo existente.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'replacement',
        title: 'Reemplazo',
        description: 'El enfoque principal de este proyecto es el reemplazo de un activo existente.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'expansion',
        title: 'Expansión',
        description: 'El proyecto relacionado podría resultar en la expansión de la misma infraestructura.',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_types', null, {});
  }
};
