'use strict';
module.exports = (sequelize, DataTypes) => {
  const edcapi_project_period = sequelize.define('edcapi_project_period', {
    startDate: DataTypes.STRING,
    endDate: DataTypes.STRING,
    maxExtentDate: DataTypes.STRING,
    durationInDays: DataTypes.INTEGER
  }, {});
  edcapi_project_period.associate = function(models) {
    // associations can be defined here
    edcapi_project_period.belongsToMany(models.edcapi_project, {
      through: 'edcapi_project_period_project',
      as: 'periodo',
      foreignKey: 'project_period_id',
    })
  };
  return edcapi_project_period;
};