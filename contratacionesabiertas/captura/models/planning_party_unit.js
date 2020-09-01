'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class planning_party_unit extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  };
  planning_party_unit.init({
    contractingprocess_id: DataTypes.INTEGER,
    party_code: DataTypes.STRING,
    party_name: DataTypes.STRING,
    party_legal_name: DataTypes.STRING,
    requesting_unit: DataTypes.BOOLEAN,
    contracting_unit: DataTypes.BOOLEAN,
    responsible_unit: DataTypes.BOOLEAN
  }, {
    sequelize,
    modelName: 'planning_party_unit',
  });
  return planning_party_unit;
};