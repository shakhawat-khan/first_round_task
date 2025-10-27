import 'package:first_round_task/src/utils/keys.dart';
import 'package:flutter/material.dart';

class SnackBarService {
  static void showSuccessSnackBar({required String content}) {
    snackbarKey.currentState?.showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(content)),
    );
  }

  static void showErrorSnackBar({required String content}) {
    snackbarKey.currentState?.showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(content)),
    );
  }
}
