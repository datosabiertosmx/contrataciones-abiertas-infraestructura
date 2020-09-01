'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_cat_geometry_types', [
      {
        code: 'Point',
        title: 'Punto',
        description: 'Para el tipo "Punto", el miembro "coordenadas" es una posición única.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'MultiPoint',
        title: 'MultiPunto',
        description: 'Para el tipo "MultiPoint", el miembro "coordenadas" es una matriz de posiciones.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'LineString',
        title: 'Cadena de texto multilínea',
        description: 'Para el tipo "MultiLineString", el miembro "coordenadas" es una matriz de matrices de coordenadas LineString.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'Polygon',
        title: 'Polígono',
        description: 'Para el tipo "Polígono", el miembro "coordenadas" DEBE ser un conjunto de conjuntos de coordenadas de anillo lineal.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'MultiPolygon',
        title: 'MultiPolígono',
        description: 'Para el tipo "MultiPolygon", el miembro "coordenadas" es una matriz de matrices de coordenadas Polygon.',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_cat_document_types', null, {});
  }
};
