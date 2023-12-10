import 'package:flutter/material.dart';

class SuccessDialog {
  static showSuccessDialog(String text, dynamic context) {
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
        title: const Text("Success", style: TextStyle(color: Colors.green)),
        contentPadding: const EdgeInsets.all(25),
        content: Text(text),
      ),
    );
  }
}
