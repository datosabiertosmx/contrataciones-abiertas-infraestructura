'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_cat_related_projects', [
      {
        code: 'construction',
        title: 'Proyecto de construccion',
        description: 'El proyecto relacionado es la construcción inicial de la infraestructura.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'rehabilitation',
        title: 'Proyecto de rehabilitación',
        description: 'El proyecto relacionado podría resultar en la rehabilitación de la misma infraestructura.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'replacement',
        title: 'Proyecto de reemplazo',
        description: 'El proyecto relacionado podría resultar en el reemplazo de la misma infraestructura.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'expansion',
        title: 'Proyecto de expansión',
        description: 'El proyecto relacionado podría resultar en la expansión de la misma infraestructura.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_statuses', null, {});
  }
};
