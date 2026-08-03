#!/bin/bash

# ==============================================================================
# Script de compilación web para Flutter (Legacy Network App)
# Mantenibilidad y Clean Code: Asegura compilaciones limpias en producción
# ==============================================================================

# Detenemos la ejecución si ocurre algún error
set -e

echo "🧹 1. Limpiando el proyecto (Eliminando builds previos)..."
flutter clean

echo "📦 2. Obteniendo paquetes (Actualizando dependencias)..."
flutter pub get

echo "🚀 3. Compilando aplicación Flutter para Web en modo Release..."
# Usa CanvasKit para mejor rendimiento y fidelidad visual si la app es compleja.
flutter build web --release 

echo "✅ ¡Compilación exitosa!"
echo "📂 Los archivos están listos para ser desplegados. Ubicación: build/web/"
