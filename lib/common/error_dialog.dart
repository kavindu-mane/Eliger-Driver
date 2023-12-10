import 'package:flutter/material.dart';

class ErrorDialog {
  static showErrorDialog(String text, dynamic context) {
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
}
