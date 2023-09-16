#!/bin/bash
rm /misc/workspace/treeco/app/instalavel/treeco.aab -f

flutter packages get
flutter packages pub run flutter_launcher_icons:main
# flutter build apk --split-per-abi
flutter build appbundle

mv /misc/workspace/treeco/app/build/app/outputs/bundle/release/app-release.aab /misc/workspace/treeco/app/instalavel/treeco.aab