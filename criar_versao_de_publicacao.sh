#!/bin/bash
flutter packages get
flutter packages pub run flutter_launcher_icons:main
# flutter build apk --split-per-abi
flutter build appbundle
rm /misc/workspace/treeco/instalavel/treeco.aab -f
mv /misc/workspace/treeco/build/app/outputs/bundle/release/app-release.aab /misc/workspace/treeco/instalavel/treeco.aab