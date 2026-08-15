/// Application string keys for localization.
/// Values are English defaults — replace with ARB/intl in Phase N.
class AppStrings {
  AppStrings._();

  // ─── App ───────────────────────────────────────────────────────────────────
  static const String appName = 'ReserveHub';
  static const String appTagline = 'Where businesses manage time better.';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";

  // ─── Navigation ────────────────────────────────────────────────────────────
  static const String navDashboard = 'Dashboard';
  static const String navCalendar = 'Calendar';
  static const String navCustomers = 'Customers';
  static const String navSettings = 'Settings';

  // ─── Dashboard ─────────────────────────────────────────────────────────────
  static const String todaysAppointments = "Today's Appointments";
  static const String newAppointment = 'New Appointment';
  static const String revenue = 'Revenue';
  static const String bookings = 'Bookings';
  static const String customers = 'Customers';
  static const String occupancy = 'Occupancy';

  // ─── Calendar ──────────────────────────────────────────────────────────────
  static const String calendar = 'Calendar';
  static const String noAppointments = 'No appointments';
  static const String noAppointmentsSubtitle =
      'This day is free. Add an appointment to fill the schedule.';

  // ─── Customers ─────────────────────────────────────────────────────────────
  static const String customersTitle = 'Customers';
  static const String searchCustomers = 'Search customers...';
  static const String noCustomersFound = 'No customers found';
  static const String noCustomersSubtitle =
      'Try adjusting your search or filters.';

  // ─── Settings ──────────────────────────────────────────────────────────────
  static const String businessSettings = 'Business Settings';
  static const String save = 'Save';
  static const String businessProfile = 'Business Profile';
  static const String workingHours = 'Working Hours';
  static const String services = 'Services';
  static const String notifications = 'Notifications';
  static const String subscription = 'Subscription';
  static const String dangerZone = 'Danger Zone';

  // ─── Appointment ───────────────────────────────────────────────────────────
  static const String selectService = 'Select Service';
  static const String selectStaff = 'Select Staff';
  static const String selectTime = 'Select Time';
  static const String confirmAppointment = 'Confirm Appointment';
  static const String bookAppointment = 'Book Appointment';

  // ─── Common ────────────────────────────────────────────────────────────────
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String close = 'Close';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String done = 'Done';
  static const String all = 'All';
  static const String active = 'Active';
  static const String inactive = 'Inactive';

  // ─── Errors ────────────────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
}
