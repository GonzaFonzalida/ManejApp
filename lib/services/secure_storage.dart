import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single secure-storage configuration for the whole app (Android persistence fix).
const appSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
