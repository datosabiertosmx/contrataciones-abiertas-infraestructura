'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_cat_geometry_type = sequelize.define('edcapi_cat_geometry_type', {
    code: DataTypes.STRING,
    title: DataTypes.STRING,
    description: DataTypes.STRING
  }, {});
  edcapi_cat_geometry_type.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_cat_geometry_type;
};