import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/user_facing_error.dart';

class LocationAutocompleteController extends ChangeNotifier {
  LocationAutocompleteController({
    this.minChars = 3,
    this.debounce = const Duration(milliseconds: 260),
  });

  final int minChars;
  final Duration debounce;

  Timer? _debounceTimer;
  int _requestVersion = 0;
  String _lastQuery = '';
  bool _isLoading = false;
  bool _showSuggestions = false;
  String? _error;
  List<Map<String, String>> _suggestions = const [];

  bool get isLoading => _isLoading;
  bool get showSuggestions => _showSuggestions;
  String? get error => _error;
  List<Map<String, String>> get suggestions => _suggestions;
  bool get hasQuery => _lastQuery.trim().length >= minChars;

  void onFocus() {
    if (_suggestions.isNotEmpty || _error != null) {
      _showSuggestions = true;
      notifyListeners();
    }
  }

  void onQueryChanged(String rawQuery) {
    _debounceTimer?.cancel();
    final query = rawQuery.trim();
    _lastQuery = query;
    _error = null;

    if (query.length < minChars) {
      _isLoading = false;
      _showSuggestions = false;
      _suggestions = const [];
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(debounce, () async {
      final currentVersion = ++_requestVersion;
      _isLoading = true;
      _showSuggestions = true;
      notifyListeners();

      try {
        final results = await ApiService.searchLocations(query);
        if (currentVersion != _requestVersion) return;
        _suggestions = results;
        _error = null;
        _showSuggestions = true;
      } catch (e) {
        if (currentVersion != _requestVersion) return;
        _suggestions = const [];
        _error = humanizeApiError(e);
        _showSuggestions = true;
      } finally {
        if (currentVersion == _requestVersion) {
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  void selectSuggestion() {
    _showSuggestions = false;
    _error = null;
    notifyListeners();
  }

  void closeSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
