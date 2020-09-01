'use strict';

module.exports = {
  up: (queryInterface, Sequelize) => {
    return queryInterface.bulkInsert('edcapi_project_sectors', [
      {
        code: 'waterAndWaste',
        title: 'Agua',
        description: 'Agua y residuos, incluidos saneamiento y aguas residuales.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'communications',
        title: 'Comunicaciones',
        description: 'Comunicaciones, incluyendo TIC, TI, telecomunicaciones, servicios postales, internet de alta velocidad, banda ancha.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'cultureSportsAndRecreation',
        title: 'Cultura',
        description: 'Cultura, deportes y recreación, incluyendo turismo, parques y áreas verdes.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'sports',
        title: 'Deportes',
        description: 'Deportes, incluídas las instalaciones, sistemas, bienes y servicios que permiten el deporte.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'economy',
        title: 'Economía',
        description: 'Economía, incluidos los agronegocios, la agricultura, la ciencia y el medio ambiente.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'education',
        title: 'Educación',
        description: 'Educación, incluyendo escuelas, universidades y otras instalaciones de aprendizaje y capacitación.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'energy',
        title: 'Energía',
        description: 'Energía, incluida la generación de energía eléctrica, y la transmisión y distribución de electricidad, petróleo y gas, por ejemplo: centrales eléctricas, líneas eléctricas, gasoductos.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'governance',
        title: 'Gobernancia',
        description: 'Gobierno, incluidos alojamientos gubernamentales, edificios públicos, oficinas gubernamentales; justicia, tribunales; servicios de emergencia / respuesta, seguridad local; seguridad, prisiones, correcciones; defensa militar',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'socialHousing',
        title: 'Habitacional',
        description: 'Vivienda social.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'recreation',
        title: 'Recreación',
        description: 'Recreación, incluídos espacios de recreación o zonas de juegos en un espacio público especialmente acondicionado para la realización de actividades recreativas.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'waste',
        title: 'Residuos',
        description: 'Residuos, incluídos centros para el acopio, transferencia, separación y tratamiento de los mismos.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'health',
        title: 'Salud',
        description: 'Salud, incluidos hospitales, atención médica y servicios humanos.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport',
        title: 'Transporte',
        description: 'Transporte. Se puede proporcionar un desglose más detallado utilizando los códigos de transporte.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport.air',
        title: 'Transporte aéreo',
        description: 'Transporte aéreo, incluidos aeropuertos, vías aéreas y aviación.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport.road',
        title: 'Transporte carretero',
        description: 'Transporte por carretera, incluidas carreteras, autopistas, calles, túneles y puentes.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport.rail',
        title: 'Transporte ferroviario',
        description: 'Transporte ferroviario',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport.water',
        title: 'Transporte marítimo',
        description: 'Transporte por agua, incluidos puertos y vías navegables.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'transport.urban',
        title: 'Transporte urbano',
        description: 'Transporte urbano, incluyendo transporte público, movilidad urbana, autobuses, ciclismo, caminata y taxi.',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      {
        code: 'security',
        title: 'Seguridad',
        description: 'Seguridad, incluídos edificios e instalaciones permanentes que permiten las operaciones.',
        createdAt: new Date(),
        updatedAt: new Date(),
      }
    ], {});
  },

  down: (queryInterface, Sequelize) => {
    return queryInterface.bulkDelete('edcapi_project_sectors', null, {});
  }
};
