import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // ================= SAVE TOKEN =================

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "accessToken",
      token,
    );
  }

  // ================= GET TOKEN =================

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      "accessToken",
    );
  }

  // ================= HEADERS =================

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",

      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }

  // ================= GET =================

  Future<http.Response> get(String url) async {
    final headers = await getHeaders();

    return await http.get(
      Uri.parse(url),
      headers: headers,
    );
  }

  // ================= POST JSON =================

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();

    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // ================= POST JSON WITHOUT TOKEN =================

  Future<http.Response> postWithoutToken(
    String url,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }

  // ================= POST FORM-DATA WITHOUT TOKEN =================

  Future<http.Response> postFormDataWithoutToken(
    String url,
    Map<String, String> fields,
  ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    request.fields.addAll(fields);

    request.headers["Accept"] = "application/json";

    final streamedResponse = await request.send();

    return await http.Response.fromStream(
      streamedResponse,
    );
  }

  // ================= POST FORM-DATA WITH TOKEN =================

  Future<http.Response> postFormData(
    String url,
    Map<String, String> fields,
  ) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    request.fields.addAll(fields);

    request.headers["Accept"] = "application/json";

    if (token != null && token.isNotEmpty) {
      request.headers["Authorization"] =
          "Bearer $token";
    }

    final streamedResponse = await request.send();

    return await http.Response.fromStream(
      streamedResponse,
    );
  }

  // ================= PUT =================

  Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();

    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // ================= DELETE =================

  Future<http.Response> delete(String url) async {
    final headers = await getHeaders();

    return await http.delete(
      Uri.parse(url),
      headers: headers,
    );
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      "accessToken",
    );
  }
}

