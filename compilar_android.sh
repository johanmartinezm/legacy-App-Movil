#!/bin/bash

# ==============================================================================
# Script de Compilación para Android (Release)
# Proyecto: Legacy App
# 
# Descripción:
# Este script automatiza el proceso de limpieza, instalación de dependencias
# y compilación del App Bundle (.aab) firmado para su carga en Google Play Store.
# ==============================================================================

# Detener el script si ocurre un error
set -e

# Colores para la salida en consola
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}🚀 INICIANDO COMPILACIÓN ANDROID - RELEASE${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Limpieza del proyecto
# Se realiza limpieza para evitar conflictos con archivos temporales de builds previas.
echo -e "${YELLOW}🧹 Limpiando proyecto...${NC}"
flutter clean

# 2. Obtención de dependencias
# Asegura que todos los paquetes definidos en pubspec.yaml estén actualizados.
echo -e "${YELLOW}📦 Obteniendo dependencias...${NC}"
flutter pub get

# 3. Compilación del App Bundle
# Se utiliza el formato .aab (App Bundle) requerido por Google Play.
# Se añade --obfuscate y --split-debug-info para mejorar la seguridad del código
# y reducir el tamaño del binario final mediante la optimización de símbolos.
echo -e "${YELLOW}🏗️ Compilando App Bundle (.aab)...${NC}"
flutter build appbundle --release \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

# Nota: Si necesitas compilar un APK para pruebas directas, puedes usar:
# flutter build apk --release

# 4. Verificación del resultado
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_PATH" ]; then
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}✅ COMPILACIÓN EXITOSA!${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${BLUE}Ubicación del archivo:${NC}"
    echo -e "${GREEN}$AAB_PATH${NC}"
    echo -e "${BLUE}Símbolos de depuración:${NC}"
    echo -e "${GREEN}build/app/outputs/symbols${NC}"
    echo -e "${YELLOW}⚠️ Recuerda subir los archivos de símbolos a Play Store para obtener stacktraces legibles.${NC}"
else
    echo -e "${RED}❌ Error: No se encontró el archivo generado en $AAB_PATH${NC}"
    exit 1
fi
