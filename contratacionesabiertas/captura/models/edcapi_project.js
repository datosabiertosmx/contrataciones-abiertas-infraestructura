'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project = sequelize.define('edcapi_project', {
    oc4ids: DataTypes.STRING,
    identifier: DataTypes.STRING,
    updated: DataTypes.DATE,
    title: DataTypes.STRING,
    description: DataTypes.STRING,
    status: DataTypes.STRING,
    purpose: DataTypes.STRING,
    sector: DataTypes.ARRAY(DataTypes.TEXT),
    type: DataTypes.STRING,
    oc4idsIdentifier: DataTypes.STRING
  }, {});
  edcapi_project.associate = function(models) {
    edcapi_project.belongsToMany(models.edcapi_project_package, {
      through: 'edcapi_project_package_projects',
      as: 'projecto',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_period, {
      through: 'edcapi_project_period_project',
      as: 'period',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_asset_lifetime, {
      through: 'edcapi_project_asset_lifetime_project',
      as: 'assetLifetime',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_budget, {
      through: 'edcapi_budget_project',
      as: 'budget',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_party, {
      through: 'edcapi_project_party_project',
      as: 'parties',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_related_project, {
      through: 'edcapi_project_related_project_project',
      as: 'relatedProjects',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_additional_classification, {
      through: 'edcapi_project_additional_classification_project',
      as: 'additionalClassifications',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_document, {
      through: 'edcapi_project_document_project',
      as: 'documents',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_location_project, {
      through: 'edcapi_project_location_project',
      as: 'locations',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_completion, {
      through: 'edcapi_project_completion_project',
      as: 'completion',
      foreignKey: 'project_id',
    }),
    edcapi_project.belongsToMany(models.edcapi_project_related_contracting_process, {
      through: 'edcapi_project_related_contracting_process_project',
      as: 'contractingProcesses',
      foreignKey: 'project_id',
    })
  };
  return edcapi_project;
};