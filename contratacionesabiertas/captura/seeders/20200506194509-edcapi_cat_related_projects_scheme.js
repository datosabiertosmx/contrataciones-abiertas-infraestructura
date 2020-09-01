'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_cat_related_projects_schemes', [
      {
        code: 'oc4ids',
        title: 'oc4ids',
        description: '',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_statuses', null, {});
  }
};
