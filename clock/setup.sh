#!/usr/bin/env bash
# Rebuilds generated/ (a throwaway Flutter project) around the hand-written files.
# Usage: ./setup.sh        then:  cd generated && flutter run -d linux
set -euo pipefail
cd "$(dirname "$0")"
rm -rf generated && mkdir -p generated build
cd generated
flutter create --project-name clock_app --org local.hobby --platforms linux,windows,macos,android . >/dev/null
rm -rf lib test
ln -sf ../src lib
ln -sf ../test ../assets ../analysis_options.yaml ../pubspec.yaml .
ln -s ../build build
# plugin hides the title bar only if the runner doesn't force a GTK header bar
sed -i 's/use_header_bar = TRUE/use_header_bar = FALSE/' linux/runner/my_application.cc
flutter pub get
echo "Done. cd generated && flutter run -d linux   (output lands in build/)"
