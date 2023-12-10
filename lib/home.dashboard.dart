import 'package:eliger_driver/common/loading_screen.dart';
import 'package:eliger_driver/common/success_dialog.dart';
import 'package:eliger_driver/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:eliger_driver/common/error_dialog.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eliger_driver/common/api_connection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic>? details;
  List<Map<String, dynamic>>? rentOutBookings;
  List<Map<String, dynamic>>? bookNowBookings;
  bool availability = false;
  Map<String, dynamic> addresseMap = {};
  bool finishLoading = false;

// load basic details
  loadDetails() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.getDriverURL),
            body: {}, headers: {"cookie": token}).then((res) {
          if (res.statusCode == 200) {
            var resBody = jsonDecode(res.body);
            setState(() => details = resBody);
            setState(
                () => availability = resBody["Availability"] == "available");
          } else {
            ErrorDialog.showErrorDialog(
                "Something went wrong. Please try again later.", context);
          }
        }).then((value) {
          if (details!["Booking_Type"] == "rent-out") loadRentOut();
          if (details!["Booking_Type"] == "book-now") loadBookNow();
        }).then((value) {
          setState(() {
            finishLoading = true;
          });
        });
      });
    } catch (e) {
      ErrorDialog.showErrorDialog(
          "Something went wrong. Please try again later.", context);
    }
  }

  // load rent out bookings
  loadRentOut() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.getDriverRentOutBookingURL),
            body: {}, headers: {"cookie": token}).then((res) {
          if (res.statusCode == 200) {
            var resBody = jsonDecode(res.body);
            setState(() => rentOutBookings =
                (resBody as List<dynamic>).cast<Map<String, dynamic>>());
          } else {
            ErrorDialog.showErrorDialog(
                "Something went wrong. Please try again later.", context);
          }
        });
      });
    } catch (e) {
      ErrorDialog.showErrorDialog(
          "Something went wrong. Please try again later.", context);
    }
  }

// load book now bookings
  loadBookNow() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.getDriverBookNowBookingURL),
            body: {}, headers: {"cookie": token}).then((res) {
          if (res.statusCode == 200) {
            var resBody = jsonDecode(res.body);
            setState(() => bookNowBookings =
                (resBody as List<dynamic>).cast<Map<String, dynamic>>());
          } else {
            ErrorDialog.showErrorDialog(
                "Something went wrong. Please try again later.", context);
          }
        }).then((value) {
          for (var row in bookNowBookings ?? []) {
            getAddressFromLocation(row["Origin_Place"]);
            getAddressFromLocation(row["Destination_Place"]);
          }
        });
      });
    } catch (e) {
      ErrorDialog.showErrorDialog(
          "Something went wrong. Please try again later.", context);
    }
  }

// convert latlang to address
  Future getAddressFromLocation(String latlng) async {
    double lat = double.parse(latlng.split(",")[0]);
    double lng = double.parse(latlng.split(",")[1]);
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    String address =
        "${placemarks[0].street} ${placemarks[0].subLocality} ${placemarks[0].thoroughfare} ${placemarks[0].locality}";
    setState(() {
      addresseMap[latlng] = address;
    });
  }

  Future<void> rejectBooking(int id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Are you sure, You want to reject ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              try {
                SharedPreferences.getInstance().then((prefs) {
                  // send 1st request and get driver basic details
                  dynamic token = prefs.getString("token");
                  http.post(Uri.parse(API.manageBookingURL),
                      body: {"booking": id.toString(), "status": "rejected"},
                      headers: {"cookie": token}).then((res) {
                    if (res.statusCode == 200) {
                      var resBody = jsonDecode(res.body);
                      if (resBody == 200) {
                        SuccessDialog.showSuccessDialog(
                            "Booking rejected", context);
                      }
                    } else {
                      ErrorDialog.showErrorDialog(
                          "Something went wrong. Please try again later.",
                          context);
                    }
                  });
                });
              } catch (e) {
                ErrorDialog.showErrorDialog(
                    "Something went wrong. Please try again later.", context);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // load basic information of the driver
    super.initState();
    loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    return !finishLoading ? const LoadingScreen() : _mainLayout();
  }

  Widget _mainLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          //  top container
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.blue,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hi, ${details?["Driver_firstname"] ?? ""}',
                        style: const TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        details?["Vehicle_PlateNumber"] ?? "No Vehicle",
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Rs.',
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ((details?["Income"] ?? 0).toStringAsFixed(2))
                            .toString(),
                        style: const TextStyle(
                            fontSize: 50,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Current Balance',
                  style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // availability container
                _activeStatus(),
                // book now bookings
                for (var row in rentOutBookings ?? []) _rentOutBookingCard(row),
                // rent out bookings
                for (var row in bookNowBookings ?? []) _bookNowBookingCard(row),
              ],
            ),
          ),
        ],
      ),
    );
  }

// status card
  Widget _activeStatus() {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          color: Colors.blue.shade900,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  details?["Availability"].toUpperCase() ?? "",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: availability,
                  activeColor: Colors.tealAccent.shade400,
                  onChanged: (bool value) {
                    if (details!["Status"] != "verified" ||
                        details!["Vehicle_PlateNumber"] == null) {
                      null;
                    } else {
                      setState(() {
                        availability = value;
                      });
                      statusChange();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookNowBookingCard(Map<String, dynamic> row) {
    double pickUpLat = double.parse(row["Origin_Place"]!.split(",")[0]);
    double pickUpLng = double.parse(row["Origin_Place"]!.split(",")[1]);
    double destLat = double.parse(row["Destination_Place"]!.split(",")[0]);
    double destLng = double.parse(row["Destination_Place"]!.split(",")[1]);
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 120,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          color: Colors.indigo.shade600,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From : ${addresseMap[row["Origin_Place"]] ?? ""}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          "To : ${addresseMap[row["Destination_Place"]] ?? ""}",
                          style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w400),
                        ),
                      ]),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 90,
                      child: OutlinedButton(
                        onPressed: () {
                          rejectBooking(row["Booking_Id"]);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.tealAccent.shade700, // Background color
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                  pickUp: LatLng(pickUpLat, pickUpLng),
                                  destination: LatLng(destLat, destLng),
                                  vehicle: details?["Vehicle_Id"],
                                  booking: row["Booking_Id"],
                                  price: details?["Price"]),
                            ),
                          );
                        },
                        child: const Text('Approve'),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rentOutBookingCard(Map<String, dynamic> row) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Card(
          color: Colors.indigo.shade600,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start : ${row["Journey_Starting_Date"]}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  'End : ${row["Journey_Ending_Date"]}',
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> statusChange() async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.availabilityChangeURL), body: {
          "vehicle": details?["Vehicle_Id"].toString(),
          "availability": availability ? "available" : "not available"
        }, headers: {
          "cookie": token
        }).then((res) {
          if (res.statusCode == 200) {
            SuccessDialog.showSuccessDialog("Availability updated", context);
          } else {
            ErrorDialog.showErrorDialog(
                "Something went wrong. Please try again later.", context);
          }
        });
      });
    } catch (e) {
      ErrorDialog.showErrorDialog(
          "Something went wrong. Please try again later.", context);
    }
  }
}
