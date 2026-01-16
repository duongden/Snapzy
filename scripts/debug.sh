APP_NAME="ZapShot"

xcodebuild \
  -scheme $APP_NAME \
  -configuration Debug \
  build && \
open ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug/$APP_NAME.app