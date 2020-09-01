'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_cat_budget_moment_types', [
      {
        code: 'approved',
        title: 'Aprobado',
        description: 'El momento contable del gasto aprobado, es el que refleja las asignaciones presupuestarias anuales comprometidas en el Presupuesto de Egresos.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'modified',
        title: 'Modificado',
        description: 'El gasto modificado es el momento contable que refleja la asignación presupuestaria que resulta de incorporar, en su caso, las adecuaciones presupuestarias al presupuesto aprobado.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'committed',
        title: 'Comprometido',
        description: 'El gasto comprometido es el momento contable que refleja la aprobación por autoridad competente de un acto administrativo, u otro instrumento jurídico que formaliza una relación jurídica con terceros para la adquisición de bienes y servicios o ejecución de obras. En el caso de las obras a ejecutarse o de bienes y servicios a recibirse durante varios ejercicios, el compromiso será registrado por la parte que se ejecutará o recibirá, durante cada ejercicio',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'accrued',
        title: 'Devengado',
        description: 'El gasto devengado es el momento contable que refleja el reconocimiento de una obligación de pago a favor de terceros por la recepción de conformidad de bienes, servicios y obras oportunamente contratados; así como de las obligaciones que derivan de tratados, leyes, decretos, resoluciones y sentencias definitivas.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'executed',
        title: 'Ejercido',
        description: 'El gasto ejercido es el momento contable que refleja la emisión de una cuenta por liquidar certificada o documento equivalente debidamente aprobado por la autoridad competente.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'paid',
        title: 'Pagado',
        description: 'El gasto pagado es el momento contable que refleja la cancelación total o parcial de las obligaciones de pago, que se concreta mediante el desembolso de efectivo o cualquier otro medio de pago.',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_cat_document_types', null, {});
  }
};
