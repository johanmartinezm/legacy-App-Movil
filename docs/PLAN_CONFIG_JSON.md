# Plan de Implementación: Configuración Dinámica mediante JSON (Assets)

Este documento detalla el plan técnico para centralizar las variables de entorno y URLs de backend en un archivo JSON externo, permitiendo cambios de configuración sin necesidad de recompilar el código fuente de Flutter.

---

## 🏗️ Arquitectura Propuesta

### 1. Archivo de Configuración (`assets/config/config.json`)
Centralizará las URLs de los servicios REST y GraphQL.

```json
{
  "api_base_url": "http://10.0.2.2:8080",
  "graphql_base_url": "https://legacynetworkco.com/graphql",
  "environment": "development"
}
```

### 2. Servicio de Carga (`lib/data/config/config_service.dart`)
Una clase estática (o Singleton) encargada de leer el JSON y exponer las variables.

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigService {
  static Map<String, dynamic> _config = {};

  static Future<void> initialize() async {
    final String response = await rootBundle.loadString('assets/config/config.json');
    _config = json.decode(response);
  }

  static String get apiBaseUrl => _config['api_base_url'] ?? '';
  static String get graphqlBaseUrl => _config['graphql_base_url'] ?? '';
  static String get environment => _config['environment'] ?? 'production';
}
```

---

## 🚀 Pasos para la Ejecución

### Fase 1: Preparación de Assets
1.  Crear el directorio `assets/config/` si no existe.
2.  Crear el archivo `config.json` con las variables iniciales.
3.  Registrar el directorio en el `pubspec.yaml`:
    ```yaml
    flutter:
      assets:
        - assets/config/
    ```

### Fase 2: Implementación de Lógica
1.  **ConfigService**: Crear el archivo `lib/data/config/config_service.dart`.
2.  **Inicialización**: Modificar el `main()` en `lib/main.dart` para asegurar la carga antes del `runApp`:
    ```dart
    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await ConfigService.initialize();
      // ... resto del código
    }
    ```

### Fase 3: Refactorización de Servicios
1.  **ApiConstants**: Actualizar `lib/data/config/api_constants.dart` para retornar `ConfigService.apiBaseUrl`.
2.  **GraphqlService**: Actualizar `lib/data/services/graphql_service.dart` para usar `ConfigService.graphqlBaseUrl`.

---

## 📝 Criterios de Validación (QA)
- [ ] Verificar que la app inicie correctamente (sin pantalla negra por error de carga de JSON).
- [ ] Confirmar que las peticiones REST apunten a la URL del JSON.
- [ ] Confirmar que el contenido de GraphQL se cargue desde la URL definida en el JSON.
- [ ] Probar el cambio de URL en el JSON y verificar que la app lo tome tras un reinicio en caliente (Hot Restart).

---
**Fecha de creación:** 2026-03-11
**Estado:** Pendiente de ejecución
