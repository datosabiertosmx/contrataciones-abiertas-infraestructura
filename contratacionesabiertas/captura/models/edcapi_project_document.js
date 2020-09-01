'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_document = sequelize.define('edcapi_project_document', {
    documentType: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING,
    url: DataTypes.STRING,
    datePublished: DataTypes.STRING,
    dateModified: DataTypes.STRING,
    format: DataTypes.STRING,
    language: DataTypes.STRING,
    pageStart: DataTypes.INTEGER,
    pageEnd: DataTypes.INTEGER,
    accessDetails: DataTypes.STRING,
    author: DataTypes.STRING
  }, {});
  edcapi_project_document.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_document;
};