'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.addConstraint('edcapi_project_asset_lifetime_projects', ['project_id'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_asset_lifetime_projects_project_1',
          references: {
            table: 'edcapi_projects',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
        await queryInterface.addConstraint('edcapi_project_asset_lifetime_projects', ['edcapiProjectAssetLifetimeId'], {
          type: 'FOREIGN KEY',
          name: 'FK_edcapi_project_asset_lifetime_projects_project_asset_lifetime_1',
          references: {
            table: 'edcapi_project_asset_lifetimes',
            field: 'id',
          },
          onDelete: 'no action',
          onUpdate: 'no action',
        }),
      ]
  },

  down: async (queryInterface, Sequelize) => {
    return [
      await queryInterface.removeConstraint('edcapi_project_asset_lifetime_projects', 'FK_edcapi_project_asset_lifetime_projects_project_1'), 
      await queryInterface.removeConstraint('edcapi_project_asset_lifetime_projects', 'FK_edcapi_project_asset_lifetime_projects_project_asset_lifetime_1'),
    ]
  }
};
