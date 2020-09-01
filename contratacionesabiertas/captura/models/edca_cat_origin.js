'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class edca_cat_origin extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  };
  edca_cat_origin.init({
    value: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'edca_cat_origin',
  });
  return edca_cat_origin;
};