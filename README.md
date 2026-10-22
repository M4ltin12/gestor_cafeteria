# Gestor de cafetería

Aplicación Flutter para consultar los pedidos de una cafetería. Usa `ApiClient` para consumir el servicio y convertir errores HTTP en tipos de `Failure`. Las pruebas del cliente usan `MockClient`, sin red ni servidor.

## Requisitos

- Flutter con Dart compatible con `sdk: ^3.13.2` del `pubspec.yaml`.
- Node.js 22.13 o superior para `mini_backend`.

## Servidor

`mini_backend` es un repositorio separado: https://github.com/DMI-2026/mini_backend

La versión usada como referencia es **0.1.0**, commit `94d2533034134e4904dd38df8f2c60d56c2d1d6f`. Sus cinco pruebas con `npm test` pasaron el 22 de octubre de 2026. La integración con Flutter requiere verificación en un equipo con Flutter instalado.

En una terminal, descarga ese repositorio, entra a su carpeta y ejecuta:

```bash
node server.js
```

El servidor escucha en el puerto 8000. Mantén esa terminal abierta.

## Aplicación

Dentro de esta carpeta:

```bash
flutter pub get
flutter run --dart-define=API_URL=http://localhost:8000
```

`localhost` corresponde a Flutter web en el mismo equipo que el backend. Si usas el emulador Android, cambia la URL por `http://10.0.2.2:8000`; en un dispositivo físico, utiliza la IP local del equipo que ejecuta el servidor.

## Calidad

```bash
flutter analyze
flutter test
```

`test/core/http_client_test.dart` contiene los siete escenarios del cliente y `test/core/failure_test.dart` comprueba la jerarquía de fallos. Las pruebas del cliente no hacen solicitudes reales.

## Carpetas

- `lib/main.dart`: pantalla de pedidos.
- `lib/core/`: cliente HTTP y fallos tipados.
- `test/core/`: pruebas unitarias.
- `android/` y `web/`: archivos de plataforma de Flutter.
