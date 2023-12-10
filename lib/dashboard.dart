import 'package:eliger_driver/home.dashboard.dart';
import 'package:eliger_driver/login_page.dart';
import 'package:eliger_driver/payments.dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int index = 0;

  Widget getPage(int index) {
    switch (index) {
      case 1:
        return const Payments();
      default:
        return const Home();
    }
  }

  logout() async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.remove("token");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginForm()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Are you sure?'),
                content: const Text('Are you sure, You want to exit ?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text("Eliger for Driver"),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                logout();
              },
              icon: const Icon(
                Icons.logout,
              ),
            ),
          ],
        ),
        body: getPage(index),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
              indicatorColor: Colors.blue.shade700,
              iconTheme: MaterialStateProperty.all(const IconThemeData(
                color: Colors.white,
              )),
              labelTextStyle: MaterialStateProperty.all(const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white))),
          child: NavigationBar(
            height: 60,
            backgroundColor: Colors.blue,
            animationDuration: const Duration(milliseconds: 600),
            selectedIndex: index,
            onDestinationSelected: (index) =>
                setState(() => this.index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: "Payment",
              )
            ],
          ),
        ),
      ),
    );
  }
}
