# 📚 Guía de Actualización de Flutter - Dependencias y Extensiones

## 📦 **ACTUALIZAR DEPENDENCIAS DE FLUTTER**

### 1️⃣ **Ver qué dependencias están desactualizadas**

```powershell
flutter pub outdated
```

**Resultado:** Muestra una tabla con:
- **Current:** Versión actual instalada
- **Upgradable:** Versión más reciente compatible con tus restricciones
- **Resolvable:** Versión que se puede resolver sin cambios mayores
- **Latest:** Última versión disponible en pub.dev

---

### 2️⃣ **Actualizar dependencias (sin cambios mayores)**

```powershell
flutter pub upgrade
```

**¿Qué hace?**
- Actualiza todas las dependencias dentro de las restricciones del `pubspec.yaml`
- Respeta las versiones especificadas (ej: `^1.0.0` no sube a `2.0.0`)
- Seguro de usar, no rompe código

---

### 3️⃣ **Actualizar con cambios mayores (breaking changes)**

```powershell
flutter pub upgrade --major-versions
```

**¿Qué hace?**
- Actualiza dependencias a versiones mayores (ej: `1.x.x` → `2.x.x`)
- Modifica automáticamente el `pubspec.yaml`
- ⚠️ **CUIDADO:** Puede introducir breaking changes

**Ejemplo de cambios automáticos:**
```yaml
# ANTES
permission_handler: ^11.3.1
flutter_lints: ^5.0.0

# DESPUÉS
permission_handler: ^12.0.1  # ⬆️ Actualizado
flutter_lints: ^6.0.0        # ⬆️ Actualizado
```

---

### 4️⃣ **Obtener dependencias (primera vez o después de cambios manuales)**

```powershell
flutter pub get
```

**¿Cuándo usar?**
- Después de clonar un proyecto
- Después de editar manualmente `pubspec.yaml`
- Después de cambiar de rama en Git

---

### 5️⃣ **Limpiar caché de dependencias**

```powershell
flutter pub cache clean
flutter pub get
```

**¿Cuándo usar?**
- Cuando hay errores de dependencias corruptas
- Después de cambios mayores en el proyecto

---

## 🔧 **ACTUALIZAR FLUTTER SDK**

### Verificar versión actual

```powershell
flutter --version
```

### Actualizar Flutter

```powershell
flutter upgrade
```

**Incluye:**
- Flutter SDK
- Dart SDK
- Engine
- Framework

### Actualizar a un canal específico

```powershell
# Ver canal actual
flutter channel

# Cambiar a canal estable
flutter channel stable
flutter upgrade

# Otros canales
flutter channel beta
flutter channel dev
```

---

## 🧹 **LIMPIEZA Y REPARACIÓN**

### Limpiar build cache

```powershell
flutter clean
flutter pub get
```

### Reparar instalación de Flutter

```powershell
flutter doctor
flutter doctor -v  # Versión detallada
```

### Resolver problemas de dependencias

```powershell
# 1. Limpiar
flutter clean
rm pubspec.lock  # O eliminar manualmente

# 2. Obtener de nuevo
flutter pub get

# 3. Si persiste el problema
flutter pub cache clean
flutter pub get
```

---

## 🎯 **EXTENSIONES DE VS CODE**

### Ver extensiones instaladas

1. Abrir VS Code
2. Presionar `Ctrl + Shift + X`
3. Ver lista de extensiones instaladas

### Actualizar extensiones manualmente

1. Click en el ícono de engranaje ⚙️ de cada extensión
2. Seleccionar "Update" si está disponible

### Actualizar todas las extensiones

1. `Ctrl + Shift + P`
2. Escribir: "Extensions: Update All Extensions"
3. Enter

### Archivo de extensiones recomendadas (ya creado)

Tu proyecto ya tiene `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "nash.awesome-flutter-snippets",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker",
    "alexisvt.flutter-snippets",
    "jeroen-meijer.pubspec-assist"
  ]
}
```

**Instalar extensiones recomendadas:**
1. Abrir proyecto en VS Code
2. VS Code mostrará una notificación
3. Click en "Install All"

---

## 📋 **DEPENDENCIAS ACTUALIZADAS EN TU PROYECTO**

### ✅ Actualizaciones realizadas hoy:

| Paquete | Antes | Después | Tipo |
|---------|-------|---------|------|
| `permission_handler` | 11.4.0 | **12.0.1** | ⬆️ Major |
| `flutter_lints` | 5.0.0 | **6.0.0** | ⬆️ Major |
| `cross_file` | 0.3.4+2 | **0.3.5** | ⬆️ Minor |
| `image_picker_android` | 0.8.13+5 | **0.8.13+7** | ⬆️ Patch |
| `image_picker_platform_interface` | 2.11.0 | **2.11.1** | ⬆️ Patch |
| `path_provider_android` | 2.2.18 | **2.2.20** | ⬆️ Patch |
| `path_provider_foundation` | 2.4.2 | **2.4.3** | ⬆️ Patch |
| `win32` | 5.14.0 | **5.15.0** | ⬆️ Minor |
| `lints` | 5.1.1 | **6.0.0** | ⬆️ Major |

### ⚠️ Pendientes (requieren atención manual):

- **flutter_secure_storage** (versiones de plataforma desactualizadas)
  - Linux: 1.2.3 → 2.0.1
  - macOS: 3.1.3 → 4.0.0
  - Windows: 3.1.2 → 4.0.0
  - Web: 1.2.1 → 2.0.0

**Para actualizar:**
```powershell
flutter pub upgrade --major-versions flutter_secure_storage
```

---

## 🔄 **WORKFLOW RECOMENDADO**

### Actualización mensual:

```powershell
# 1. Ver qué hay disponible
flutter pub outdated

# 2. Actualizar sin breaking changes
flutter pub upgrade

# 3. Probar la app
flutter run

# 4. Si todo funciona, hacer commit
git add pubspec.lock
git commit -m "chore: actualizar dependencias"
```

### Actualización trimestral:

```powershell
# 1. Actualizar Flutter SDK
flutter upgrade

# 2. Actualizar con breaking changes
flutter pub upgrade --major-versions

# 3. Limpiar
flutter clean

# 4. Reinstalar
flutter pub get

# 5. Probar exhaustivamente
flutter test
flutter run

# 6. Revisar changelog de paquetes actualizados
# Verificar si hay cambios en APIs
```

---

## 🚨 **SOLUCIÓN DE PROBLEMAS COMUNES**

### Error: "Version solving failed"

```powershell
flutter pub cache clean
rm pubspec.lock
flutter pub get
```

### Error: "package has breaking changes"

1. Leer el changelog del paquete en pub.dev
2. Actualizar código según cambios requeridos
3. O mantener versión anterior temporalmente

### Error de plataforma específica

```powershell
# Android
cd android
./gradlew clean

# iOS
cd ios
rm -rf Pods
rm Podfile.lock
pod install

# Volver a raíz
cd ..
flutter clean
flutter pub get
```

---

## 📚 **RECURSOS ÚTILES**

- **pub.dev:** https://pub.dev/ (buscar paquetes y ver changelog)
- **Flutter docs:** https://docs.flutter.dev/packages-and-plugins
- **Dart pub commands:** https://dart.dev/tools/pub/cmd

---

## ✅ **CHECKLIST DE ACTUALIZACIÓN**

- [ ] `flutter pub outdated` - Ver actualizaciones disponibles
- [ ] `flutter pub upgrade` - Actualizar sin breaking changes
- [ ] `flutter run` - Probar que la app funcione
- [ ] Revisar warnings en la consola
- [ ] `flutter pub upgrade --major-versions` - Si es necesario
- [ ] Leer changelogs de paquetes con cambios mayores
- [ ] `flutter test` - Ejecutar tests
- [ ] `git add pubspec.yaml pubspec.lock`
- [ ] `git commit -m "chore: actualizar dependencias"`

---

*Documento creado: 2 de noviembre de 2025*
