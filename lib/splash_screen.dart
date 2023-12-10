import 'package:eliger_driver/dashboard.dart';
import 'package:eliger_driver/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eliger_driver/common/api_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  dynamic status;

  bool isJSON(str) {
    try {
      jsonDecode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  getToken() async {
    status = null;
    final prefs = await SharedPreferences.getInstance();
    dynamic token = prefs.getString("token") ?? "";
    try {
      http.Response res = await http.post(Uri.parse(API.sessionURL),
          body: {}, headers: {"cookie": token});
      if (res.statusCode == 200) {
        if (isJSON(res.body)) {
          var resBody = jsonDecode(res.body);
          // check response is error code or not
          if (resBody.runtimeType != int) {
            // check response status value 200 or not
            if (resBody["status"] == 200) {
              String rawCookie = res.headers["set-cookie"].toString();
              // check new cookies passes or not, if passes update token value with it
              if (rawCookie != "null") {
                final prefs = await SharedPreferences.getInstance();
                prefs.setString("token", rawCookie);
              }
              status = 1;
            }
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      debugPrint("Something went wrong. Please try again later.");
    }
  }

  @override
  void initState() {
    getToken();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  status == null ? const LoginForm() : const Dashboard()));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage("assets/eliger.png"),
          height: 47,
          width: 125,
        ),
      ),
    );
  }
}
