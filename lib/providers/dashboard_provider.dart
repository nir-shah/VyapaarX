import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? dashboardService})
    : _dashboardService = dashboardService ?? DashboardService();

  final DashboardService _dashboardService;

  DashboardData _data = DashboardData.empty;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  DashboardData get data => _data;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard(String businessId) async {
    if (businessId.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _dashboardService.fetchDashboardData(
        businessId: businessId,
      );
      _hasLoaded = true;
    } on Object catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String businessId) => loadDashboard(businessId);

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You do not have permission to view this business dashboard.';
      }
      return error.message ?? 'Unable to load dashboard data.';
    }
    return 'Unable to load dashboard data. Please try again.';
  }
}
