'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_project_statuses', [
      {
        code: 'completed',
        title: 'Terminado',
        description: 'Se completaron las actividades de cierre y este proyecto está inactivo.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'completion',
        title: 'Terminación',
        description: 'La finalización cubre la entrega de los activos y actividades de cierre con detalles del alcance final, el costo y el tiempo de entrega.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'identification',
        title: 'Identificación',
        description: 'La identificación se refiere a la decisión de desarrollar un proyecto dentro del presupuesto y el programa del propietario del proyecto (la entidad pública responsable de ejecutar el presupuesto.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'implementation',
        title: 'Implementación',
        description: 'La implementación cubre la adquisición e implementación del grupo de obras o servicios (como diseño y supervisión) que se entregarán en el marco del proyecto, incluidas las obras o servicios realizados por la entidad contratante. Esto difiere de la definición de "implementación" en OCDS, que cubre la implementación pero no la adquisición.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'cancelled',
        title: 'Cancelado',
        description: 'Este proyecto se canceló antes de que se completaran las actividades de cierre y está inactivo. La cancelación puede ocurrir en cualquier momento después de la identificación.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'preparation',
        title: 'Preparación',
        description: 'La preparación cubre el estudio de factibilidad, la evaluación del impacto ambiental y social, el alcance general del proyecto, el establecimiento de la estrategia de empaque y adquisición, los requisitos legales preliminares sobre los impactos ambientales y de la tierra, y la autorización presupuestaria resultante.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_statuses', null, {});
  }
};
