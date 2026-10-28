import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class Api {
  // Inclui o tempo para reativar hospedagens que pausam quando ficam ociosas.
  static const requestTimeout = Duration(seconds: 120);
  final http.Client client;
  final FlutterSecureStorage storage;
  Api({http.Client? client, FlutterSecureStorage? storage})
    : client = client ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();
  String base = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://investir-api.onrender.com',
  );
  String? token, refreshToken, email;
  Future<bool>? _refreshing;
  bool get signedIn => token != null;
  bool get configured => base.isNotEmpty;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    base = prefs.getString('api_base') ?? base;
    try {
      final raw = await storage.read(key: 'session');
      if (raw != null) {
        final data = jsonDecode(raw);
        token = data['access_token'];
        refreshToken = data['refresh_token'];
        email = data['email'];
      }
    } catch (_) {
      token = null;
      refreshToken = null;
      email = null;
    }
  }

  Future<void> configure(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !(uri.scheme == 'https' ||
            (uri.scheme == 'http' &&
                const bool.fromEnvironment('ALLOW_LOCAL_HTTP')))) {
      throw ApiError('Informe uma URL HTTPS válida, sem usuário ou senha.');
    }
    await logout(remote: false);
    base = value.trim().replaceAll(RegExp(r'/+$'), '');
    await (await SharedPreferences.getInstance()).setString('api_base', base);
  }

  Uri uri(String path) {
    if (!configured)
      throw ApiError('O serviço está indisponível. Tente novamente mais tarde.');
    return Uri.parse('$base$path');
  }

  dynamic decode(http.Response r) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw ApiError(
        'O servidor retornou uma resposta inválida.',
        r.statusCode,
      );
    }
    if (r.statusCode >= 400) {
      final detail = data is Map ? data['detail'] : null;
      throw ApiError(
        detail is String
            ? detail
            : 'Não foi possível concluir a solicitação (${r.statusCode}).',
        r.statusCode,
      );
    }
    return data;
  }

  Future<dynamic> get(String path) async {
    try {
      return decode(
        await client.get(uri(path)).timeout(requestTimeout),
      );
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError(
        'Não foi possível conectar. Confira sua conexão e tente novamente.',
      );
    }
  }

  Future<void> saveSession(dynamic data) async {
    try {
      await storage.write(key: 'session', value: jsonEncode(data));
    } catch (_) {
      throw ApiError(
        'O sistema não permitiu guardar a sessão com segurança. Confira as permissões do aplicativo.',
      );
    }
    token = data['access_token'];
    refreshToken = data['refresh_token'];
    email = data['email'];
  }

  Future<void> login(String email, String password) async {
    try {
      final r = await client
          .post(
            uri('/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(requestTimeout);
      await saveSession(decode(r));
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError('Não foi possível entrar. Verifique a conexão.');
    }
  }

  Future<bool> _doRefresh() async {
    if (refreshToken == null) return false;
    try {
      final r = await client
          .post(
            uri('/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(requestTimeout);
      await saveSession(decode(r));
      return true;
    } catch (_) {
      await logout(remote: false);
      return false;
    }
  }

  Future<bool> refresh() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _doRefresh();
    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  Future<dynamic> upload(
    String path,
    Uint8List bytes,
    String filename,
    Map<String, String> fields, {
    bool retry = true,
  }) async {
    if (token == null) throw ApiError('Entre para importar planilhas.', 401);
    try {
      final request = http.MultipartRequest('POST', uri(path));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final r = await http.Response.fromStream(
        await client.send(request).timeout(requestTimeout),
      ).timeout(requestTimeout);
      if (r.statusCode == 401 && retry && await refresh())
        return upload(path, bytes, filename, fields, retry: false);
      return decode(r);
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError(
        'Falha de conexão durante a importação. Atualize a base antes de tentar novamente para conferir se foi salva.',
      );
    }
  }

  Future<void> attest(
    String ticker,
    Map<String, String> evidence, {
    bool retry = true,
  }) async {
    try {
      final r = await client
          .post(
            uri('/api/assets/$ticker/evidence'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(evidence),
          )
          .timeout(requestTimeout);
      if (r.statusCode == 401 && retry && await refresh())
        return attest(ticker, evidence, retry: false);
      decode(r);
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError('Não foi possível salvar a conferência.');
    }
  }

  Future<void> logout({bool remote = true}) async {
    if (remote && token != null) {
      try {
        await client
            .post(
              uri('/api/auth/logout'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
    token = null;
    refreshToken = null;
    email = null;
    await storage.delete(key: 'session');
  }
}
