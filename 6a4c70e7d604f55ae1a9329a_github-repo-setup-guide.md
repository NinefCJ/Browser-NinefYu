# GitHub 仓库初始化与配置指南

## 一、创建仓库

### 1.1 GitHub 网页创建

1. 访问 https://github.com/new
2. 填写信息：
   - **Repository name**: `browser`（或你的项目名）
   - **Description**: 五平台 AI 原生浏览器
   - **Visibility**: Public（推荐开源）或 Private
   - **Initialize this repository with**: 勾选 `Add a README file`
3. 点击 **Create repository**

### 1.2 本地关联

```bash
# 克隆到本地
git clone https://github.com/你的用户名/browser.git
cd browser

# 配置 Git 身份
git config user.name "你的名字"
git config user.email "你的邮箱"

# 创建 .gitignore（Flutter 专用）
cat > .gitignore << 'EOF'
# Flutter/Dart
.dart_tool/
.packages
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds
.pub-cache/
.pub/

# Android
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks

# iOS/XCode
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral/
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# macOS
**/macos/Flutter/GeneratedPluginRegistrant.swift
**/macos/Flutter/ephemeral/

# Windows
**/windows/flutter/generated_plugin_registrant.cc
**/windows/flutter/generated_plugin_registrant.h
**/windows/flutter/generated_plugins.cmake

# Linux
**/linux/flutter/generated_plugin_registrant.cc
**/linux/flutter/generated_plugin_registrant.h
**/linux/flutter/generated_plugins.cmake

# IDE
.idea/
.vscode/
*.iml
*.ipr
*.iws

# 系统文件
.DS_Store
Thumbs.db

# 测试覆盖率
coverage/
*.lcov

# 环境配置
.env
.env.local
EOF

git add .gitignore
git commit -m "chore: add .gitignore"
git push origin main
```

---

## 二、完整目录结构

创建仓库后，按以下结构初始化项目文件：

```
browser/
├── .github/
│   ├── workflows/                    # CI/CD 工作流
│   │   ├── release.yml              # 统一 Release 触发
│   │   ├── android.yml              # Android APK
│   │   ├── ios.yml                  # iOS IPA
│   │   ├── windows.yml              # Windows MSI
│   │   ├── macos.yml                # macOS DMG
│   │   ├── linux.yml                # Linux AppImage
│   │   ├── web.yml                  # Web 版（可选）
│   │   └── ci.yml                   # PR 快速检查
│   │
│   ├── ISSUE_TEMPLATE/              # Issue 模板
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   └── config.yml
│   │
│   ├── PULL_REQUEST_TEMPLATE.md     # PR 模板
│   ├── CODEOWNERS                   # 代码审查分配
│   ├── CODE_OF_CONDUCT.md           # 行为准则
│   ├── CONTRIBUTING.md              # 贡献指南
│   ├── FUNDING.yml                  # 赞助配置
│   └── dependabot.yml               # 依赖自动更新
│
├── lib/                             # Flutter Dart 代码
│   ├── main.dart
│   ├── core/
│   ├── platforms/
│   ├── features/
│   └── ui/
│
├── android/                         # Android 原生层
├── ios/                             # iOS 原生层
├── windows/                         # Windows 原生层
│   └── installer/
│       └── browser.iss              # Inno Setup 脚本
├── macos/                           # macOS 原生层
├── linux/                           # Linux 原生层
│   └── packaging/
│       └── linux/
│           └── browser.desktop
├── shared/                          # KMP 共享模块
├── test/                            # 单元测试
├── integration_test/                # 集成测试
├── docs/                            # 文档
│   ├── architecture.md
│   ├── api_reference.md
│   └── changelog.md
│
├── pubspec.yaml                     # Flutter 依赖
├── analysis_options.yaml            # Dart 代码规范
├── LICENSE                          # 开源协议
├── README.md                        # 项目说明
├── CHANGELOG.md                     # 版本日志
└── BROWSER_FULL_PLAN.md             # 完整方案文档
```

### 2.1 初始化命令

```bash
# 创建目录结构
mkdir -p .github/workflows .github/ISSUE_TEMPLATE
mkdir -p lib/core lib/platforms lib/features lib/ui
mkdir -p android/app/src/main/kotlin/engine
mkdir -p android/app/src/main/kotlin/download
mkdir -p android/app/src/main/kotlin/script
mkdir -p windows/installer
mkdir -p linux/packaging/linux
mkdir -p docs
mkdir -p test integration_test

# 创建空文件占位
touch lib/main.dart
touch lib/core/browser_api.dart
touch lib/core/tab_manager.dart
touch lib/core/download_service.dart
touch lib/core/settings_service.dart
touch lib/platforms/engine_factory.dart
touch lib/features/adblock/.gitkeep
touch lib/features/script/.gitkeep
touch lib/features/download/.gitkeep
touch lib/features/ai_chat/.gitkeep
touch lib/features/ai_tab/.gitkeep
touch lib/features/ai_writer/.gitkeep
touch lib/features/ai_agent/.gitkeep
touch lib/features/skills/.gitkeep
touch lib/features/subscription/.gitkeep
```

---

## 三、GitHub Actions 工作流文件

在 `.github/workflows/` 目录下创建以下文件。内容已在 `BROWSER_FULL_PLAN.md` 中提供，此处给出完整可直接使用的版本。

### 3.1 统一 Release 触发器

```yaml
# .github/workflows/release.yml
name: Release All Platforms

on:
  push:
    tags:
      - 'v*'

jobs:
  android:
    uses: ./.github/workflows/android.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  ios:
    uses: ./.github/workflows/ios.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  windows:
    uses: ./.github/workflows/windows.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  macos:
    uses: ./.github/workflows/macos.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  linux:
    uses: ./.github/workflows/linux.yml
    with:
      build_type: release
      version: ${{ github.ref_name }}
    secrets: inherit

  create-release:
    needs: [android, ios, windows, macos, linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/download-artifact@v4
        with:
          path: build
          merge-multiple: true

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          name: Browser ${{ github.ref_name }}
          body: |
            ## Downloads
            | Platform | File | Size |
            |----------|------|------|
            | Android | `*.apk` | ~20MB |
            | iOS | `*.ipa` | ~20MB |
            | Windows | `*-setup.exe` | ~30MB |
            | macOS | `*.dmg` | ~25MB |
            | Linux | `*.AppImage` | ~25MB |
          files: build/*
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3.2 Android 构建

```yaml
# .github/workflows/android.yml
name: Android Build

on:
  workflow_call:
    inputs:
      build_type:
        type: string
        default: debug
      version:
        type: string
        default: '1.0.0'
  workflow_dispatch:
    inputs:
      build_type:
        type: choice
        options: [debug, release]
        default: debug
      version:
        type: string
        default: '1.0.0'

jobs:
  build-android:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Decode signing key
        if: inputs.build_type == 'release'
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
          cat > android/key.properties << EOF
          storeFile=keystore.jks
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          EOF

      - name: Build Release APK
        if: inputs.build_type == 'release'
        run: |
          flutter build apk --release \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --dart-define=ENV=production \
            --obfuscate \
            --split-debug-info=build/debug-info

      - name: Build Debug APK
        if: inputs.build_type == 'debug'
        run: flutter build apk --debug

      - uses: actions/upload-artifact@v4
        with:
          name: android-${{ inputs.build_type }}
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 30
```

### 3.3 iOS 构建

```yaml
# .github/workflows/ios.yml
name: iOS Build

on:
  workflow_call:
    inputs:
      build_type:
        type: string
        default: debug
      version:
        type: string
        default: '1.0.0'
  workflow_dispatch:
    inputs:
      build_type:
        type: choice
        options: [debug, release]
        default: debug
      version:
        type: string
        default: '1.0.0'

jobs:
  build-ios:
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true

      - run: flutter pub get
      - run: cd ios && pod install --repo-update

      - name: Import certificates
        if: inputs.build_type == 'release'
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_P12_BASE64 }}
          p12-password: ${{ secrets.IOS_P12_PASSWORD }}

      - name: Install Provisioning Profile
        if: inputs.build_type == 'release'
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}" | base64 -d \
            > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

      - name: Build Release IPA
        if: inputs.build_type == 'release'
        run: |
          flutter build ipa --release \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --export-options-plist=ios/ExportOptions.plist \
            --dart-define=ENV=production \
            --obfuscate \
            --split-debug-info=build/debug-info

      - name: Build Debug
        if: inputs.build_type == 'debug'
        run: flutter build ios --debug --no-codesign

      - name: Archive IPA
        if: inputs.build_type == 'release'
        run: |
          cd build/ios/ipa
          mkdir -p ../../output
          zip -r ../../output/browser-${{ inputs.version }}-ios.ipa Payload

      - uses: actions/upload-artifact@v4
        if: inputs.build_type == 'release'
        with:
          name: ios-release
          path: build/output/*.ipa
          retention-days: 30
```

### 3.4 Windows 构建（MSI + Inno Setup）

```yaml
# .github/workflows/windows.yml
name: Windows Build

on:
  workflow_call:
    inputs:
      build_type:
        type: string
        default: debug
      version:
        type: string
        default: '1.0.0'
  workflow_dispatch:
    inputs:
      build_type:
        type: choice
        options: [debug, release]
        default: debug
      version:
        type: string
        default: '1.0.0'

jobs:
  build-windows:
    runs-on: windows-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Build Windows
        shell: pwsh
        run: |
          $mode = "${{ inputs.build_type }}"
          $envArg = if ($mode -eq "release") { "production" } else { "staging" }
          flutter build windows --$mode --build-name=${{ inputs.version }} --build-number=${{ github.run_number }} --dart-define=ENV=$envArg

      - name: Create Inno Setup installer
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          choco install innosetup -y
          $outDir = "build\windows\x64\runner\Release"
          $version = "${{ inputs.version }}"

          $issContent = @"
          [Setup]
          AppName=Browser
          AppVersion=$version
          DefaultDirName={pf}\Browser
          DefaultGroupName=Browser
          OutputDir=build
          OutputBaseFilename=browser-$version-windows-setup
          Compression=lzma2/ultra64
          SolidCompression=yes
          SetupIconFile=windows\runner\resources\app_icon.ico
          ArchitecturesAllowed=x64compatible
          ArchitecturesInstallIn64BitMode=x64compatible
          AllowPathPersistence=yes
          DisableDirPage=no
          DisableProgramGroupPage=yes
          PrivilegesRequired=admin
          PrivilegesRequiredOverridesAllowed=dialog

          [Messages]
          SelectDirBrowseLabel=选择安装 Browser 的文件夹。

          [Files]
          Source: "$outDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

          [Icons]
          Name: "{group}\Browser"; Filename: "{app}\browser.exe"
          Name: "{autodesktop}\Browser"; Filename: "{app}\browser.exe"

          [Registry]
          Root: HKLM; Subkey: "Software\Browser"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletevalue
          Root: HKLM; Subkey: "Software\Browser"; ValueType: string; ValueName: "Version"; ValueData: "$version"; Flags: uninsdeletevalue

          [Run]
          Filename: "{app}\browser.exe"; Description: "启动 Browser"; Flags: nowait postinstall skipifsilent
          "@

          $issContent | Out-File -FilePath "windows\installer\browser.iss" -Encoding UTF8
          & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer\browser.iss

      - name: Code sign
        if: inputs.build_type == 'release'
        shell: pwsh
        run: |
          $cert = "${{ secrets.WINDOWS_CERT_BASE64 }}"
          if ($cert) {
            $certBytes = [Convert]::FromBase64String($cert)
            [IO.File]::WriteAllBytes("build\cert.pfx", $certBytes)
            $exe = Get-ChildItem build\browser-*-windows-setup.exe | Select-Object -First 1
            if ($exe) {
              & signtool sign /f build\cert.pfx /p "${{ secrets.WINDOWS_CERT_PASSWORD }}" /tr http://timestamp.digicert.com /td sha256 $exe.FullName
            }
          }
        continue-on-error: true

      - uses: actions/upload-artifact@v4
        with:
          name: windows-${{ inputs.build_type }}
          path: build/*.exe
          retention-days: 30
```

### 3.5 macOS 构建

```yaml
# .github/workflows/macos.yml
name: macOS Build

on:
  workflow_call:
    inputs:
      build_type:
        type: string
        default: debug
      version:
        type: string
        default: '1.0.0'
  workflow_dispatch:
    inputs:
      build_type:
        type: choice
        options: [debug, release]
        default: debug
      version:
        type: string
        default: '1.0.0'

jobs:
  build-macos:
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true

      - run: flutter pub get

      - name: Build macOS
        run: |
          flutter build macos --${{ inputs.build_type == 'release' && 'release' || 'debug' }} \
            --build-name=${{ inputs.version }} \
            --build-number=${{ github.run_number }} \
            --dart-define=ENV=${{ inputs.build_type == 'release' && 'production' || 'staging' }}

      - name: Create DMG
        if: inputs.build_type == 'release'
        run: |
          brew install create-dmg
          create-dmg \
            --volname "Browser" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --app-drop-link 460 220 \
            "build/browser-${{ inputs.version }}-macos.dmg" \
            "build/macos/Build/Products/Release/browser.app"

      - name: Code sign
        if: inputs.build_type == 'release'
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.MACOS_P12_BASE64 }}
          p12-password: ${{ secrets.MACOS_P12_PASSWORD }}

      - uses: actions/upload-artifact@v4
        with:
          name: macos-${{ inputs.build_type }}
          path: build/*.dmg
          retention-days: 30
```

### 3.6 Linux 构建

```yaml
# .github/workflows/linux.yml
name: Linux Build

on:
  workflow_call:
    inputs:
      build_type:
        type: string
        default: debug
      version:
        type: string
        default: '1.0.0'
  workflow_dispatch:
    inputs:
      build_type:
        type: choice
        options: [debug, release]
        default: debug
      version:
        type: string
        default: '1.0.0'

jobs:
  build-linux:
    runs-on: ubuntu-22.04
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update && sudo apt-get install -y \
            clang cmake ninja-build pkg-config \
            libgtk-3-dev libblkid-dev liblzma-dev \
            libsecret-1-dev libwebkit2gtk-4.1-dev \
            libjson-glib-dev libglib2.0-dev \
            librsvg2-dev libappindicator3-dev

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true

      - run: flutter config --enable-linux-desktop
      - run: flutter pub get

      - name: Build Linux
        run: |
          flutter build linux --${{ inputs.build_type == 'release' && 'release' || 'debug' }} \
            --dart-define=ENV=${{ inputs.build_type == 'release' && 'production' || 'staging' }}

      - name: Package AppImage
        if: inputs.build_type == 'release'
        run: |
          wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
          chmod +x linuxdeploy-x86_64.AppImage
          mkdir -p build/AppDir
          cp -r build/linux/x64/release/bundle/* build/AppDir/
          ./linuxdeploy-x86_64.AppImage --appdir build/AppDir --output appimage \
            --desktop-file=linux/packaging/linux/browser.desktop \
            --icon-file=linux/packaging/linux/browser.png
          mv Browser-*.AppImage build/browser-${{ inputs.version }}-linux.AppImage

      - uses: actions/upload-artifact@v4
        with:
          name: linux-${{ inputs.build_type }}
          path: build/*.AppImage
          retention-days: 30
```

### 3.7 CI 快速检查

```yaml
# .github/workflows/ci.yml
name: CI Check

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed lib/ test/
      - run: dart analyze lib/ --fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        if: github.event_name == 'pull_request'
        with:
          files: coverage/lcov.info
          fail_ci_if_error: false

  build-android-ci:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build apk --debug --dart-define=ENV=staging

  build-linux-ci:
    runs-on: ubuntu-22.04
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - name: Install deps
        run: |
          sudo apt-get update && sudo apt-get install -y \
            clang cmake ninja-build pkg-config \
            libgtk-3-dev libblkid-dev liblzma-dev \
            libsecret-1-dev libwebkit2gtk-4.1-dev
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: stable
          cache: true
      - run: flutter config --enable-linux-desktop
      - run: flutter pub get
      - run: flutter build linux --debug
```

---

## 四、GitHub 仓库配置

### 4.1 分支保护规则

进入仓库 **Settings → Branches → Add rule**：

| 规则 | 设置 |
|------|------|
| Branch name pattern | `main` |
| Require a pull request before merging | **勾选** |
| Require status checks to pass | **勾选**，添加 `analyze`, `build-android-ci`, `build-linux-ci` |
| Require branches to be up to date before merging | **勾选** |
| Require linear history | **勾选**（可选） |
| Include administrators | **勾选** |

为 `develop` 分支添加相同规则（如果有 develop 分支）。

### 4.2 Secrets 配置

进入仓库 **Settings → Secrets and variables → Actions → New repository secret**：

| Secret 名称 | 值 | 获取方式 |
|-------------|-----|----------|
| `ANDROID_KEYSTORE_BASE64` | base64 编码的 .jks 文件 | `base64 -w0 keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | 密钥库密码 | 自定义 |
| `ANDROID_KEY_ALIAS` | 密钥别名 | 自定义 |
| `ANDROID_KEY_PASSWORD` | 密钥密码 | 自定义 |
| `IOS_P12_BASE64` | 开发者证书 .p12 的 base64 | Keychain Access 导出 → base64 |
| `IOS_P12_PASSWORD` | p12 导出密码 | 导出时设置 |
| `IOS_PROVISION_PROFILE_BASE64` | 描述文件 .mobileprovision 的 base64 | Apple Developer Portal 下载 → base64 |
| `MACOS_P12_BASE64` | macOS 签名证书 base64 | 同 iOS |
| `MACOS_P12_PASSWORD` | p12 密码 | 同 iOS |
| `WINDOWS_CERT_BASE64` | 代码签名证书 .pfx 的 base64 | 购买后导出 → base64 |
| `WINDOWS_CERT_PASSWORD` | pfx 密码 | 购买时设置 |

**快速生成 base64：**

```bash
# macOS / Linux
base64 -w0 keystore.jks | pbcopy  # 复制到剪贴板
base64 -w0 certificate.p12 | pbcopy

# 或输出到文件
base64 -w0 keystore.jks > keystore.txt
```

### 4.3 Dependabot 配置

```yaml
# .github/dependabot.yml
version: 2
updates:
  # Dart/Flutter 依赖
  - package-ecosystem: pub
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "09:00"
    open-pull-requests-limit: 10
    labels:
      - dependencies
      - dart
    commit-message:
      prefix: "chore(deps)"
      include: scope

  # Android Gradle 依赖
  - package-ecosystem: gradle
    directory: /android
    schedule:
      interval: weekly
      day: monday
      time: "09:00"
    labels:
      - dependencies
      - android
    commit-message:
      prefix: "chore(deps)"
      include: scope

  # GitHub Actions
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: monthly
    labels:
      - dependencies
      - ci
    commit-message:
      prefix: "ci"
      include: scope
```

### 4.4 Issue 模板

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug Report
 description: 提交一个 bug
title: "[Bug] "
labels: [bug]
body:
  - type: markdown
    attributes:
      value: |
        感谢提交 bug！请尽可能提供详细信息以便定位。
  - type: dropdown
    id: platform
    attributes:
      label: 平台
      options:
        - Android
        - iOS
        - Windows
        - macOS
        - Linux
        - Web
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: 版本号
      placeholder: "例如 v1.0.0"
    validations:
      required: true
  - type: textarea
    id: description
    attributes:
      label: 问题描述
      placeholder: 清晰描述发生了什么
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: 复现步骤
      placeholder: |
        1. 打开 ...
        2. 点击 ...
        3. 看到错误
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: 期望行为
  - type: textarea
    id: logs
    attributes:
      label: 日志 / 截图
      render: shell
```

```yaml
# .github/ISSUE_TEMPLATE/feature_request.yml
name: Feature Request
description: 提议一个新功能
title: "[Feature] "
labels: [enhancement]
body:
  - type: textarea
    id: description
    attributes:
      label: 功能描述
      placeholder: 描述你希望添加的功能
    validations:
      required: true
  - type: textarea
    id: motivation
    attributes:
      label: 使用场景
      placeholder: 这个功能在什么场景下有用？
  - type: textarea
    id: alternatives
    attributes:
      label: 替代方案
      placeholder: 你考虑过其他实现方式吗？
```

```yaml
# .github/ISSUE_TEMPLATE/config.yml
blank_issues_enabled: false
contact_links:
  - name: 讨论区
    url: https://github.com/你的用户名/browser/discussions
    about: 有使用问题？先去讨论区看看
```

### 4.5 PR 模板

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->
## 变更内容

<!-- 简要描述这个 PR 做了什么 -->

## 关联 Issue

<!-- 关联的 Issue 编号，例如 Fixes #123 -->

## 平台检查

- [ ] Android
- [ ] iOS
- [ ] Windows
- [ ] macOS
- [ ] Linux

## 测试

- [ ] 单元测试通过
- [ ] 手动测试通过
- [ ] CI 通过

## 截图（如有 UI 变更）

<!-- 附上截图或录屏 -->

## 其他说明

<!-- 需要评审者特别注意的地方 -->
```

### 4.6 CODEOWNERS

```
# .github/CODEOWNERS
# 全局默认审查者
* @你的用户名

# 平台原生代码
/android/ @你的用户名
/ios/ @你的用户名
/windows/ @你的用户名
/macos/ @你的用户名
/linux/ @你的用户名

# CI/CD
/.github/workflows/ @你的用户名
```

### 4.7 FUNDING.yml（可选）

```yaml
# .github/FUNDING.yml
github: [你的用户名]
ko_fi: 你的用户名
```

---

## 五、代码规范配置

### 5.1 Dart 分析配置

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_put_control_body_on_new_line
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_unnecessary_containers
    - avoid_void_async
    - await_only_futures
    - camel_case_types
    - cancel_subscriptions
    - cast_nullable_to_non_nullable
    - constant_identifier_names
    - control_flow_in_finally
    - empty_statements
    - file_names
    - hash_and_equals
    - implementation_imports
    - iterable_contains_unrelated_type
    - list_remove_unrelated_type
    - no_duplicate_case_values
    - non_constant_identifier_names
    - null_closures
    - package_names
    - package_prefixed_library_names
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_if_null_operators
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_null_aware_operators
    - prefer_single_quotes
    - prefer_typing_uninitialized_variables
    - recursive_getters
    - slash_for_doc_comments
    - test_types_in_equals
    - throw_in_finally
    - type_init_formals
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_getters_setters
    - unnecessary_new
    - unnecessary_null_aware_assignments
    - unnecessary_null_in_if_null_operators
    - unnecessary_overrides
    - unnecessary_parenthesis
    - unnecessary_statements
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_rethrow_when_possible
    - valid_regexps

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"
  language:
    strict-casts: true
    strict-raw-types: true
```

### 5.2 pubspec.yaml 基础结构

```yaml
name: browser
description: 五平台 AI 原生浏览器
version: 0.1.0+1
publish_to: none

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # 网络
  dio: ^5.4.0
  cookie_jar: ^4.0.0
  dio_cookie_manager: ^3.1.0
  
  # 存储
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.20
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  
  # 权限
  permission_handler: ^11.3.0
  
  # 通知
  flutter_local_notifications: ^17.0.0
  
  # 加密
  crypto: ^3.0.3
  encrypt: ^5.0.0
  
  # FFI
  ffi: ^2.1.0
  
  # 国际化
  intl: ^0.19.0

dependency_overrides: {}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.18.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/images/
    - assets/icons/
```

### 5.3 commit 规范

采用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响逻辑） |
| `refactor` | 重构（不新增功能也不修复 bug） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建过程、依赖更新 |
| `ci` | CI/CD 配置 |

**示例：**

```
feat(download): add VPN-resilient download retry

- detect IP change during download
- auto-recover session on 403
- increase retry count to 8 for VPN scenarios

Closes #42
```

---

## 六、完整初始化脚本

```bash
#!/bin/bash
# init-repo.sh — 一键初始化仓库

set -e

REPO_URL="https://github.com/你的用户名/browser.git"
PROJECT_NAME="browser"

# 1. 克隆仓库
echo "==> 克隆仓库..."
git clone "$REPO_URL"
cd "$PROJECT_NAME"

# 2. 创建目录结构
echo "==> 创建目录结构..."
mkdir -p .github/workflows .github/ISSUE_TEMPLATE
mkdir -p lib/{core,platforms,features,ai,ui}
mkdir -p lib/features/{adblock,script,download,reader,sync,ai_chat,ai_tab,ai_writer,ai_agent,skills,subscription}
mkdir -p android/app/src/main/kotlin/{engine,download,script}
mkdir -p ios/Runner windows/installer macos/Runner linux/packaging/linux
mkdir -p shared/src/commonMain/kotlin
mkdir -p test integration_test docs

# 3. 创建 .gitignore
echo "==> 创建 .gitignore..."
cat > .gitignore << 'GITIGNORE'
.dart_tool/
.packages
build/
flutter_*.png
.pub-cache/
.pub/
.idea/
.vscode/
*.iml
.DS_Store
.env
.env.local
coverage/
*.lcov
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/DerivedData/
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/xcuserdata
**/ios/Flutter/ephemeral/
**/macos/Flutter/ephemeral/
**/windows/flutter/generated_*
**/linux/flutter/generated_*
GITIGNORE

# 4. 创建空文件占位
echo "==> 创建占位文件..."
touch lib/main.dart
touch lib/core/{browser_api,tab_manager,bookmark_service,download_service,settings_service,env}.dart
touch lib/platforms/engine_factory.dart
touch lib/features/{adblock,script,download,reader,sync,ai_chat,ai_tab,ai_writer,ai_agent,skills,subscription}/.gitkeep

# 5. 创建 GitHub 模板文件
echo "==> 创建 GitHub 模板..."
cat > .github/PULL_REQUEST_TEMPLATE.md << 'PR'
## 变更内容

## 关联 Issue

## 测试
- [ ] 单元测试通过
- [ ] 手动测试通过
- [ ] CI 通过
PR

cat > .github/CODEOWNERS << 'CO'
* @你的用户名
CO

# 6. 创建 analysis_options.yaml
echo "==> 创建分析配置..."
cat > analysis_options.yaml << 'ANALYSIS'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print
    - prefer_single_quotes
    - prefer_const_constructors
    - prefer_final_locals

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
ANALYSIS

# 7. 提交初始文件
echo "==> 提交初始文件..."
git add .
git commit -m "chore: initial project structure"
git push origin main

echo "==> 完成！"
echo ""
echo "下一步："
echo "1. 复制 BROWSER_FULL_PLAN.md 到本目录"
echo "2. 在 GitHub Settings → Secrets 中配置签名密钥"
echo "3. 配置分支保护规则"
echo "4. 创建第一个功能分支：git checkout -b feat/initial-setup"
```

---

## 七、推荐的工作流

### 7.1 日常开发

```bash
# 1. 同步主分支
git checkout main
git pull origin main

# 2. 创建功能分支
git checkout -b feat/smart-tab-grouping

# 3. 开发并提交
git add .
git commit -m "feat(tab): add AI-powered tab grouping"

# 4. 推送并创建 PR
git push -u origin feat/smart-tab-grouping
# 在 GitHub 上创建 Pull Request
```

### 7.2 发布新版本

```bash
# 1. 确保主分支干净
git checkout main
git pull origin main

# 2. 更新版本号（编辑 pubspec.yaml）
# version: 1.0.0+1

# 3. 更新 CHANGELOG.md
# 添加新版本条目

# 4. 提交版本变更
git add pubspec.yaml CHANGELOG.md
git commit -m "chore(release): bump version to v1.0.0"
git push origin main

# 5. 打 tag 触发构建
git tag v1.0.0
git push origin v1.0.0

# 6. GitHub Actions 自动：
#    - 五平台并行构建
#    - 签名 + 打包
#    - 创建 GitHub Release
#    - 上传安装包
```

---

## 八、检查清单

创建仓库后，逐一完成以下配置：

- [ ] 仓库创建（Public / Private）
- [ ] `.gitignore` 配置
- [ ] 目录结构初始化
- [ ] `pubspec.yaml` 基础依赖
- [ ] `analysis_options.yaml` 代码规范
- [ ] `.github/workflows/` 所有工作流文件
- [ ] `.github/ISSUE_TEMPLATE/` Issue 模板
- [ ] `.github/PULL_REQUEST_TEMPLATE.md`
- [ ] `.github/CODEOWNERS`
- [ ] `.github/dependabot.yml`
- [ ] `.github/FUNDING.yml`（可选）
- [ ] GitHub Secrets 配置（签名密钥）
- [ ] 分支保护规则（main + develop）
- [ ] README.md 编写
- [ ] LICENSE 选择（MIT / GPL / 其他）
- [ ] CHANGELOG.md 初始化
- [ ] 第一次 push 验证 CI 通过
