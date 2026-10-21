#!/usr/bin/env bash
# Gera a pasta android/ (se ainda não existir) e ajusta nome, permissão
# de internet (para baixar as fontes pixel) e ícone padrão.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org com.guilhermefuentes --project-name rotina_quest .
  # flutter create recria o teste de exemplo; o projeto já tem os seus.
  rm -f test/widget_test.dart
fi

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  sed -i 's#<manifest xmlns:android="http://schemas.android.com/apk/res/android">#<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
fi
sed -i 's#android:label="rotina_quest"#android:label="Rotina Quest"#' "$MANIFEST"

echo "android/ pronto"
