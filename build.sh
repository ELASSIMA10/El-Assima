#!/bin/bash
echo "Téléchargement de Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Configuration de Flutter..."
flutter config --enable-web
flutter pub get

echo "Construction de l'application Web..."
flutter build web --release

echo "Build terminé !"
