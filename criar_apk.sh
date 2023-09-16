#!/bin/bash
rm /misc/workspace/treeco/app/instalavel/treeco.apk -f

flutter packages get
flutter packages pub run flutter_launcher_icons:main
flutter build apk #--split-per-abi

mv /misc/workspace/treeco/app/build/app/outputs/flutter-apk/app-release.apk /misc/workspace/treeco/app/instalavel/treeco.apk