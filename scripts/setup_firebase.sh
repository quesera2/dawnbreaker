#!/bin/bash
set -e

export PATH="$PATH":"$HOME/.pub-cache/bin"

echo "=== dev ==="
fvm exec flutterfire configure \
  --project=dawn-breaker-dev \
  --ios-bundle-id=que.sera.sera.dawnbreaker.dev \
  --android-package-name=que.sera.sera.dawnbreaker.dev \
  --out=lib/firebase_options_dev.dart \
  --platforms=ios,android \
  --yes

mv android/app/google-services.json android/app/src/dev/google-services.json
mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info-Dev.plist

echo "=== prod ==="
fvm exec flutterfire configure \
  --project=dawn-breaker \
  --ios-bundle-id=que.sera.sera.dawnbreaker \
  --android-package-name=que.sera.sera.dawnbreaker \
  --out=lib/firebase_options_prod.dart \
  --platforms=ios,android \
  --yes

mv android/app/google-services.json android/app/src/prod/google-services.json
mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info-Prod.plist

echo "=== 完了 ==="
