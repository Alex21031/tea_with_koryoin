import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService = ApiService();
  final String baseUrl = 'http://10.0.2.2:8080';

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  // [추가됨] 전문가 인증 신청 완료 시 호출 (로컬 상태 업데이트)
  void markExpertRequested() {
    if (_user != null) {
      // certificatePath에 임시 값('pending')을 넣어 "심사 중" 상태임을 표시
      _user = _user!.copyWith(certificatePath: 'pending_submitted');
      notifyListeners(); // ProfileScreen에 즉시 업데이트 알림
    }
  }

  // 로그인
  Future<void> login(String email, String password) async {
    try {
      _user = await _apiService.login(email, password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 로그아웃
  void logout() {
    _user = null;
    notifyListeners();
  }

  // 회원가입
  Future<void> signup({
    required String email,
    required String name,
    required String username,
    required String phone,
    required String password,
    File? certificateFile,
  }) async {
    await _apiService.signup(
      email: email,
      name: name,
      username: username,
      phone: phone,
      password: password,
      certificateFile: certificateFile,
    );
  }
}