'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_related_contracting_process = sequelize.define('edcapi_project_related_contracting_process', {
    ocid: DataTypes.STRING,
    title: DataTypes.STRING,
    contractingProcessId: DataTypes.INTEGER,
    tenderId: DataTypes.STRING
  }, {});
  edcapi_project_related_contracting_process.associate = function(models) {
    // associations can be defined here
  };
  return edcapi_project_related_contracting_process;
};