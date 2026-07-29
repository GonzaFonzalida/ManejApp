import 'package:flutter/material.dart';

class HomeController {
  final TextEditingController searchController = TextEditingController();

  void dispose() {
    searchController.dispose();
  }
}
