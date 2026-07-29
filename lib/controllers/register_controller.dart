import 'package:flutter/material.dart';

class RegisterController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dniController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  bool isLoading = false;
  DateTime? selectedDate;

  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dniController.dispose();
    dateController.dispose();
  }
}
