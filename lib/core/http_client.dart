import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client? _client;
  final Uri? baseUrl;
  final Duration timeout;
  //Clase Client
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       baseUrl = Uri.parse(
         baseUrl ??
             (const String.fromEnvironment('API_URL').isNotEmpty
                 ? const String.fromEnvironment('API_URL')
                 : (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000')),
       );
  //POST,GET,PATCH,DELETE
  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> update(String path, Object body) =>
      _send('UPDATE', path, body);
  Future<void> delete(String path) => _send('DELETE', path);

  //Funcion SEND -> Mandar la peticion al Servicio, esperar una respuesta y adecuarlo para flutter

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    //Request: Va arma la peticion con la inyeccion de los HEADERS
    final request = http.Request(method, baseUrl!.resolve(path))
      ..headers['Accept'] = 'application/json';
    //Si es una peticion que tiene que mandar un body
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    //Guardar la respuesta del servicio
    final http.Response response;
    //El response se va a tratar segun el caso con el servicio respondio
    try {
      response = await _client!
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    }
    final json = _tryDecode(response);
    final code = response.statusCode;
    if (code >= 200 && code <= 300) return json;
    throw _mapHttpError(code, json);
  }

  Failure _mapHttpError(int code, Object? body) {
    if (code == 404) {
      return NotFoundFailure(_detailMessage(body, 'Recurso no encontrado'));
    }
    if (code == 409) {
      return ConflictFailure(_detailMessage(body, 'Conflicto con el pedido'));
    }
    if (code == 422) {
      return ValidationFailure(_validationFields(body));
    }
    if (code >= 500 && code <= 599) {
      return ServerFailure(code);
    }
    return UnexpectedFailure(code, _detailMessage(body, 'Error HTTP $code'));
  }

  String _detailMessage(Object? body, String fallback) {
    if (body is Map && body['detail'] is String) {
      final detail = (body['detail'] as String).trim();
      if (detail.isNotEmpty) return detail;
    }
    return fallback;
  }

  Map<String, String> _validationFields(Object? body) {
    final fields = <String, String>{};
    if (body is! Map) return fields;
    final detail = body['detail'];
    if (detail is! List) return fields;

    for (final error in detail) {
      if (error is! Map) continue;
      final loc = error['loc'];
      final msg = error['msg'];
      if (loc is List && loc.length > 1 && msg is String) {
        fields[loc[1].toString()] = msg;
      }
    }
    return fields;
  }

  dynamic _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
