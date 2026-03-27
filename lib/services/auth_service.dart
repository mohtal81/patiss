// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../database/db_helper.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? _user;
  bool _isLoading = false;
  String? _error;

  GoogleSignInAccount? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  String? get error => _error;
  String? get userEmail => _user?.email;
  String? get userName  => _user?.displayName;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skipped = prefs.getBool('auth_skipped') ?? false;
      if (!skipped) {
        _user = await _googleSignIn.signInSilently();
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> signIn() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      _user = account;
      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_skipped', false);
      }
      return account != null;
    } catch (e) {
      _error = 'Erreur de connexion : $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> skipAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_skipped', true);
    notifyListeners();
  }

  // ── DRIVE BACKUP ─────────────────────────────────────

  Future<String> backupToDrive() async {
    if (_user == null) throw Exception('Non connecté à Google');

    final auth  = await _user!.authentication;
    final token = auth.accessToken;
    if (token == null) throw Exception('Token invalide');

    final dbPath  = await DbHelper().getDbPath();
    final dbFile  = File(dbPath);
    final bytes   = await dbFile.readAsBytes();
    final now     = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
    final fileName = 'patisserie_backup_$now.db';

    // 1. Créer le fichier sur Drive
    final metaRes = await http.post(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/related; boundary=boundary123',
      },
      body: _buildMultipart(fileName, bytes),
    );

    if (metaRes.statusCode != 200) {
      throw Exception('Erreur Drive : ${metaRes.statusCode} ${metaRes.body}');
    }

    final fileId = jsonDecode(metaRes.body)['id'];
    return fileId;
  }

  List<int> _buildMultipart(String fileName, List<int> bytes) {
    const boundary = 'boundary123';
    final meta = jsonEncode({
      'name': fileName,
      'mimeType': 'application/octet-stream',
    });
    final sb = StringBuffer();
    sb.write('--$boundary\r\n');
    sb.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
    sb.write('$meta\r\n');
    sb.write('--$boundary\r\n');
    sb.write('Content-Type: application/octet-stream\r\n\r\n');
    final header = sb.toString().codeUnits;
    final footer = '\r\n--$boundary--'.codeUnits;
    return [...header, ...bytes, ...footer];
  }

  Future<List<Map<String, dynamic>>> listDriveBackups() async {
    if (_user == null) return [];
    final auth  = await _user!.authentication;
    final token = auth.accessToken;
    if (token == null) return [];

    final res = await http.get(
      Uri.parse(
        "https://www.googleapis.com/drive/v3/files?q=name+contains+'patisserie_backup'&fields=files(id,name,size,modifiedTime)&orderBy=modifiedTime+desc"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['files'] ?? []);
  }
}
