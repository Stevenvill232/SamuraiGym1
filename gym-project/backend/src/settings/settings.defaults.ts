export const TIPOS_PLAN = [
  'GIMNASIO_SESION',
  'GIMNASIO_QUINCENA',
  'GIMNASIO_MES',
  'TIQUETERA_10',
  'TIQUETERA_15',
  'TIQUETERA_20',
  'TIQUETERA_30',
  'BOXEO',
  'KARATE',
  'MMA',
];

/**
 * Valores por defecto de cada ajuste. Mientras el administrador no guarde
 * nada, el sistema funciona con estos. Los valores de `categorias_gasto` y
 * `metodos_pago` coinciden con los que ya se venían usando, para que los
 * registros históricos sigan siendo válidos.
 */
export const SETTINGS_DEFAULTS: Record<string, any> = {
  precios_planes: {
    GIMNASIO_SESION: 8000,
    GIMNASIO_QUINCENA: 40000,
    GIMNASIO_MES: 70000,
    TIQUETERA_10: 60000,
    TIQUETERA_15: 85000,
    TIQUETERA_20: 110000,
    TIQUETERA_30: 150000,
    BOXEO: 80000,
    KARATE: 80000,
    MMA: 90000,
  },
  // Una tiquetera de N días vence en N x factor días calendario.
  tiquetera_factor_vigencia: 2,
  categorias_gasto: [
    'LUZ',
    'AGUA',
    'NOMINA',
    'ARRIENDO',
    'INTERNET',
    'MANTENIMIENTO',
    'IMPLEMENTOS',
    'OTRO',
  ],
  metodos_pago: [
    'EFECTIVO',
    'TRANSFERENCIA',
    'NEQUI',
    'DAVIPLATA',
    'TARJETA',
    'OTRO',
  ],
  stock_minimo_default: 5,
  info_gimnasio: {
    nombre: 'Mi Gimnasio',
    telefono: '',
    direccion: '',
    horarioAtencion: '',
  },
  // Se aplicará cuando se active el envío de notificaciones (Fase 6).
  notificaciones: {
    avisarDosDias: true,
    avisarUnDia: true,
    avisarVencido: true,
  },
};

export const SETTINGS_CLAVES = Object.keys(SETTINGS_DEFAULTS);
