class API {
  static const googleMapsApiKey = "ADD_YOUR_API_KEY";
  static const hostConnection = "https://eliger-backend.000webhostapp.com";
  static const loginURL = "$hostConnection/login_driver_mobile";
  static const sessionURL = "$hostConnection/session";
  static const getDriverURL = "$hostConnection/get_driver";
  static const getDriverRentOutBookingURL =
      "$hostConnection/load_driver_rentout_bookings";
  static const getDriverBookNowBookingURL =
      "$hostConnection/load_driver_booknow_bookings";
  static const manageBookingURL = "$hostConnection/manage_booking_status";
  static const finishBookingURL = "$hostConnection/finish_booking";
  static const availabilityChangeURL =
      "$hostConnection/vehicle_availability_change";
  static const locationChangeURL = "$hostConnection/vehicle_location_change";
}
