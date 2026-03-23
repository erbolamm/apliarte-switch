#!/usr/bin/env bash
# install.sh — Script de instalación de ApliArteSwitch para macOS y Linux
# Uso: curl -fsSL https://raw.githubusercontent.com/erbolamm/apliarte-switch/main/scripts/install.sh | bash

set -e

REPO="erbolamm/apliarte-switch"
BIN_NAME="apliarte-switch"
INSTALL_DIR="/usr/local/bin"

# Detectar SO y arquitectura
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "🔍 Detectando sistema: $OS $ARCH"

case "$OS" in
  Darwin)
    case "$ARCH" in
      x86_64) TARGET="x86_64-apple-darwin" ;;
      arm64)  TARGET="aarch64-apple-darwin" ;;
      *) echo "❌ Arquitectura no soportada: $ARCH"; exit 1 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
      aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
      *) echo "❌ Arquitectura no soportada: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "❌ Sistema operativo no soportado: $OS"
    echo "   Usa el script install.ps1 en Windows"
    exit 1
    ;;
esac

# Obtener la última versión disponible
echo "📡 Obteniendo última versión..."
VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "⚠️  No se encontró ninguna release publicada."
  echo "   El proyecto está en desarrollo activo."
  echo "   Compila desde código fuente con: cargo install apliarte-switch"
  exit 1
fi

echo "📦 Versión: $VERSION"

# Descargar el binario
URL="https://github.com/$REPO/releases/download/$VERSION/$BIN_NAME-$TARGET"
TMP="$(mktemp -d)"
DEST="$TMP/$BIN_NAME"

echo "⬇️  Descargando $BIN_NAME para $TARGET..."
curl -fsSL "$URL" -o "$DEST"
chmod +x "$DEST"

# Instalar en /usr/local/bin
echo "📂 Instalando en $INSTALL_DIR/$BIN_NAME..."
if [ -w "$INSTALL_DIR" ]; then
  mv "$DEST" "$INSTALL_DIR/$BIN_NAME"
else
  sudo mv "$DEST" "$INSTALL_DIR/$BIN_NAME"
fi

# Limpiar temporales
rm -rf "$TMP"

echo ""
echo "✅ ¡ApliArteSwitch instalado correctamente!"
echo ""
echo "🚀 Para empezar:"
echo "   apliarte-switch          → arranca el servicio"
echo "   apliarte-switch --help   → ver todas las opciones"
echo ""

# Aviso especial para Linux (uinput)
if [ "$OS" = "Linux" ]; then
  echo "⚠️  En Linux necesitas dar permisos de input:"
  echo "   sudo usermod -a -G input \$USER"
  echo "   (Cierra sesión y vuelve a entrar para que se aplique)"
  echo ""
fi
