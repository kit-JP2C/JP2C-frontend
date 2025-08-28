# Flutter 프로젝트 환경 세팅 가이드 (Windows + VS Code)

이 문서는 Windows 환경에서 Flutter 개발 환경을 구축하면서 겪은 문제와 해결 과정을 정리한 문서입니다.  
Android Studio 설치를 최소화하고, 주로 **VS Code**를 이용하여 Flutter 개발을 진행하는 것을 목표로 합니다.

---

## 🚀 설치 과정

### 1. Git 설치
Flutter SDK는 내부적으로 Git을 사용합니다.
- [Git for Windows 다운로드](https://git-scm.com/download/win)  
- 설치 후 확인:
```powershell
git --version
```

### 2. Flutter SDK 설치
1. [Flutter SDK 다운로드](https://docs.flutter.dev/get-started/install/windows)  
2. 원하는 경로(예: `C:\src\flutter`)에 압축 해제  
3. 환경 변수 설정:
   - `C:\src\flutter\bin` 경로를 **PATH**에 추가  
   - CMD에서 확인:
     ```powershell
     flutter --version
     ```

---

## 🔍 문제 해결 기록

### ⚠️ 문제 1: `'WHERE'은 내부 또는 외부 명령이 아닙니다`
- 원인: `C:\Windows\System32`가 PATH에서 빠져 있었음  
- 해결: 환경 변수에 `C:\Windows\System32` 추가

### ⚠️ 문제 2: `Unable to find git in your PATH`
- 원인: Git 미설치 혹은 PATH 미등록  
- 해결: Git 설치 후 PATH에 자동 등록됨

### ⚠️ 문제 3: Dart SDK is not configured (Android Studio)
- 원인: Flutter SDK 내의 Dart SDK 경로를 IDE가 인식하지 못함  
- 해결:
  - Android Studio → `File > Settings > Languages & Frameworks > Dart`  
  - SDK 경로: `C:\src\flutter\bin\cache\dart-sdk` 지정  
  - Flutter SDK 경로: `C:\src\flutter`

---

## 🛠 개발 환경
- Windows 10/11
- Flutter SDK (stable)
- Git for Windows
- VS Code (Flutter, Dart 확장 설치)
- Android Studio (필수 아님, 필요 시 SDK 설정용)

---

## 📂 .gitignore 주의사항
공개 저장소에서는 민감한 파일을 반드시 무시해야 합니다.  
`.gitignore`에 아래 항목을 추가했습니다:

```gitignore
# Flutter/Dart
.dart_tool/
.build/
.pub/
packages/
pubspec.lock

# IDE
.idea/
.vscode/

# OS
.DS_Store
Thumbs.db

# 보안 관련
*.jks
*.keystore
*.pem
*.p12
*.key
*.crt
*.env
```

---

## ▶️ 실행 방법

```powershell
flutter doctor        # 환경 점검
flutter create <프로젝트 이름> # 프로젝트 생성
cd <프로젝트 이름>
flutter run -d windows  # Windows 앱 실행
```

안드로이드 폰 연결 시:
```powershell
flutter devices        # 연결된 기기 확인
flutter run -d <device_id>
```

---

## 📌 정리
- 최소 설치 (Flutter SDK + Git + VS Code)로 Flutter 개발 가능  
- `flutter doctor`로 환경 점검 → 문제점 하나씩 해결  
- Android Studio는 필수는 아니지만 SDK 관리 시 유용  
- `.gitignore`를 꼭 세팅해 보안 및 빌드 파일 누락 방지
