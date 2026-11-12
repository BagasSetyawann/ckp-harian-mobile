import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const String defaultBaseUrl = 'https://ckp-harian-backend.vercel.app/api';
  static const String _tokenKey = 'si_ckp_token';
  static const String _userKey = 'si_ckp_user';
  static const String _baseUrlKey = 'si_ckp_base_url';

  static String _baseUrl = defaultBaseUrl;
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String get baseUrl => _baseUrl;
  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static int? get employeeId =>
      _currentUser?['employee']?['id'] ?? _currentUser?['employeeId'];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
    _token = prefs.getString(_tokenKey);
    final userRaw = prefs.getString(_userKey);
    if (userRaw != null) {
      try {
        _currentUser = jsonDecode(userRaw) as Map<String, dynamic>;
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = cleaned.endsWith('/api') ? cleaned : '$cleaned/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response res) {
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    final errorMsg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Terjadi kesalahan server (${res.statusCode})';
    throw ApiException(errorMsg, res.statusCode);
  }

  // ─── AUTH ───

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final res = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode({'username': username.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 25));

    final data = _handleResponse(res) as Map<String, dynamic>;
    _token = data['token'] as String?;
    _currentUser = data['user'] as Map<String, dynamic>?;

    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    if (_currentUser != null) await prefs.setString(_userKey, jsonEncode(_currentUser));

    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final uri = Uri.parse('$_baseUrl/auth/me');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    final data = _handleResponse(res) as Map<String, dynamic>;
    if (data['user'] != null) {
      _currentUser = data['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser));
    }
    return data;
  }

  static Future<void> logout() async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/logout');
      await http.post(uri, headers: _headers()).timeout(const Duration(seconds: 5));
    } catch (_) {}
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final uri = Uri.parse('$_baseUrl/auth/change-password');
    final res = await http
        .put(
          uri,
          headers: _headers(),
          body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 20));
    _handleResponse(res);
  }

  // ─── DASHBOARD & PERIODS ───

  static Future<Map<String, dynamic>> getPegawaiDashboard() async {
    final uri = Uri.parse('$_baseUrl/dashboard/pegawai');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPeriods() async {
    final uri = Uri.parse('$_baseUrl/periods');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as List<dynamic>;
  }

  static Future<List<dynamic>> getPerformancePlans({int? periodId}) async {
    final query = <String, String>{};
    if (periodId != null) query['period_id'] = periodId.toString();
    final uri = Uri.parse('$_baseUrl/performance-plans').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as List<dynamic>;
  }

  // ─── ACTIVITIES (KEGIATAN HARIAN) ───

  static Future<List<dynamic>> getActivities({int? periodId, String? tanggal}) async {
    final query = <String, String>{};
    if (periodId != null) query['period_id'] = periodId.toString();
    if (tanggal != null && tanggal.isNotEmpty) query['tanggal'] = tanggal;

    final uri = Uri.parse('$_baseUrl/activities').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createActivity(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/activities');
    final res = await http
        .post(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 25));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateActivity(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/activities/$id');
    final res = await http
        .put(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 25));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<void> deleteActivity(int id) async {
    final uri = Uri.parse('$_baseUrl/activities/$id');
    final res = await http
        .delete(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    _handleResponse(res);
  }

  // ─── EVIDENCE (BUKTI DUKUNG) ───

  static Future<Map<String, dynamic>> getEvidence(int activityId) async {
    final uri = Uri.parse('$_baseUrl/evidence/activity/$activityId');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadEvidenceFile({
    required int activityId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? keterangan,
  }) async {
    // 1. Minta signed URL ke backend
    final urlRes = await http
        .post(
          Uri.parse('$_baseUrl/evidence/upload-url/$activityId'),
          headers: _headers(),
          body: jsonEncode({
            'nama_file': fileName,
            'mime_type': mimeType,
            'ukuran_file': bytes.length,
          }),
        )
        .timeout(const Duration(seconds: 25));

    final signedData = _handleResponse(urlRes) as Map<String, dynamic>;
    final signedUrl = signedData['signedUrl'] as String;
    final storagePath = signedData['path'] as String;

    // 2. Upload langsung bytes file ke Supabase Storage
    final putRes = await http
        .put(
          Uri.parse(signedUrl),
          headers: {'Content-Type': mimeType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      throw ApiException('Gagal mengunggah file ke storage (${putRes.statusCode})');
    }

    // 3. Simpan metadata file di backend (termasuk koordinat GPS & timestamp pada keterangan)
    final saveRes = await http
        .post(
          Uri.parse('$_baseUrl/evidence/file/$activityId'),
          headers: _headers(),
          body: jsonEncode({
            'path': storagePath,
            'nama_file': fileName,
            'mime_type': mimeType,
            'ukuran_file': bytes.length,
            'keterangan': keterangan,
          }),
        )
        .timeout(const Duration(seconds: 25));

    return _handleResponse(saveRes) as Map<String, dynamic>;
  }

  static String getExcelExportUrl({required int periodId}) {
    final empId = ApiService.employeeId;
    final empParam = empId != null ? '&employee_id=$empId' : '';
    return '$_baseUrl/export/excel?period_id=$periodId$empParam&token=${Uri.encodeComponent(_token ?? '')}';
  }

  static Future<Map<String, dynamic>> addEvidenceLink({
    required int activityId,
    required String judul,
    required String url,
    String? platform,
    String? keterangan,
  }) async {
    final uri = Uri.parse('$_baseUrl/evidence/link/$activityId');
    final res = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode({
            'judul': judul,
            'url': url,
            'platform': platform,
            'keterangan': keterangan,
          }),
        )
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as Map<String, dynamic>;
  }

  static Future<void> deleteEvidenceFile(int id) async {
    final uri = Uri.parse('$_baseUrl/evidence/file/$id');
    final res = await http
        .delete(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    _handleResponse(res);
  }

  static Future<void> deleteEvidenceLink(int id) async {
    final uri = Uri.parse('$_baseUrl/evidence/link/$id');
    final res = await http
        .delete(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    _handleResponse(res);
  }

  // ─── SCORES & RK ───

  static Future<Map<String, dynamic>> getCkpScore({
    required int periodId,
    int? employeeId,
  }) async {
    final empId = employeeId ?? ApiService.employeeId;
    final query = <String, String>{
      'period_id': periodId.toString(),
      if (empId != null) 'employee_id': empId.toString(),
    };
    final uri = Uri.parse('$_baseUrl/scores/ckp').replace(queryParameters: query);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    return _handleResponse(res) as Map<String, dynamic>;
  }
}

