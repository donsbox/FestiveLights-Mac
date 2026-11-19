#!/bin/bash
set -euo pipefail

APP_NAME="FestiveLights"
BUNDLE_ID="com.festivelights.menubar"
VERSION="1.0.0"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_OUTPUT="./$APP_NAME.dmg"

echo "🎄 开始构建 $APP_NAME (原生 macOS 菜单栏彩灯应用)..."

if ! command -v swiftc >/dev/null 2>&1; then
    echo "❌ 未检测到 swiftc。请先运行 xcode-select --install"
    exit 1
fi

rm -rf "$BUILD_DIR" "$DMG_OUTPUT"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

# 1. 编译 Universal Binary (同时支持 Apple Silicon 与 Intel Mac)
SDK_PATH=$(xcrun --show-sdk-path)
echo "🔨 正在编译 Universal 原生可执行文件 (arm64 + x86_64)..."
if swiftc -O -sdk "$SDK_PATH" -target arm64-apple-macos12.0 -framework Cocoa main.swift -o "$BUILD_DIR/${APP_NAME}_arm64" && \
   swiftc -O -sdk "$SDK_PATH" -target x86_64-apple-macos12.0 -framework Cocoa main.swift -o "$BUILD_DIR/${APP_NAME}_x86_64"; then
    lipo -create -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
        "$BUILD_DIR/${APP_NAME}_arm64" \
        "$BUILD_DIR/${APP_NAME}_x86_64"
    echo "✅ Universal Binary 编译成功"
else
    echo "⚠️ 回退至当前架构编译..."
    swiftc -O -framework Cocoa main.swift -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
fi

# 2. 生成应用图标 (.icns)
echo "🎨 正在生成 App 图标..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
swift generate_icon.swift "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# 3. 写入 Info.plist (LSUIElement=true 确保仅驻留菜单栏，不占 Dock)
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 4. 本地 Ad-hoc 签名
echo "🔏 正在执行 Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 5. 打包标准 DMG 安装镜像（含 Applications 快捷方式与 CI 防忙重试）
echo "📦 正在打包 $DMG_OUTPUT ..."
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

for attempt in 1 2 3; do
    if hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGING" \
        -ov \
        -format UDZO \
        "$DMG_OUTPUT"; then
        break
    fi
    echo "⏳ hdiutil 繁忙，3 秒后重试 ($attempt/3)..."
    sleep 3
done

echo "✅ 构建完成：$(pwd)/$APP_NAME.dmg"
