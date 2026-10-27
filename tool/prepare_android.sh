#!/usr/bin/env bash
# A pasta android/ já vem no repositório (com ícone e nome do app).
# Este script só a recria se ela tiver sido apagada.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org com.guilhermefuentes --project-name rotina_quest .
  rm -f test/widget_test.dart
  sed -i 's#android:label="Divine Routine"#android:label="Divine Routine"#' android/app/src/main/AndroidManifest.xml
fi

echo "android/ pronto"
