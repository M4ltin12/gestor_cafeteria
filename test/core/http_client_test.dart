import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient con MockClient', () {
    test('GET exitoso devuelve el JSON decodificado', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/orders');
        return http.Response('[{"id":1}]', 200);
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      final resultado = await api.get('/orders');

      expect(resultado, [
        {'id': 1},
      ]);
    });

    test('404 conserva el detalle en NotFoundFailure', () async {
      final mock = MockClient((request) async =>
          http.Response('{"detail":"Order 9 not found"}', 404));
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (failure) => failure.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    test('409 conserva el detalle en ConflictFailure', () async {
      final mock = MockClient((request) async =>
          http.Response('{"detail":"Estado incompatible"}', 409));
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(
        api.patch('/orders/9', {'status': 'ready'}),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.message,
            'message',
            'Estado incompatible',
          ),
        ),
      );
    });

    test('422 identifica el campo customer en ValidationFailure', () async {
      final mock = MockClient((request) async => http.Response(
            '{"detail":[{"loc":["body","customer"],'
            '"msg":"Must be 1-50 characters"}]}',
            422,
          ));
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(
        api.post('/orders', {'customer': ''}),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.fields,
            'fields',
            {'customer': 'Must be 1-50 characters'},
          ),
        ),
      );
    });

    test('503 conserva el statusCode en ServerFailure', () async {
      final mock = MockClient((request) async => http.Response('', 503));
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('ClientException se convierte en NetworkFailure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });

    test('300 se convierte en UnexpectedFailure', () async {
      final mock = MockClient((request) async => http.Response('', 300));
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            300,
          ),
        ),
      );
    });
  });
}
