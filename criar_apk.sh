#!/bin/bash
flutter packages get
flutter packages pub run flutter_launcher_icons:main
flutter build apk #--split-per-abi
rm /misc/workspace/treeco/instalavel/treeco.apk -f
mv /misc/workspace/treeco/build/app/outputs/flutter-apk/app-release.apk /misc/workspace/treeco/instalavel/treeco.apk