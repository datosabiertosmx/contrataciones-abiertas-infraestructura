'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_cat_document_type = sequelize.define('edcapi_cat_document_type', {
    code: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING(900)
  }, {});
  edcapi_cat_document_type.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_cat_document_type;
};