// import 'package:flutter/material.dart';
// import 'package:admin/features/auth/models/admin_user.dart';
// import 'package:admin/features/auth/repositories/auth_repository.dart';
// import 'package:admin/features/auth/models/login_request.dart';
// import 'package:admin/core/services/local_storage_service.dart';

// class AuthProvider extends ChangeNotifier {
//   final AuthRepository _authRepository;
//   final LocalStorageService _storageService;

//   AdminUser? _currentUser;
//   bool _isLoading = false;
//   bool _isAuthenticated = false;
//   String? _error;

//   AuthProvider(this._authRepository, this._storageService);

//   AdminUser? get currentUser => _currentUser;
//   bool get isLoading => _isLoading;
//   bool get isAuthenticated => _isAuthenticated;
//   String? get error => _error;

//   Future<bool> login(String email, String password) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final request = LoginRequest(email: email, password: password);
//       final response = await _authRepository.login(request);

//       // await _storageService.saveToken(response.token);
//       // await _storageService.saveRefreshToken(response.refreshToken);
//       // await _storageService.saveUser(response.user);

//       _currentUser = response.user;
//       _isAuthenticated = true;
//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<void> logout() async {
//     await _authRepository.logout();
//     // await _storageService.clearAll();
//     _currentUser = null;
//     _isAuthenticated = false;
//     notifyListeners();
//   }

//   Future<void> checkAuth() async {
//     final token = await _storageService.getToken();
//     // final user = await _storageService.getUser();
//     if (token != null && user != null) {
//       _currentUser = user;
//       _isAuthenticated = true;
//       notifyListeners();
//     }
//   }
// }
