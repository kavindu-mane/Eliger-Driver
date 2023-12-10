import 'dart:async';
import 'dart:convert';
import 'package:eliger_driver/common/loading_screen.dart';
import 'package:eliger_driver/common/api_connection.dart';
import 'package:eliger_driver/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:eliger_driver/common/error_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen(
      {Key? key,
      required this.pickUp,
      required this.destination,
      required this.vehicle,
      required this.booking,
      required this.price})
      : super(key: key);
  final LatLng destination;
  final LatLng pickUp;
  final int vehicle;
  final int booking;
  final dynamic price;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng? currentPosition = const LatLng(5.9717, 80.6951);
  Map<PolylineId, Polyline> polylines = {};
  double distance = 0;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
    approveBooking(widget.booking);
    updateDistance();
  }

  Future<void> approveBooking(int id) async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.manageBookingURL),
            body: {"booking": id.toString(), "status": "driving"},
            headers: {"cookie": token}).then((res) {
          if (res.statusCode == 200) {
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

  @override
  Widget build(BuildContext context) {
    return currentPosition == null
        ? const LoadingScreen()
        : Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: ((GoogleMapController controller) =>
                      _mapController.complete(controller)),
                  initialCameraPosition: CameraPosition(
                    target: currentPosition!,
                    zoom: 18,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("_currentLocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: currentPosition!,
                    ),
                    Marker(
                      markerId: const MarkerId("_destinationLocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: widget.destination,
                    ),
                    Marker(
                      markerId: const MarkerId("_pickUpLocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: widget.pickUp,
                    )
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 150,
                    child: Container(
                      decoration: const BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 3,
                          blurRadius: 30,
                        )
                      ]),
                      child: Card(
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _cardContainer(),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
  }

  Widget _cardContainer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 12.0),
        Text("Distance : $distance Km",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Text("Price : Rs.${(distance * widget.price).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.tealAccent.shade700, // Background color
                ),
                onPressed: () {
                  payedAndFinish();
                },
                child: const Text('Payed & Finish'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.tealAccent.shade700, // Background color
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Dashboard(),
                    ),
                  );
                },
                child: const Text('Finish'),
              ),
            ),
          ],
        )
      ],
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(
      target: pos,
      zoom: 18,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        if (mounted) {
          setState(
            () {
              currentPosition =
                  LatLng(currentLocation.latitude!, currentLocation.longitude!);
              _cameraToPosition(currentPosition!);
            },
          );
          updateLocation(currentLocation.latitude!, currentLocation.longitude!);
          getPolylinePoints().then(
            (value) => generatePolyLineFromPoints(value),
          );
        }
      }
    });
  }

// decide polyline points
  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      API.googleMapsApiKey,
      PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
      PointLatLng(widget.destination.latitude, widget.destination.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    return polylineCoordinates;
  }

// draw polyline
  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    polylines.clear();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue.shade900,
        points: polylineCoordinates,
        width: 5);
    if (mounted) {
      setState(() {
        polylines[id] = polyline;
      });
    }
  }

  Future<void> payedAndFinish() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure to end?'),
        content:
            const Text('Are you sure that you collect money from customer ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              updatePayedStatus();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> updateDistance() async {
    String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?destinations=${widget.destination.latitude},${widget.destination.longitude}&origins=${widget.pickUp.latitude},${widget.pickUp.longitude}&key=${API.googleMapsApiKey}";
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(url), body: {}, headers: {"cookie": token}).then(
            (res) {
          final resBody = jsonDecode(res.body);
          setState(() {
            distance = double.parse(resBody["rows"][0]["elements"][0]
                    ["distance"]["text"]
                .split(" ")[0]);
          });
          if (res.statusCode == 200) {
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

  Future<void> updatePayedStatus() async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.finishBookingURL), body: {
          "booking": widget.booking.toString(),
          "amount": (distance * widget.price).toString()
        }, headers: {
          "cookie": token
        }).then((res) {
          if (res.statusCode == 200) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Dashboard(),
              ),
            );
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

  Future<void> updateLocation(double lat, double lng) async {
    try {
      SharedPreferences.getInstance().then((prefs) {
        // send 1st request and get driver basic details
        dynamic token = prefs.getString("token");
        http.post(Uri.parse(API.locationChangeURL), body: {
          "vehicle": widget.vehicle.toString(),
          "lat": lat.toString(),
          "lng": lng.toString(),
        }, headers: {
          "cookie": token
        }).then((res) {});
      });
    } catch (e) {
      ErrorDialog.showErrorDialog(
          "Something went wrong. Please try again later.", context);
    }
  }
}
