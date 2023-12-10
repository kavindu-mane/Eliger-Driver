import 'dart:convert';
import 'package:eliger_driver/common/api_connection.dart';
import 'package:eliger_driver/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late Color myColor;
  late Size mediaSize;
  var formKey = GlobalKey<FormState>();
  var isObsSecure = true.obs;
  late TextEditingController emailController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;

  login() async {
    try {
      http.Response res = await http.post(Uri.parse(API.loginURL), body: {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'remember': 'true',
      });
      if (res.statusCode == 200) {
        var resBody = jsonDecode(res.body);
        //  save session id
        String rawCookie = res.headers["set-cookie"].toString();
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("token", rawCookie);

        if (resBody["status"] == 200 && resBody["role"] == "driver") {
          if (context.mounted) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Dashboard()));
          }
        } else {
          showErrorDialog("Email and Password mistmatch.");
        }
      } else {
        showErrorDialog("Something went wrong. Please try again later.");
      }
    } catch (e) {
      debugPrint("Something went wrong. Please try again later.");
    }
  }

  showErrorDialog(String text) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"))
        ],
        title: const Text("Error", style: TextStyle(color: Colors.red)),
        contentPadding: const EdgeInsets.all(25),
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;
    mediaSize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
          color: myColor,
          image: const DecorationImage(
              image: AssetImage("assets/login-background.png"),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  spreadRadius: 3,
                  blurRadius: 30,
                )
              ]),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return SizedBox(
        width: mediaSize.width,
        height: 420,
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildForm(),
          ),
        ));
  }

  Widget _buildForm() {
    return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome",
              style: TextStyle(
                  color: myColor, fontWeight: FontWeight.w500, fontSize: 40),
            ),
            _buildGrayText("Please login with your driver account details"),
            const SizedBox(height: 60),
            _buildInputField(emailController, "Email"),
            const SizedBox(height: 10),
            Obx(() => _buildInputField(passwordController, "Password",
                isPassword: true)),
            const SizedBox(height: 30),
            _buildLoginButton(),
            const SizedBox(height: 20),
          ],
        ));
  }

  Widget _buildGrayText(String text) {
    return Text(
      text,
      style: TextStyle(
          color: Colors.blueGrey.shade800,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400),
    );
  }

  Widget _buildInputField(TextEditingController controller, String text,
      {isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isObsSecure.value,
      validator: (value) => value == "" ? "Please enter $text" : null,
      decoration: InputDecoration(
          hintText: text,
          border: InputBorder.none,
          prefixIcon:
              isPassword ? const Icon(Icons.vpn_key) : const Icon(Icons.email),
          suffixIcon: isPassword
              ? Obx(() => GestureDetector(
                    onTap: () {
                      isObsSecure.value = !isObsSecure.value;
                    },
                    child: isObsSecure.value
                        ? const Icon(Icons.visibility_off)
                        : const Icon(Icons.visibility),
                  ))
              : null,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 2, color: myColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 2, color: myColor))),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            login();
          }
        },
        style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 20,
            shadowColor: myColor,
            minimumSize: const Size.fromHeight(50)),
        child: const Text("Login"));
  }
}
