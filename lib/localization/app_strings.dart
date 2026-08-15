/// ReserveHub — Cadena de texto de la interfaz de usuario.
///
/// ARQUITECTURA DE LOCALIZACIÓN
/// ─────────────────────────────────────────────────────────────────────────────
/// AppStrings es la ÚNICA fuente de verdad para todo el texto de la plataforma
/// ReserveHub. Ningún widget, pantalla o componente debe contener texto de UI
/// codificado directamente.
///
/// IDIOMA PREDETERMINADO: Español (es)
/// ReserveHub 1.0.0 es una plataforma para negocios latinoamericanos.
///
/// FASES FUTURAS:
///   - Fase L2: Inglés (en) — agregar AppStringsEn con los mismos identificadores
///   - Fase L3: Portugués (pt) — agregar AppStringsPt con los mismos identificadores
///   - Fase L4: Migrar a flutter_localizations + ARB si se requiere i18n completo
///
/// REGLAS:
///   - No traducir contenido generado por el usuario.
///   - No traducir identificadores Dart, nombres de tablas, RPCs ni nombres técnicos.
///   - Usar identificadores en inglés (camelCase) para mantener compatibilidad de código.
///   - Los valores son en español para ReserveHub 1.0.0.
/// ─────────────────────────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  // ═══════════════════════════════════════════════════════════════════════════
  // APP — Identidad de la plataforma
  // ═══════════════════════════════════════════════════════════════════════════

  static const String appName = 'ReserveHub';
  static const String appTagline =
      'La forma inteligente de gestionar reservas.';
  static const String appDescription =
      'La plataforma de reservas para negocios latinoamericanos.';

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON ACTIONS — Acciones comunes
  // ═══════════════════════════════════════════════════════════════════════════

  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String edit = 'Editar';
  static const String delete = 'Eliminar';
  static const String close = 'Cerrar';
  static const String next = 'Siguiente';
  static const String back = 'Atrás';
  static const String done = 'Listo';
  static const String retry = 'Reintentar';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String clear = 'Limpiar';
  static const String add = 'Agregar';
  static const String remove = 'Eliminar';
  static const String update = 'Actualizar';
  static const String create = 'Crear';
  static const String view = 'Ver';
  static const String select = 'Seleccionar';
  static const String upload = 'Subir';
  static const String download = 'Descargar';
  static const String share = 'Compartir';
  static const String copy = 'Copiar';
  static const String yes = 'Sí';
  static const String no = 'No';
  static const String ok = 'Aceptar';
  static const String apply = 'Aplicar';
  static const String reset = 'Restablecer';
  static const String refresh = 'Actualizar';
  static const String continue_ = 'Continuar';
  static const String finish = 'Finalizar';
  static const String skip = 'Omitir';
  static const String all = 'Todos';
  static const String active = 'Activo';
  static const String inactive = 'Inactivo';
  static const String enabled = 'Habilitado';
  static const String disabled = 'Deshabilitado';
  static const String optional = 'Opcional';
  static const String required = 'Requerido';
  static const String today = 'Hoy';
  static const String yesterday = 'Ayer';
  static const String tomorrow = 'Mañana';
  static const String thisWeek = 'Esta semana';
  static const String thisMonth = 'Este mes';
  static const String custom = 'Personalizado';
  static const String from = 'Desde';
  static const String to = 'Hasta';
  static const String of = 'de';
  static const String and = 'y';
  static const String or = 'o';
  static const String minutes = 'minutos';
  static const String hours = 'horas';
  static const String days = 'días';

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTICATION — Autenticación
  // ═══════════════════════════════════════════════════════════════════════════

  static const String signIn = 'Iniciar sesión';
  static const String signUp = 'Registrarse';
  static const String signOut = 'Cerrar sesión';
  static const String createAccount = 'Crear cuenta';
  static const String email = 'Correo electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String resetPassword = 'Restablecer contraseña';
  static const String changePassword = 'Cambiar contraseña';
  static const String currentPassword = 'Contraseña actual';
  static const String newPassword = 'Nueva contraseña';
  static const String alreadyHaveAccount = '¿Ya tienes una cuenta?';
  static const String dontHaveAccount = '¿No tienes una cuenta?';
  static const String welcomeBack = 'Bienvenido de nuevo';
  static const String welcomeToReserveHub = 'Bienvenido a ReserveHub';
  static const String signInToYourAccount = 'Inicia sesión en tu cuenta';
  static const String createYourAccount = 'Crea tu cuenta';
  static const String fullName = 'Nombre completo';
  static const String firstName = 'Nombre';
  static const String lastName = 'Apellido';
  static const String phone = 'Teléfono';
  static const String termsAndConditions = 'Términos y condiciones';
  static const String privacyPolicy = 'Política de privacidad';
  static const String agreeToTerms =
      'Al registrarte, aceptas nuestros términos y condiciones.';
  static const String sendResetLink = 'Enviar enlace de restablecimiento';
  static const String checkYourEmail = 'Revisa tu correo electrónico';
  static const String resetLinkSent =
      'Hemos enviado un enlace de restablecimiento a tu correo.';
  static const String signingIn = 'Iniciando sesión...';
  static const String creatingAccount = 'Creando cuenta...';

  // Auth form UI
  static const String rememberMe = 'Recuérdame';
  static const String showPassword = 'Mostrar contraseña';
  static const String hidePassword = 'Ocultar contraseña';
  static const String agreeToTermsPrefix = 'Al registrarte aceptas nuestros ';
  static const String signInToPortal =
      'Inicia sesión en tu portal de ReserveHub';

  // Brand hero / marketing copy
  static const String heroBrandHeadline =
      'Donde los negocios\ngestionan mejor su tiempo.';
  static const String appSubheadline =
      'Gestión profesional de citas para negocios modernos.';
  static const String appFooterTagline =
      'ReserveHub — SaaS profesional para negocios modernos.';

  // Feature pills
  static const String featureSmartScheduling = 'Agenda inteligente';
  static const String featureSmartSchedulingSubtitle =
      'Automatiza tu flujo de reservas';
  static const String featureCustomerManagement = 'Gestión de clientes';
  static const String featureCustomerManagementSubtitle =
      'Conoce mejor a tus clientes';
  static const String featureBusinessAnalytics = 'Analítica del negocio';
  static const String featureBusinessAnalyticsSubtitle =
      'Decisiones basadas en datos';

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION — Navegación
  // ═══════════════════════════════════════════════════════════════════════════

  static const String navDashboard = 'Panel';
  static const String navCalendar = 'Calendario';
  static const String navCustomers = 'Clientes';
  static const String navSettings = 'Configuración';
  static const String navNewAppointment = 'Nueva cita';
  static const String navSearch = 'Buscar negocios';
  static const String navProfile = 'Perfil';
  static const String navHelp = 'Ayuda';
  static const String navLogout = 'Cerrar sesión';
  static const String mainMenu = 'Menú principal';
  static const String openMenu = 'Abrir menú';
  static const String closeMenu = 'Cerrar menú';

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD — Panel de control
  // ═══════════════════════════════════════════════════════════════════════════

  static const String dashboard = 'Panel';
  static const String todaysAppointments = 'Citas de hoy';
  static const String upcomingAppointments = 'Próximas citas';
  static const String recentActivity = 'Actividad reciente';
  static const String newAppointment = 'Nueva cita';
  static const String revenue = 'Ingresos';
  static const String bookings = 'Reservas';
  static const String customers = 'Clientes';
  static const String occupancy = 'Ocupación';
  static const String totalAppointments = 'Total de citas';
  static const String completedAppointments = 'Citas completadas';
  static const String cancelledAppointments = 'Citas canceladas';
  static const String pendingAppointments = 'Citas pendientes';
  static const String confirmedAppointments = 'Citas confirmadas';
  static const String noShowAppointments = 'No se presentaron';
  static const String appointmentsToday = 'Citas hoy';
  static const String appointmentsThisWeek = 'Citas esta semana';
  static const String appointmentsThisMonth = 'Citas este mes';
  static const String goodMorning = 'Buenos días';
  static const String goodAfternoon = 'Buenas tardes';
  static const String goodEvening = 'Buenas noches';
  static const String overview = 'Resumen';
  static const String performance = 'Rendimiento';
  static const String quickActions = 'Acciones rápidas';
  static const String viewAll = 'Ver todos';
  static const String viewDetails = 'Ver detalles';

  // Dashboard — additional strings for L1-B3
  static const String panelPrincipal = 'Panel principal';
  static const String resumen = 'Resumen';
  static const String ingresos = 'Ingresos';
  static const String citasDeHoy = 'Citas de hoy';
  static const String proximasCitas = 'Próximas citas';
  static const String nuevaCita = 'Nueva cita';
  static const String verTodas = 'Ver todas';
  static const String proximaCita = 'Próxima cita';
  static const String horarioDeHoy = 'Horario de hoy';
  static const String totalLabel = 'total';
  static const String kpiTodayAppts = 'Citas de hoy';
  static const String kpiApptValue = 'Valor de citas';
  static const String kpiCancelled = 'Canceladas';
  static const String kpiCustomers = 'Clientes';
  static const String kpiVsYesterday = 'vs ayer';
  static const String kpiNoneToday = 'Ninguna hoy';
  static const String kpiUpcoming = 'próximas';
  static const String kpiInformationalOnly = 'Solo informativo';
  static const String kpiAlert = 'Alerta';
  static const String dashboardDataUnavailable =
      'Datos del panel no disponibles. Completa la configuración para ver los KPIs en vivo.';
  static const String revenueTrend = 'Tendencia de ingresos';
  static const String lastUpdatedJustNow = 'Actualizado ahora mismo';
  static const String chartRange7d = '7 días';
  static const String chartRange30d = '30 días';
  static const String chartRange90d = '90 días';
  static const String servicesFilterLabel = 'Servicios';
  static const String filterAll = 'Todos';

  // Dashboard — weekday short labels (for chart)
  static const String weekdayShortMon = 'Lun';
  static const String weekdayShortTue = 'Mar';
  static const String weekdayShortWed = 'Mié';
  static const String weekdayShortThu = 'Jue';
  static const String weekdayShortFri = 'Vie';
  static const String weekdayShortSat = 'Sáb';
  static const String weekdayShortSun = 'Dom';

  // Dashboard — full weekday names (for date display)
  static const String weekdayMon = 'Lunes';
  static const String weekdayTue = 'Martes';
  static const String weekdayWed = 'Miércoles';
  static const String weekdayThu = 'Jueves';
  static const String weekdayFri = 'Viernes';
  static const String weekdaySat = 'Sábado';
  static const String weekdaySun = 'Domingo';

  // Dashboard — month names
  static const String monthJan = 'Ene';
  static const String monthFeb = 'Feb';
  static const String monthMar = 'Mar';
  static const String monthApr = 'Abr';
  static const String monthMay = 'May';
  static const String monthJun = 'Jun';
  static const String monthJul = 'Jul';
  static const String monthAug = 'Ago';
  static const String monthSep = 'Sep';
  static const String monthOct = 'Oct';
  static const String monthNov = 'Nov';
  static const String monthDec = 'Dic';

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDAR — Calendario
  // ═══════════════════════════════════════════════════════════════════════════

  static const String calendar = 'Calendario';
  static const String month = 'Mes';
  static const String week = 'Semana';
  static const String day = 'Día';
  static const String agenda = 'Agenda';
  static const String previousMonth = 'Mes anterior';
  static const String nextMonth = 'Mes siguiente';
  static const String previousWeek = 'Semana anterior';
  static const String nextWeek = 'Semana siguiente';
  static const String previousDay = 'Día anterior';
  static const String nextDay = 'Día siguiente';
  static const String goToToday = 'Ir a hoy';
  static const String selectDate = 'Seleccionar fecha';
  static const String selectTime = 'Seleccionar hora';
  static const String timeSlot = 'Horario disponible';
  static const String availableSlots = 'Horarios disponibles';
  static const String noAvailableSlots = 'Sin horarios disponibles';
  static const String noAppointments = 'Sin citas';
  static const String noAppointmentsSubtitle =
      'Este día está libre. Agrega una cita para llenar el horario.';
  static const String addTimeBlock = 'Agregar bloqueo de tiempo';
  static const String timeBlock = 'Bloqueo de tiempo';
  static const String blockTime = 'Bloquear tiempo';
  static const String administrativeBlock = 'Bloqueo administrativo';
  static const String scheduleException = 'Excepción de horario';
  static const String holiday = 'Día festivo';
  static const String timeOff = 'Tiempo libre';
  static const String break_ = 'Descanso';
  static const String workingHours = 'Horario de trabajo';
  static const String businessHours = 'Horario del negocio';
  static const String openingTime = 'Hora de apertura';
  static const String closingTime = 'Hora de cierre';
  static const String closed = 'Cerrado';
  static const String open = 'Abierto';
  static const String allDay = 'Todo el día';
  static const String startTime = 'Hora de inicio';
  static const String endTime = 'Hora de fin';
  static const String duration = 'Duración';
  static const String buffer = 'Tiempo de preparación';

  // Calendar — additional strings for L1-B3
  static const String calendarMonthFull = 'Mes';
  static const String calendarWeekFull = 'Semana';
  static const String calendarDayFull = 'Día';
  static const String available = 'Disponible';
  static const String unavailable = 'No disponible';
  static const String blocked = 'Bloqueado';
  static const String viewAppointment = 'Ver cita';
  static const String cancelAppointmentAction = 'Cancelar cita';
  static const String reschedule = 'Reprogramar';
  static const String complete = 'Completar';
  static const String noShow = 'No asistió';
  static const String blockedPeriods = 'Períodos bloqueados';
  static const String tapToSelect = 'Toca las citas para seleccionar';
  static const String selectedCount = 'seleccionadas';
  static const String confirmAll = 'Confirmar todas';
  static const String completeAll = 'Completar todas';
  static const String cancelAll = 'Cancelar todas';
  static const String exitBulkMode = 'Salir del modo selección';
  static const String selectMultiple = 'Seleccionar varias';
  static const String newManualAppointment = 'Nueva cita manual';
  static const String cancelNAppointments = 'Cancelar {n} cita(s)';
  static const String reasonForCancellation = 'Motivo de cancelación...';
  static const String cancelAllAction = 'Cancelar todas';
  static const String appointmentConfirmedMsg = 'Cita confirmada.';
  static const String appointmentCancelledMsg = 'Cita cancelada.';
  static const String timeBlockRemoved = 'Bloqueo de tiempo eliminado.';
  static const String timeBlockCreated = 'Bloqueo de tiempo creado.';
  static const String appointmentCreatedMsg = 'Cita creada correctamente.';
  static const String failedToConfirm = 'Error al confirmar.';
  static const String failedToCancel = 'Error al cancelar.';
  static const String failedToCreate = 'Error al crear.';
  static const String failedToCreateBlock = 'Error al crear el bloqueo.';
  static const String bulkConfirmedMsg = '{n} confirmadas{failed}';
  static const String bulkCancelledMsg = '{n} canceladas{failed}';
  static const String bulkCompletedMsg = '{n} completadas{failed}';
  static const String bulkFailedSuffix = ', {n} fallidas';
  static const String confirmAction = 'Confirmar';
  static const String cancelAction = 'Cancelar';
  static const String viewAction = 'Ver';
  static const String createAction = 'Crear';
  static const String blockAction = 'Bloquear';
  static const String customerNameLabel = 'Nombre del cliente';
  static const String branchIdLabel = 'ID de sucursal';
  static const String branchIdHint = 'UUID de la sucursal';
  static const String serviceIdLabel = 'ID de servicio';
  static const String serviceIdHint = 'UUID del servicio';
  static const String employeeIdLabel = 'ID de profesional';
  static const String employeeIdHint = 'UUID del profesional';
  static const String bookingSourceLabel = 'Fuente de reserva';
  static const String bookingSourceManual = 'Manual';
  static const String bookingSourcePhone = 'Teléfono';
  static const String bookingSourceWhatsApp = 'WhatsApp';
  static const String bookingSourceWalkIn = 'Sin cita previa';
  static const String bookingSourceInstagram = 'Instagram';
  static const String notesOptional = 'Notas (opcional)';
  static const String titleLabel = 'Título';
  static const String titleHint = 'Ej. Almuerzo, Reunión, Mantenimiento';
  static const String titleRequired = 'El título es requerido';
  static const String branchIdRequired = 'El ID de sucursal es requerido';
  static const String startLabel = 'Inicio';
  static const String endLabel = 'Fin';
  static const String reasonOptional = 'Motivo (opcional)';
  static const String fieldIsRequired = '{field} es requerido';
  static const String appts = 'citas';

  // Calendar — full month names (for grid header)
  static const String calMonthJanuary = 'Enero';
  static const String calMonthFebruary = 'Febrero';
  static const String calMonthMarch = 'Marzo';
  static const String calMonthApril = 'Abril';
  static const String calMonthMay = 'Mayo';
  static const String calMonthJune = 'Junio';
  static const String calMonthJuly = 'Julio';
  static const String calMonthAugust = 'Agosto';
  static const String calMonthSeptember = 'Septiembre';
  static const String calMonthOctober = 'Octubre';
  static const String calMonthNovember = 'Noviembre';
  static const String calMonthDecember = 'Diciembre';

  // Calendar — weekday short labels for grid header
  static const String calWeekdayMo = 'Lu';
  static const String calWeekdayTu = 'Ma';
  static const String calWeekdayWe = 'Mi';
  static const String calWeekdayTh = 'Ju';
  static const String calWeekdayFr = 'Vi';
  static const String calWeekdaySa = 'Sá';
  static const String calWeekdaySu = 'Do';

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMERS — Clientes
  // ═══════════════════════════════════════════════════════════════════════════

  static const String customersTitle = 'Clientes';
  static const String customerProfile = 'Perfil del cliente';
  static const String addCustomer = 'Agregar cliente';
  static const String editCustomer = 'Editar cliente';
  static const String deleteCustomer = 'Eliminar cliente';
  static const String searchCustomers = 'Buscar clientes...';
  static const String customerName = 'Nombre del cliente';
  static const String customerEmail = 'Correo del cliente';
  static const String customerPhone = 'Teléfono del cliente';
  static const String customerNotes = 'Notas del cliente';
  static const String appointmentHistory = 'Historial de citas';
  static const String totalVisits = 'Visitas totales';
  static const String lastVisit = 'Última visita';
  static const String firstVisit = 'Primera visita';
  static const String noCustomersFound = 'No se encontraron clientes';
  static const String noCustomersSubtitle =
      'Intenta ajustar tu búsqueda o filtros.';
  static const String newCustomer = 'Nuevo cliente';
  static const String guestCustomer = 'Cliente invitado';
  static const String registeredCustomer = 'Cliente registrado';
  static const String customerSince = 'Cliente desde';
  static const String contactInformation = 'Información de contacto';
  static const String personalInformation = 'Información personal';

  // Customers — additional strings for L1-B4
  static const String customerTotal = 'total';
  static const String customerFilterAll = 'Todos';
  static const String customerFilterActive = 'Activo';
  static const String customerFilterVip = 'VIP';
  static const String customerFilterNew = 'Nuevo';
  static const String customerFilterAtRisk = 'En riesgo';
  static const String customerNoResults = 'No encontramos resultados';
  static const String customerNoResultsSubtitle =
      'Intenta con otro término de búsqueda';
  static const String customerNoCustomers = 'No hay clientes';
  static const String customerNoCustomersSubtitle =
      'Los clientes aparecerán aquí después de su primera reserva';
  static const String customerVisits = 'visitas';
  static const String customerLastVisitLabel = 'Última visita:';
  static const String customerBookAction = 'Reservar';
  static const String customerStatusActive = 'Activo';
  static const String customerStatusAtRisk = 'En riesgo';
  static const String customerStatusNew = 'Nuevo';

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPLOYEES — Empleados
  // ═══════════════════════════════════════════════════════════════════════════

  static const String employees = 'Empleados';
  static const String employee = 'Empleado';
  static const String addEmployee = 'Agregar empleado';
  static const String editEmployee = 'Editar empleado';
  static const String deleteEmployee = 'Eliminar empleado';
  static const String employeeName = 'Nombre del empleado';
  static const String employeeEmail = 'Correo del empleado';
  static const String employeePhone = 'Teléfono del empleado';
  static const String employeeRole = 'Rol del empleado';
  static const String employeeSchedule = 'Horario del empleado';
  static const String employeeServices = 'Servicios del empleado';
  static const String employeeAvailability = 'Disponibilidad del empleado';
  static const String selectEmployee = 'Seleccionar empleado';
  static const String selectStaff = 'Seleccionar personal';
  static const String anyEmployee = 'Cualquier empleado';
  static const String noEmployeesFound = 'No se encontraron empleados';
  static const String noEmployeesSubtitle =
      'Agrega empleados para comenzar a gestionar citas.';
  static const String staffMember = 'Miembro del personal';
  static const String staffSchedule = 'Horario del personal';
  static const String timeOffRequest = 'Solicitud de tiempo libre';
  static const String approveTimeOff = 'Aprobar tiempo libre';
  static const String rejectTimeOff = 'Rechazar tiempo libre';

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICES — Servicios
  // ═══════════════════════════════════════════════════════════════════════════

  static const String services = 'Servicios';
  static const String service = 'Servicio';
  static const String addService = 'Agregar servicio';
  static const String editService = 'Editar servicio';
  static const String deleteService = 'Eliminar servicio';
  static const String serviceName = 'Nombre del servicio';
  static const String serviceDescription = 'Descripción del servicio';
  static const String serviceDuration = 'Duración del servicio';
  static const String servicePrice = 'Precio del servicio';
  static const String serviceCategory = 'Categoría del servicio';
  static const String selectService = 'Seleccionar servicio';
  static const String noServicesFound = 'No se encontraron servicios';
  static const String noServicesSubtitle =
      'Agrega servicios para que los clientes puedan reservar.';
  static const String serviceAvailability = 'Disponibilidad del servicio';
  static const String bufferTime = 'Tiempo de preparación';
  static const String maxCapacity = 'Capacidad máxima';
  static const String onlineBooking = 'Reserva en línea';
  static const String onlineBookingEnabled = 'Reserva en línea habilitada';
  static const String onlineBookingDisabled = 'Reserva en línea deshabilitada';
  static const String price = 'Precio';
  static const String free = 'Gratis';
  static const String priceOnRequest = 'Precio a consultar';

  // ═══════════════════════════════════════════════════════════════════════════
  // BRANCHES — Sucursales
  // ═══════════════════════════════════════════════════════════════════════════

  static const String branches = 'Sucursales';
  static const String branch = 'Sucursal';
  static const String addBranch = 'Agregar sucursal';
  static const String editBranch = 'Editar sucursal';
  static const String deleteBranch = 'Eliminar sucursal';
  static const String branchName = 'Nombre de la sucursal';
  static const String branchAddress = 'Dirección de la sucursal';
  static const String branchPhone = 'Teléfono de la sucursal';
  static const String branchHours = 'Horario de la sucursal';
  static const String selectBranch = 'Seleccionar sucursal';
  static const String noBranchesFound = 'No se encontraron sucursales';
  static const String noBranchesSubtitle =
      'Agrega sucursales para gestionar múltiples ubicaciones.';
  static const String mainBranch = 'Sucursal principal';
  static const String allBranches = 'Todas las sucursales';
  static const String branchLocation = 'Ubicación de la sucursal';
  static const String address = 'Dirección';
  static const String city = 'Ciudad';
  static const String state = 'Estado';
  static const String country = 'País';
  static const String postalCode = 'Código postal';
  static const String timezone = 'Zona horaria';

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS — Configuración
  // ═══════════════════════════════════════════════════════════════════════════

  static const String settings = 'Configuración';
  static const String businessSettings = 'Configuración del negocio';
  static const String businessProfile = 'Perfil del negocio';
  static const String businessName = 'Nombre del negocio';
  static const String businessDescription = 'Descripción del negocio';
  static const String businessCategory = 'Categoría del negocio';
  static const String businessPhone = 'Teléfono del negocio';
  static const String businessEmail = 'Correo del negocio';
  static const String businessWebsite = 'Sitio web del negocio';
  static const String businessAddress = 'Dirección del negocio';
  static const String businessTimezone = 'Zona horaria del negocio';
  static const String bookingSettings = 'Configuración de reservas';
  static const String cancellationPolicy = 'Política de cancelación';
  static const String minimumNotice = 'Aviso mínimo';
  static const String maximumAdvanceBooking = 'Reserva máxima anticipada';
  static const String notifications = 'Notificaciones';
  static const String notificationSettings = 'Configuración de notificaciones';
  static const String emailNotifications = 'Notificaciones por correo';
  static const String smsNotifications = 'Notificaciones por SMS';
  static const String reminderNotifications = 'Recordatorios';
  static const String subscription = 'Suscripción';
  static const String dangerZone = 'Zona de riesgo';
  static const String deleteAccount = 'Eliminar cuenta';
  static const String deleteBusiness = 'Eliminar negocio';
  static const String branding = 'Identidad de marca';
  static const String logo = 'Logotipo';
  static const String coverImage = 'Imagen de portada';
  static const String gallery = 'Galería';
  static const String profilePicture = 'Foto de perfil';
  static const String language = 'Idioma';
  static const String currency = 'Moneda';
  static const String dateFormat = 'Formato de fecha';
  static const String timeFormat = 'Formato de hora';
  static const String saveChanges = 'Guardar cambios';
  static const String changesSaved = 'Cambios guardados';
  static const String unsavedChanges = 'Cambios sin guardar';
  static const String discardChanges = 'Descartar cambios';

  // Settings — additional strings for L1-B4
  static const String settingsSidebarTitle = 'Configuración';
  static const String settingsSectionBusinessProfile = 'Perfil del negocio';
  static const String settingsSectionBranches = 'Sucursales';
  static const String settingsSectionServices = 'Servicios';
  static const String settingsSectionEmployees = 'Profesionales';
  static const String settingsSectionBusinessHours = 'Horario del negocio';
  static const String settingsSectionBookingSettings =
      'Configuración de reservas';
  static const String settingsSectionHolidaysExceptions =
      'Días festivos y excepciones';
  static const String settingsSectionNotifications = 'Notificaciones';
  static const String settingsSectionSubscription = 'Suscripción';
  static const String settingsSectionBranding = 'Identidad de marca';
  static const String settingsSectionDangerZone = 'Zona de riesgo';

  // Business Profile widget
  static const String settingsBizProfileTitle = 'Perfil del negocio';
  static const String settingsBizNameLabel = 'Nombre del negocio';
  static const String settingsBizDescriptionLabel = 'Descripción';
  static const String settingsBizDescriptionHint = 'Describe tu negocio...';
  static const String settingsBizPhoneLabel = 'Teléfono';
  static const String settingsBizEmailLabel = 'Correo electrónico';
  static const String settingsBizWebsiteLabel = 'Sitio web';
  static const String settingsBizAddressLabel = 'Dirección';
  static const String settingsBizCityLabel = 'Ciudad';
  static const String settingsBizCountryLabel = 'País';
  static const String settingsBizTimezoneLabel = 'Zona horaria';
  static const String settingsBizSaveButton = 'Guardar perfil del negocio';
  static const String settingsBizProfileUpdated =
      'Perfil del negocio actualizado';
  static const String settingsBizProfileSaveFailed = 'Error al guardar';

  // Branch Manager
  static const String settingsBranchManagerTitle = 'Gestión de sucursales';
  static const String settingsBranchManagerSubtitle =
      'Administra las ubicaciones de tu negocio';
  static const String settingsAddBranch = 'Agregar sucursal';
  static const String settingsNoBranchesTitle = 'Aún no hay sucursales';
  static const String settingsNoBranchesSubtitle =
      'Agrega tu primera sucursal para comenzar';
  static const String settingsBranchSaved = 'Sucursal guardada';
  static const String settingsBranchSaveFailed = 'Error al guardar';
  static const String settingsBranchCoverImage =
      'Imagen de portada de sucursal';
  static const String settingsBranchImageTooltip = 'Imagen de sucursal';

  // Branch Dialog
  static const String settingsBranchDialogAdd = 'Agregar sucursal';
  static const String settingsBranchDialogEdit = 'Editar sucursal';
  static const String settingsBranchNameField = 'Nombre de la sucursal *';
  static const String settingsBranchAddressField = 'Dirección';
  static const String settingsBranchCityField = 'Ciudad';
  static const String settingsBranchCountryField = 'País';
  static const String settingsBranchPhoneField = 'Teléfono';
  static const String settingsBranchEmailField = 'Correo electrónico';

  // Services Manager
  static const String settingsServicesManagerTitle = 'Gestión de servicios';
  static const String settingsServicesManagerSubtitle =
      'Configura los servicios que ofrece tu negocio';
  static const String settingsAddService = 'Agregar servicio';
  static const String settingsNoServicesTitle = 'Aún no hay servicios';
  static const String settingsNoServicesSubtitle =
      'Agrega tu primer servicio para comenzar a recibir reservas';
  static const String settingsServiceSaved = 'Servicio guardado';
  static const String settingsServiceSaveFailed = 'Error al guardar';
  static const String settingsServiceImageLabel = 'Imagen del servicio';
  static const String settingsServiceImageSubtitle =
      'Se muestra a los clientes al reservar este servicio';
  static const String settingsServiceImageTooltip = 'Imagen del servicio';

  // Service Dialog
  static const String settingsServiceDialogAdd = 'Agregar servicio';
  static const String settingsServiceDialogEdit = 'Editar servicio';
  static const String settingsServiceNameField = 'Nombre del servicio *';
  static const String settingsServiceDescField = 'Descripción';
  static const String settingsServicePriceField = 'Precio de exhibición';
  static const String settingsServiceDurationField = 'Duración (minutos)';
  static const String settingsServiceBufferBeforeField =
      'Tiempo de preparación (min)';
  static const String settingsServiceBufferAfterField =
      'Tiempo posterior (min)';
  static const String settingsServiceActiveLabel = 'Activo';
  static const String settingsServiceActiveSubtitle =
      'El servicio está disponible para reservas';

  // Employees Manager
  static const String settingsEmployeesManagerTitle =
      'Gestión de profesionales';
  static const String settingsEmployeesManagerSubtitle =
      'Administra personal, horarios, descansos y ausencias';
  static const String settingsAddEmployee = 'Agregar profesional';
  static const String settingsNoEmployeesTitle = 'Aún no hay profesionales';
  static const String settingsNoEmployeesSubtitle =
      'Agrega profesionales para asignar servicios y horarios';
  static const String settingsEmployeeSaved = 'Profesional guardado';
  static const String settingsEmployeeSaveFailed = 'Error al guardar';
  static const String settingsEmployeeBookable = 'Disponible para reservas';
  static const String settingsEmployeeBookableSubtitle =
      'Los clientes pueden reservar con este profesional';
  static const String settingsEmployeeActiveLabel = 'Activo';
  static const String settingsEmployeeActiveSubtitle =
      'El profesional está trabajando actualmente';

  // Employee Dialog
  static const String settingsEmployeeDialogAdd = 'Agregar profesional';
  static const String settingsEmployeeDialogEdit = 'Editar profesional';
  static const String settingsEmployeeFirstNameField = 'Nombre *';
  static const String settingsEmployeeLastNameField = 'Apellido *';
  static const String settingsEmployeeEmailField = 'Correo electrónico';
  static const String settingsEmployeePhoneField = 'Teléfono';
  static const String settingsEmployeeTitleField = 'Título / Rol';

  // Employee Schedule Panel
  static const String settingsTabWorkingHours = 'Horario laboral';
  static const String settingsTabBreaks = 'Descansos';
  static const String settingsTabTimeOff = 'Ausencias';
  static const String settingsNoWorkingHours =
      'Sin horario laboral configurado';
  static const String settingsSaveWorkingHours = 'Guardar horario laboral';
  static const String settingsWorkingHoursSaved = 'Horario laboral guardado';
  static const String settingsAddBreak = 'Agregar descanso';
  static const String settingsNoBreaks = 'Sin descansos configurados';
  static const String settingsBreakAdded = 'Descanso agregado';
  static const String settingsAddTimeOff = 'Agregar ausencia';
  static const String settingsNoTimeOff = 'Sin ausencias próximas';
  static const String settingsTimeOffAdded = 'Ausencia agregada';
  static const String settingsAllDays = 'Todos los días';

  // Break Dialog
  static const String settingsBreakDialogTitle = 'Agregar descanso';
  static const String settingsBreakNameField = 'Nombre del descanso';
  static const String settingsBreakDayField =
      'Día (dejar vacío para todos los días)';
  static const String settingsBreakStartField = 'Inicio';
  static const String settingsBreakEndField = 'Fin';
  static const String settingsBreakAddButton = 'Agregar descanso';

  // Time Off Dialog
  static const String settingsTimeOffDialogTitle = 'Agregar ausencia';
  static const String settingsTimeOffTypeField = 'Tipo';
  static const String settingsTimeOffReasonField = 'Motivo (opcional)';
  static const String settingsTimeOffAddButton = 'Agregar ausencia';

  // Business Hours Section
  static const String settingsBusinessHoursTitle = 'Horario del negocio';
  static const String settingsBusinessHoursSubtitle =
      'Define cuándo está abierto tu negocio para citas';
  static const String settingsSaveBusinessHours = 'Guardar horario del negocio';
  static const String settingsBusinessHoursSaved =
      'Horario del negocio guardado';
  static const String settingsWorkingLabel = 'Abierto';
  static const String settingsClosedLabel = 'Cerrado';
  static const String settingsOffLabel = 'Libre';

  // Booking Settings Section
  static const String settingsBookingTitle = 'Configuración de reservas';
  static const String settingsBookingSubtitle =
      'Controla cómo los clientes pueden reservar citas';
  static const String settingsSaveBookingSettings =
      'Guardar configuración de reservas';
  static const String settingsBookingSettingsSaved =
      'Configuración de reservas guardada';
  static const String settingsOnlineBookingSection = 'Reservas en línea';
  static const String settingsEnablePublicBooking =
      'Habilitar reservas públicas';
  static const String settingsEnablePublicBookingSubtitle =
      'Permite que los clientes reserven en línea';
  static const String settingsAllowGuestBooking = 'Reservas sin registro';
  static const String settingsAllowGuestBookingSubtitle =
      'Los clientes pueden reservar sin una cuenta';
  static const String settingsAutoConfirm = 'Confirmación automática';
  static const String settingsAutoConfirmSubtitle =
      'Confirma automáticamente las nuevas citas';
  static const String settingsMinNoticeLabel = 'Anticipación mínima (horas)';
  static const String settingsMinNoticeSubtitle =
      'Horas mínimas de anticipación para reservar';
  static const String settingsMaxHorizonLabel =
      'Anticipación máxima para reservar (días)';
  static const String settingsMaxHorizonSubtitle =
      'Con cuánta anticipación pueden reservar los clientes';
  static const String settingsSlotDurationLabel =
      'Duración de intervalo (minutos)';
  static const String settingsAllowReschedule = 'Permitir reprogramaciones';
  static const String settingsAllowRescheduleSubtitle =
      'Los clientes pueden reprogramar sus citas';
  static const String settingsRescheduleNoticeLabel =
      'Aviso de reprogramación (horas)';
  static const String settingsMaxReschedulesLabel =
      'Máximo de reprogramaciones';
  static const String settingsCancellationSection = 'Política de cancelación';
  static const String settingsAllowCancellations = 'Permitir cancelaciones';
  static const String settingsAllowCancellationsSubtitle =
      'Los clientes pueden cancelar sus citas';
  static const String settingsCancellationNoticeLabel =
      'Aviso de cancelación (horas)';
  static const String settingsCancellationFeeLabel = 'Cargo por cancelación';
  static const String settingsNoShowFeeLabel = 'Cargo por no presentarse';

  // Holidays & Exceptions Section
  static const String settingsHolidaysTitle = 'Días festivos y excepciones';
  static const String settingsHolidaysSubtitle =
      'Modifica el horario para fechas específicas sin cambiar tu horario regular';
  static const String settingsAddException = 'Agregar excepción';
  static const String settingsNoExceptionsTitle =
      'Sin excepciones configuradas';
  static const String settingsNoExceptionsSubtitle =
      'Agrega días festivos u horarios modificados para fechas específicas';
  static const String settingsExceptionAdded = 'Excepción agregada';
  static const String settingsExceptionRemoved = 'Excepción eliminada';

  // Exception Dialog
  static const String settingsExceptionDialogTitle =
      'Agregar día festivo / excepción';
  static const String settingsExceptionTypeField = 'Tipo';
  static const String settingsExceptionClosedAllDay = 'Cerrado todo el día';
  static const String settingsExceptionOpenField = 'Apertura';
  static const String settingsExceptionCloseField = 'Cierre';
  static const String settingsExceptionReasonField = 'Motivo (ej. Navidad)';
  static const String settingsExceptionAddButton = 'Agregar excepción';
  static const String settingsExceptionTypeHoliday = 'Día festivo';
  static const String settingsExceptionTypeClosed = 'Cierre del negocio';
  static const String settingsExceptionTypeModified = 'Horario modificado';
  static const String settingsExceptionClosedLabel = 'Cerrado';

  // Notifications Widget
  static const String settingsNotificationsTitle =
      'Notificaciones por correo electrónico';
  static const String settingsNotificationsInfoBanner =
      'Las notificaciones por correo se envían a través de Resend. Configura los secretos en los ajustes de tu Edge Function de Supabase.';
  static const String settingsApptNotificationsSection =
      'Notificaciones de citas';
  static const String settingsApptNotificationsMaster =
      'Notificaciones de citas';
  static const String settingsApptNotificationsMasterSubtitle =
      'Interruptor principal para todos los correos de citas';
  static const String settingsNewBookingAlert = 'Alerta de nueva reserva';
  static const String settingsNewBookingAlertSubtitle =
      'Recibe un correo cuando se reserve una nueva cita';
  static const String settingsCancellationAlert = 'Alerta de cancelación';
  static const String settingsCancellationAlertSubtitle =
      'Recibe un correo cuando un cliente cancele';
  static const String settingsApptReminders = 'Recordatorios de citas';
  static const String settingsApptRemindersSubtitle =
      'Envía recordatorios por correo a los clientes (24h y 2h antes)';
  static const String settingsDailySummarySection = 'Resumen diario';
  static const String settingsDailySummaryToggle = 'Resumen diario de citas';
  static const String settingsDailySummarySubtitle =
      'Recibe un resumen de las citas de hoy a las 7:00 AM hora local';
  static const String settingsSummaryRecipientLabel =
      'Correo electrónico del destinatario';
  static const String settingsSummaryRecipientHint =
      'Dejar en blanco para usar el correo del propietario del negocio';
  static const String settingsSummaryDeliveryNote =
      'Entregado a más tardar a las 7:00 AM en la zona horaria de tu negocio';
  static const String settingsSaveNotifications =
      'Guardar configuración de notificaciones';

  // Branding Widget
  static const String settingsBrandingTitle = 'Identidad de marca';
  static const String settingsBrandingSubtitle =
      'Administra la identidad visual de tu negocio';
  static const String settingsBrandingLogoTitle = 'Logotipo del negocio';
  static const String settingsBrandingLogoSubtitle =
      'Se muestra en tu perfil público y resultados de búsqueda';
  static const String settingsBrandingCoverTitle = 'Imagen de portada';
  static const String settingsBrandingCoverSubtitle =
      'El banner que aparece en la parte superior de tu página de perfil';
  static const String settingsBrandingGalleryTitle = 'Galería de fotos';
  static const String settingsBrandingGallerySubtitle =
      'Muestra tu negocio con hasta 12 fotos';
  static const String settingsBrandingUploadLabel = 'Subir';
  static const String settingsBrandingReplaceLabel = 'Reemplazar';
  static const String settingsBrandingRemoveLabel = 'Eliminar';
  static const String settingsBrandingFileHint = 'JPEG, PNG o WebP · Máx. 5 MB';
  static const String settingsBrandingGalleryFileHint =
      'JPEG, PNG o WebP · Máx. 5 MB por foto';
  static const String settingsBrandingAddPhotos = 'Agregar fotos';
  static const String settingsBrandingAddMorePhotos = 'Agregar más fotos';
  static const String settingsBrandingMaxPhotos =
      'Se alcanzó el máximo de 12 fotos';
  static const String settingsBrandingUploadSuccess =
      'Imagen subida correctamente';
  static const String settingsBrandingUploadFailed = 'Error al subir';
  static const String settingsBrandingRemoveSuccess = 'Imagen eliminada';
  static const String settingsBrandingRemoveFailed = 'Error al eliminar';
  static const String settingsBrandingPhotoAdded = 'Foto agregada a la galería';
  static const String settingsBrandingPickError =
      'No se pudo seleccionar el archivo:';
  static const String settingsBrandingNoLogo = 'Sin logotipo subido';
  static const String settingsBrandingNoCover = 'Sin imagen de portada subida';
  static const String settingsBrandingNoImage = 'Sin imagen';
  static const String settingsBrandingGalleryPhoto = 'Foto de galería';
  static const String settingsBrandingRemoveDialogTitle = 'Eliminar';
  static const String settingsBrandingRemoveDialogContent =
      'Esto eliminará permanentemente la imagen de tu perfil.';
  static const String settingsBrandingRemovePhotoTitle = '¿Eliminar foto?';
  static const String settingsBrandingRemovePhotoContent =
      'Esta foto se eliminará permanentemente.';

  // Subscription Widget
  static const String settingsSubscriptionTitle = 'Suscripción';
  static const String settingsSubscriptionActive = 'Activo';
  static const String settingsSubscriptionPerMonth = '/mes';
  static const String settingsSubscriptionUpgradeTitle =
      'Actualizar a Empresarial';
  static const String settingsSubscriptionUpgradeSubtitle =
      'Marca blanca, acceso a API e ilimitado en todo';
  static const String settingsSubscriptionUpgradeButton = 'Actualizar';
  static const String settingsSubscriptionFeature1 = 'Reservas ilimitadas';
  static const String settingsSubscriptionFeature2 = 'Reportes avanzados';
  static const String settingsSubscriptionFeature3 = 'Múltiples sucursales';
  static const String settingsSubscriptionFeature4 =
      'Herramientas de marketing';
  static const String settingsSubscriptionFeature5 = 'Soporte prioritario';

  // Danger Zone Widget
  static const String settingsDangerZoneTitle = 'Zona de riesgo';
  static const String settingsSignOutTitle = 'Cerrar sesión';
  static const String settingsSignOutSubtitle =
      'Cerrar sesión en este dispositivo';
  static const String settingsSignOutConfirmTitle = 'Cerrar sesión';
  static const String settingsSignOutConfirmMessage =
      '¿Estás seguro de que deseas cerrar sesión?';
  static const String settingsDeleteBusinessTitle =
      'Eliminar cuenta del negocio';
  static const String settingsDeleteBusinessSubtitle =
      'Elimina permanentemente todos los datos. Esta acción no se puede deshacer.';
  static const String settingsDeleteBusinessConfirmTitle =
      'Eliminar cuenta del negocio';
  static const String settingsDeleteBusinessConfirmMessage =
      'Esto eliminará permanentemente tu negocio, todas las citas, datos de clientes y no se puede revertir. ¿Estás absolutamente seguro?';
  static const String settingsDeleteBusinessToast =
      'Eliminación de cuenta solicitada. Nuestro equipo procesará esto en 24 horas.';
  static const String settingsDangerConfirmButton = 'Confirmar';

  // Shared dialog actions
  static const String dialogSave = 'Guardar';
  static const String dialogCancel = 'Cancelar';
  static const String dialogAdd = 'Agregar';
  static const String dialogRemove = 'Eliminar';
  static const String dialogConfirm = 'Confirmar';
  static const String dialogFailed = 'Error';

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING — Incorporación
  // ═══════════════════════════════════════════════════════════════════════════

  static const String onboarding = 'Configuración inicial';
  static const String welcomeToOnboarding = 'Bienvenido a ReserveHub';
  static const String onboardingSubtitle =
      'Configura tu negocio en pocos pasos y comienza a recibir reservas.';
  static const String setupYourBusiness = 'Configura tu negocio';
  static const String setupOrganization = 'Configura tu organización';
  static const String setupBranch = 'Configura tu sucursal';
  static const String setupHours = 'Configura tu horario';
  static const String setupServices = 'Configura tus servicios';
  static const String setupEmployees = 'Configura tu equipo';
  static const String setupBookingSettings = 'Configura las reservas';
  static const String reviewAndFinish = 'Revisar y finalizar';
  static const String stepOf = 'Paso {current} de {total}';
  static const String organizationStep = 'Organización';
  static const String businessStep = 'Negocio';
  static const String branchStep = 'Sucursal';
  static const String hoursStep = 'Horario';
  static const String servicesStep = 'Servicios';
  static const String employeesStep = 'Equipo';
  static const String bookingStep = 'Reservas';
  static const String reviewStep = 'Revisión';
  static const String onboardingComplete = '¡Configuración completada!';
  static const String onboardingCompleteSubtitle =
      'Tu negocio está listo para recibir reservas.';
  static const String goToDashboard = 'Ir al panel';
  static const String organizationName = 'Nombre de la organización';
  static const String organizationDescription =
      'Descripción de la organización';
  static const String letsGetStarted = 'Comencemos';
  static const String almostDone = '¡Casi listo!';
  static const String skipForNow = 'Omitir por ahora';
  static const String addLater = 'Agregar después';

  // Onboarding step titles & subtitles
  static const String obStepTitleOrganization = 'Tu Organización';
  static const String obStepSubtitleOrganization =
      'Una organización es la cuenta principal que puede contener múltiples negocios.';
  static const String obStepTitleBusiness = 'Tu Negocio';
  static const String obStepSubtitleBusiness =
      'Configura el perfil de tu negocio. Esto es lo que verán los clientes.';
  static const String obStepTitleBranch = 'Tu Primera Ubicación';
  static const String obStepSubtitleBranch =
      'Agrega tu sucursal principal. Puedes agregar más ubicaciones desde el panel.';
  static const String obStepTitleServices = 'Tus Servicios';
  static const String obStepSubtitleServices =
      'Agrega los servicios que ofrece tu negocio. Puedes editarlos después.';
  static const String obStepTitleEmployees = 'Tu Equipo';
  static const String obStepSubtitleEmployees =
      'Agrega los profesionales que brindarán servicios. Puedes gestionar tu equipo desde el panel.';
  static const String obStepTitleHours = 'Horario del Negocio';
  static const String obStepSubtitleHours =
      'Define cuándo está abierto tu negocio. Estos horarios afectan la disponibilidad pública.';
  static const String obStepTitleBookingSettings = 'Configuración de Reservas';
  static const String obStepSubtitleBookingSettings =
      'Configura cómo los clientes pueden reservar citas. Puedes cambiar estos ajustes después.';
  static const String obStepTitleReview = 'Revisar y Publicar';
  static const String obStepSubtitleReview =
      'Revisa tu configuración antes de hacer público tu negocio.';

  // Onboarding — Organization section labels
  static const String obOrganizationDetails = 'Detalles de la Organización';
  static const String obRegionalSettings = 'Configuración Regional';
  static const String obOrganizationNameLabel = 'Nombre de la organización';
  static const String obOrganizationNameHint =
      'Ej. Corporación Acme, Negocios Familia García';
  static const String obOrganizationNameRequired =
      'El nombre de la organización es requerido';
  static const String obContactEmail = 'Correo electrónico de contacto';
  static const String obContactEmailHint = 'admin@tuempresa.com';
  static const String obDefaultTimezone = 'Zona horaria predeterminada';

  // Onboarding — Business section labels
  static const String obBusinessProfile = 'Perfil del Negocio';
  static const String obBusinessNameLabel = 'Nombre del negocio';
  static const String obBusinessNameHint = 'Ej. Salón Centro, Barbería Ciudad';
  static const String obBusinessNameRequired =
      'El nombre del negocio es requerido';
  static const String obPublicUrlSlug = 'Identificador del negocio';
  static const String obPublicUrlSlugHint = 'nombre-de-tu-negocio';
  static const String obSlugRequired = 'El identificador es requerido';
  static const String obSlugInvalidChars =
      'Solo letras minúsculas, números y guiones';
  static const String obSlugTaken = 'Este identificador ya está en uso';
  static const String obSlugHelperText =
      'Este es tu enlace público de reservas';
  static const String obDescriptionHint =
      'Cuéntales a los clientes qué hace especial a tu negocio...';
  static const String obContactInformation = 'Información de Contacto';
  static const String obBusinessPhoneHint = '+52 55 0000 0000';
  static const String obBusinessEmailHint = 'hola@tunegocio.com';
  static const String obWebsite = 'Sitio web';
  static const String obWebsiteHint = 'https://tunegocio.com';
  static const String obBusinessTimezone = 'Zona horaria del negocio';

  // Onboarding — Branch section labels
  static const String obBranchDetails = 'Detalles de la Sucursal';
  static const String obContactAndTimezone = 'Contacto y Zona Horaria';
  static const String obBranchNameLabel = 'Nombre de la sucursal';
  static const String obBranchNameHint = 'Ej. Sucursal Principal, Sede Centro';
  static const String obBranchNameRequired =
      'El nombre de la sucursal es requerido';
  static const String obStreetAddress = 'Dirección';
  static const String obStreetAddressHint = 'Calle Principal 123';
  static const String obCityHint = 'Ciudad de México';
  static const String obCountryHint = 'México';
  static const String obBranchPhoneHint = '+52 55 0000 0000';
  static const String obBranchEmailHint = 'sucursal@tunegocio.com';
  static const String obBranchTimezone = 'Zona horaria de la sucursal';

  // Onboarding — Services section labels
  static const String obNoServicesYet = 'Aún no hay servicios';
  static const String obNoServicesSubtitle =
      'Agrega los servicios que ofreces a tus clientes';
  static const String obAddFirstService = 'Agregar tu primer servicio';
  static const String obAddService = 'Agregar servicio';
  static const String obServiceNameLabel = 'Nombre del servicio';
  static const String obServiceNameHint =
      'Ej. Corte de cabello, Masaje, Consulta';
  static const String obServiceNameRequired =
      'El nombre del servicio es requerido';
  static const String obServiceDescriptionHint =
      'Breve descripción de este servicio...';
  static const String obDurationMin = 'Duración (min)';
  static const String obBufferBefore = 'Tiempo de preparación (min)';
  static const String obBufferAfter = 'Tiempo posterior (min)';
  static const String obDisplayPrice = 'Precio de exhibición';
  static const String obStatus = 'Estado';
  static const String obMustBeGreaterThanZero = 'Debe ser mayor a 0';
  static const String obMustBeZeroOrMore = 'Debe ser 0 o más';
  static const String obDeleteServiceTitle = 'Eliminar servicio';
  static const String obDeleteServiceConfirm = '¿Eliminar "{name}"?';
  static const String obSaveService = 'Guardar servicio';
  static const String obEditServiceTitle = 'Editar servicio';
  static const String obAddServiceTitle = 'Agregar servicio';

  // Onboarding — Employees section labels
  static const String obNoEmployeesYet = 'Aún no hay profesionales';
  static const String obNoEmployeesSubtitle =
      'Agrega los profesionales que brindarán servicios a los clientes';
  static const String obAddFirstEmployee = 'Agregar tu primer profesional';
  static const String obAddEmployee = 'Agregar profesional';
  static const String obAddEmployeeTitle = 'Agregar profesional';
  static const String obEditEmployeeTitle = 'Editar profesional';
  static const String obNoServicesAssigned = 'Sin servicios asignados';
  static const String obAssignedServices = 'Servicios asignados';
  static const String obFirstName = 'Nombre';
  static const String obFirstNameHint = 'Ana';
  static const String obLastName = 'Apellido';
  static const String obLastNameHint = 'García';
  static const String obEmployeeEmailHint = 'ana@tunegocio.com';
  static const String obEmployeePhoneHint = '+52 55 0000 0000';
  static const String obBookable = 'Disponible para reservas';
  static const String obSaveEmployee = 'Guardar profesional';
  static const String obFieldRequired = 'Requerido';
  static const String obInvalidEmail = 'Ingresa un correo válido';

  // Onboarding — Hours section labels
  static const String obWeeklySchedule = 'Horario Semanal';

  // Day names (used in hours step)
  static const String daySunday = 'Domingo';
  static const String dayMonday = 'Lunes';
  static const String dayTuesday = 'Martes';
  static const String dayWednesday = 'Miércoles';
  static const String dayThursday = 'Jueves';
  static const String dayFriday = 'Viernes';
  static const String daySaturday = 'Sábado';

  // Onboarding — Booking settings labels
  static const String obOnlineBookingSection = 'Reservas en Línea';
  static const String obEnableOnlineBooking = 'Habilitar reservas en línea';
  static const String obEnableOnlineBookingSubtitle =
      'Permite que los clientes reserven citas en línea';
  static const String obAllowGuestBooking = 'Reservas sin registro';
  static const String obAllowGuestBookingSubtitle =
      'Los clientes pueden reservar sin crear una cuenta';
  static const String obShowEmployeeSelection =
      'Mostrar selección de profesional';
  static const String obShowEmployeeSelectionSubtitle =
      'Permite que los clientes elijan su profesional preferido';
  static const String obShowServicePrices = 'Mostrar precios de servicios';
  static const String obShowServicePricesSubtitle =
      'Muestra los precios en la página de reservas';
  static const String obConfirmationSection = 'Confirmación';
  static const String obAutoConfirm = 'Confirmación automática';
  static const String obAutoConfirmSubtitle =
      'Las citas se confirman de inmediato. Desactiva para requerir aprobación manual.';
  static const String obBookingWindowSection = 'Ventana de Reservas';
  static const String obMinimumNotice = 'Anticipación mínima';
  static const String obMinimumNoticeSubtitle =
      'Horas mínimas de anticipación para reservar una cita';
  static const String obMaximumHorizon = 'Anticipación máxima para reservar';
  static const String obMaximumHorizonSubtitle =
      'Con cuánta anticipación pueden reservar los clientes';
  static const String obCancellationPolicySection = 'Política de Cancelación';
  static const String obAllowCancellations = 'Permitir cancelaciones';
  static const String obAllowCancellationsSubtitle =
      'Los clientes pueden cancelar sus citas';
  static const String obCancellationNotice = 'Aviso de cancelación';
  static const String obCancellationNoticeSubtitle =
      'Horas mínimas de anticipación para cancelar una cita';
  static const String obAllowRescheduling = 'Permitir reprogramaciones';
  static const String obAllowReschedulingSubtitle =
      'Los clientes pueden reprogramar sus citas';
  static const String obUnitHours = 'horas';
  static const String obUnitDays = 'días';

  // Onboarding — Review section labels
  static const String obBusinessSetup = 'Configuración del Negocio';
  static const String obBusinessIsLive = 'Negocio publicado';
  static const String obBusinessIsLiveSubtitle =
      'Tu negocio es visible públicamente';
  static const String obDraftMode =
      'Tu negocio está en modo borrador. Publícalo para que los clientes puedan reservar.';
  static const String obReviewOrganization = 'Organización';
  static const String obReviewBusiness = 'Negocio';
  static const String obReviewBranch = 'Sucursal';
  static const String obReviewServices = 'Servicios';
  static const String obReviewEmployees = 'Profesionales';
  static const String obReviewHours = 'Horario';
  static const String obReviewBookingSettings = 'Configuración de Reservas';
  static const String obReviewName = 'Nombre';
  static const String obReviewEmail = 'Correo';
  static const String obReviewTimezone = 'Zona horaria';
  static const String obReviewCurrency = 'Moneda';
  static const String obReviewUrl = 'Enlace';
  static const String obReviewPhone = 'Teléfono';
  static const String obReviewAddress = 'Dirección';
  static const String obReviewCity = 'Ciudad';
  static const String obReviewCountry = 'País';
  static const String obReviewStatus = 'Estado';
  static const String obReviewNoServicesYet =
      'Aún no se han agregado servicios';
  static const String obReviewNoEmployeesYet =
      'Aún no se han agregado profesionales';
  static const String obReviewOnlineBooking = 'Reservas en línea';
  static const String obReviewConfirmation = 'Confirmación';
  static const String obReviewMinNotice = 'Anticipación mínima';
  static const String obReviewMaxHorizon = 'Anticipación máxima';
  static const String obReviewCancellations = 'Cancelaciones';
  static const String obReviewEnabled = 'Habilitado';
  static const String obReviewDisabled = 'Deshabilitado';
  static const String obReviewAutoConfirm = 'Confirmación automática';
  static const String obReviewManualApproval = 'Aprobación manual';
  static const String obReviewAllowed = 'Permitidas';
  static const String obReviewNotAllowed = 'No permitidas';
  static const String obServicesAssigned = 'servicio(s) asignado(s)';
  static const String obReadyToGoLive = '¿Listo para publicar?';
  static const String obReadyToGoLiveSubtitle =
      'Al publicar, tu negocio será visible públicamente y los clientes podrán reservar citas.';
  static const String obPublishBusiness = 'Publicar negocio';
  static const String obBusinessPublishedTitle = '¡Negocio Publicado!';
  static const String obBusinessPublishedSubtitle =
      'Tu negocio está activo y visible públicamente. Los clientes ya pueden reservar citas.';

  // Onboarding — AppBar / sidebar
  static const String obBusinessSetupLabel = 'Configuración del negocio';
  static const String obStepIndicator = 'Paso {step} de {total}';
  static const String obProgressComplete = '% completado';

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS — Citas
  // ═══════════════════════════════════════════════════════════════════════════

  static const String appointment = 'Cita';
  static const String appointments = 'Citas';
  static const String bookAppointment = 'Reservar cita';
  static const String confirmAppointment = 'Confirmar cita';
  static const String cancelAppointment = 'Cancelar cita';
  static const String rescheduleAppointment = 'Reprogramar cita';
  static const String appointmentDetails = 'Detalles de la cita';
  static const String appointmentDate = 'Fecha de la cita';
  static const String appointmentTime = 'Hora de la cita';
  static const String appointmentDuration = 'Duración de la cita';
  static const String appointmentStatus = 'Estado de la cita';
  static const String appointmentNotes = 'Notas de la cita';
  static const String appointmentConfirmed = 'Cita confirmada';
  static const String appointmentCancelled = 'Cita cancelada';
  static const String appointmentCompleted = 'Cita completada';
  static const String appointmentPending = 'Cita pendiente';
  static const String appointmentInProgress = 'Cita en progreso';
  static const String appointmentNoShow = 'No se presentó';
  static const String appointmentRescheduled = 'Cita reprogramada';
  static const String statusPending = 'Pendiente';
  static const String statusConfirmed = 'Confirmada';
  static const String statusInProgress = 'En progreso';
  static const String statusCompleted = 'Completada';
  static const String statusCancelled = 'Cancelada';
  static const String statusNoShow = 'No se presentó';
  static const String statusRescheduled = 'Reprogramada';
  static const String markAsConfirmed = 'Marcar como confirmada';
  static const String markAsCompleted = 'Marcar como completada';
  static const String markAsNoShow = 'Marcar como no presentado';
  static const String startAppointment = 'Iniciar cita';
  static const String completeAppointment = 'Completar cita';
  static const String confirmCancellation = 'Confirmar cancelación';
  static const String cancellationReason = 'Motivo de cancelación';
  static const String rescheduleReason = 'Motivo de reprogramación';
  static const String newDate = 'Nueva fecha';
  static const String newTime = 'Nueva hora';
  static const String selectNewTime = 'Seleccionar nueva hora';
  static const String bookingToken = 'Token de reserva';
  static const String manageAppointment = 'Gestionar cita';
  static const String appointmentToken = 'Token de cita';

  // ═══════════════════════════════════════════════════════════════════════════
  // ERRORS — Errores
  // ═══════════════════════════════════════════════════════════════════════════

  static const String genericError =
      'Algo salió mal. Por favor, inténtalo de nuevo.';
  static const String networkError = 'Sin conexión a internet.';
  static const String networkErrorSubtitle =
      'Verifica tu conexión e inténtalo de nuevo.';
  static const String sessionExpired =
      'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.';
  static const String unauthorizedError =
      'No tienes permiso para realizar esta acción.';
  static const String notFoundError =
      'El recurso solicitado no fue encontrado.';
  static const String serverError =
      'Error del servidor. Por favor, inténtalo más tarde.';
  static const String timeoutError =
      'La solicitud tardó demasiado. Inténtalo de nuevo.';
  static const String uploadError =
      'Error al subir el archivo. Inténtalo de nuevo.';
  static const String invalidTokenError =
      'El enlace es inválido o ha expirado.';
  static const String slotUnavailableError =
      'Este horario ya no está disponible. Por favor, selecciona otro.';
  static const String concurrentModificationError =
      'Otro usuario modificó esta cita. Por favor, recarga e inténtalo de nuevo.';
  static const String bookingConflictError =
      'Ya existe una cita en este horario. Por favor, selecciona otro.';
  static const String cancellationPolicyError =
      'No es posible cancelar con tan poco tiempo de anticipación.';
  static const String invalidCredentialsError =
      'Correo o contraseña incorrectos.';
  static const String emailAlreadyInUseError =
      'Este correo ya está registrado. Intenta iniciar sesión.';
  static const String weakPasswordError =
      'La contraseña es demasiado débil. Usa al menos 8 caracteres.';
  static const String formError =
      'Por favor, corrige los errores en el formulario.';

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION — Validación
  // ═══════════════════════════════════════════════════════════════════════════

  static const String fieldRequired = 'Este campo es requerido.';
  static const String invalidEmail = 'Ingresa un correo electrónico válido.';
  static const String invalidPhone = 'Ingresa un número de teléfono válido.';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden.';
  static const String nameTooShort =
      'El nombre debe tener al menos 2 caracteres.';
  static const String nameTooLong = 'El nombre es demasiado largo.';
  static const String invalidUrl = 'Ingresa una URL válida.';
  static const String invalidDate = 'Ingresa una fecha válida.';
  static const String invalidTime = 'Ingresa una hora válida.';
  static const String endTimeBeforeStartTime =
      'La hora de fin debe ser posterior a la hora de inicio.';
  static const String durationTooShort = 'La duración mínima es de 5 minutos.';
  static const String durationTooLong = 'La duración máxima es de 8 horas.';
  static const String maxLengthExceeded =
      'Has excedido el límite de caracteres.';
  static const String minLengthNotMet = 'El texto es demasiado corto.';
  static const String invalidCharacters =
      'El campo contiene caracteres no válidos.';
  static const String numberRequired = 'Ingresa un número válido.';
  static const String positiveNumberRequired = 'Ingresa un número positivo.';

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING — Cargando
  // ═══════════════════════════════════════════════════════════════════════════

  static const String loading = 'Cargando...';
  static const String loadingAppointments = 'Cargando citas...';
  static const String loadingCustomers = 'Cargando clientes...';
  static const String loadingEmployees = 'Cargando empleados...';
  static const String loadingServices = 'Cargando servicios...';
  static const String loadingBranches = 'Cargando sucursales...';
  static const String loadingCalendar = 'Cargando calendario...';
  static const String loadingDashboard = 'Cargando panel...';
  static const String loadingSettings = 'Cargando configuración...';
  static const String loadingAvailability = 'Verificando disponibilidad...';
  static const String loadingProfile = 'Cargando perfil...';
  static const String savingChanges = 'Guardando cambios...';
  static const String processingRequest = 'Procesando solicitud...';
  static const String uploadingImage = 'Subiendo imagen...';
  static const String sendingNotification = 'Enviando notificación...';
  static const String checkingAvailability = 'Verificando disponibilidad...';
  static const String bookingAppointment = 'Reservando cita...';
  static const String cancellingAppointment = 'Cancelando cita...';
  static const String reschedulingAppointment = 'Reprogramando cita...';
  static const String pleaseWait = 'Por favor, espera...';
  static const String almostReady = 'Casi listo...';

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATES — Estados vacíos
  // ═══════════════════════════════════════════════════════════════════════════

  static const String noDataFound = 'No se encontraron datos';
  static const String noResultsFound = 'No se encontraron resultados';
  static const String noResultsSubtitle =
      'Intenta ajustar tu búsqueda o filtros.';
  static const String emptyAppointments = 'Sin citas';
  static const String emptyAppointmentsSubtitle =
      'No hay citas programadas. Crea una nueva cita para comenzar.';
  static const String emptyCalendar = 'Calendario vacío';
  static const String emptyCalendarSubtitle =
      'Este día está libre. Agrega una cita para llenar el horario.';
  static const String emptyCustomers = 'Sin clientes';
  static const String emptyCustomersSubtitle =
      'Aún no tienes clientes registrados. Comienza a recibir reservas.';
  static const String emptyEmployees = 'Sin empleados';
  static const String emptyEmployeesSubtitle =
      'Agrega empleados para comenzar a gestionar citas.';
  static const String emptyServices = 'Sin servicios';
  static const String emptyServicesSubtitle =
      'Agrega servicios para que los clientes puedan reservar.';
  static const String emptyBranches = 'Sin sucursales';
  static const String emptyBranchesSubtitle =
      'Agrega sucursales para gestionar múltiples ubicaciones.';
  static const String emptyNotifications = 'Sin notificaciones';
  static const String emptyNotificationsSubtitle =
      'No tienes notificaciones pendientes.';
  static const String emptySearch = 'Sin resultados de búsqueda';
  static const String emptySearchSubtitle =
      'No encontramos negocios que coincidan con tu búsqueda.';
  static const String emptyGallery = 'Sin imágenes';
  static const String emptyGallerySubtitle =
      'Agrega imágenes para mostrar tu negocio.';
  static const String emptyHistory = 'Sin historial';
  static const String emptyHistorySubtitle =
      'El historial de actividad aparecerá aquí.';
  static const String nothingHereYet = 'Nada aquí todavía';
  static const String getStarted = 'Comienza agregando tu primer elemento.';
}
