# MyWay - 나만의 길, 나만의 그림

**당신의 발자취를 예술로 만드는 특별한 산책 기록 앱, MyWay입니다.**

MyWay는 단순한 산책 기록 앱을 넘어, 당신의 발자취를 예술로 만드는 특별한 경험을 제공합니다. Flutter로 개발된 이 앱을 통해 사용자는 자신의 산책 경로를 기록하고, 그 경로를 기반으로 세상에 하나뿐인 디지털 아트를 생성할 수 있습니다. 모든 산책이 당신만의 새로운 예술 작품이 됩니다.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

## 🌟 주요 기능 (Key Features)

-   **🎨 경로 아트 생성 (Path-to-Art)**
    -   기록된 산책 경로(동선)를 기반으로 아름다운 추상화 또는 라인 아트를 생성합니다.
    -   같은 길을 걸어도 매번 다른 스타일의 아트가 만들어져 새로운 즐거움을 선사합니다.

-   **🛰️ GPS 기반 산책 기록**
    -   실시간으로 사용자의 위치를 추적하여 거리, 시간, 걸음 수, 경로 등을 정확하게 기록합니다.
    -   산책 중 잠시 멈추거나 다시 시작하는 등 다양한 상황을 손쉽게 제어할 수 있습니다.

-   **🏞️ 공원 정보 및 추천 코스**
    -   사용자 주변의 공원을 찾아주고, 거리 및 상세 정보를 제공합니다.
    -   다양한 테마의 추천 산책 코스를 통해 새로운 산책 경험을 유도합니다.

-   **🖼️ 갤러리 및 활동 관리**
    -   과거의 산책 기록과 생성된 경로 아트를 갤러리 형태로 모아보고 관리할 수 있습니다.
    -   날짜, 장소별로 활동을 필터링하여 찾아볼 수 있습니다.

-   **❤️ 즐겨찾기 기능**
    -   마음에 드는 공원이나 코스를 '찜'하여 언제든지 쉽게 다시 찾아볼 수 있습니다.

## 💻 기술 스택 (Tech Stack)

-   **Framework**: `Flutter`
-   **State Management**: `Provider`
-   **Database**: `Firestore`
-   **Location & Maps**: `geolocator`, `google_maps_flutter`
-   **Authentication**: `Firebase Authentication`
-   **Storage**: `Firebase Storage`

## 📱 스크린샷 (Screenshots)

| 산책 시작 화면 | 실시간 기록 화면 |
| :----------: | :-----------: |
| ![Main Screen](./readme_assets/main_screen.png) | ![Tracking Screen](./readme_assets/tracking_screen.png) |
| **경로 아트 생성 결과** | **활동 기록 갤러리** |
| ![Art Result](./readme_assets/art_result.png) | ![History Gallery](./readme_assets/history_gallery.png) |

*(위 이미지는 예시입니다. 실제 프로젝트의 스크린샷으로 교체해주세요. `readme_assets` 폴더를 만들고 그 안에 이미지를 넣어 관리하면 좋습니다.)*

## 🚀 시작하기 (Getting Started)

프로젝트를 로컬 환경에서 실행하려면 아래의 단계를 따라주세요.

### 사전 준비

-   [Flutter SDK](https://flutter.dev/docs/get-started/install)가 설치되어 있어야 합니다.
-   [Firebase CLI](https://firebase.google.com/docs/cli)가 설치되어 있어야 합니다.

### 설치 및 실행

1.  **저장소 클론하기**
    ```bash
    git clone https://github.com/your-username/MyWay.git
    cd MyWay
    ```

2.  **Flutter 패키지 설치**
    ```bash
    flutter pub get
    ```

3.  **Firebase 프로젝트 설정**
    -   [Firebase Console](https://console.firebase.google.com/)에서 새로운 프로젝트를 생성합니다.
    -   Android 및 iOS 앱을 프로젝트에 추가합니다.
    -   **Cloud Firestore**와 **Firebase Storage**를 활성화합니다.
    -   아래 명령어를 실행하여 프로젝트를 Firebase에 연결하고, `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 파일을 자동으로 구성합니다.
        ```bash
        flutterfire configure
        ```

4.  **앱 실행**
    ```bash
    flutter run
    ```

## 🗺️ 앞으로의 계획 (Roadmap)

-   [ ] 경로 아트 스타일 추가 (수채화, 유화, 픽셀 아트 등)
-   [ ] 소셜 공유 기능 (생성된 아트를 SNS에 공유)
-   [ ] 친구와 함께 걷기 및 경로 공유
-   [ ] 산책 챌린지 및 배지 시스템 도입
-   [ ] 웨어러블 기기 연동 (Galaxy Watch, Apple Watch)

## 🤝 기여하기 (Contributing)

이 프로젝트에 기여하고 싶으시다면 언제든지 환영합니다! 이슈를 등록하거나 Pull Request를 보내주세요.

1.  프로젝트를 Fork 하세요.
2.  새로운 브랜치를 생성하세요.
    ```bash
    git checkout -b feature/AmazingFeature
    ```
3.  변경 사항을 커밋하세요.
    ```bash
    git commit -m 'Add some AmazingFeature'
    ```
4.  브랜치에 Push 하세요.
    ```bash
    git push origin feature/AmazingFeature
    ```
5.  Pull Request를 열어주세요.

## 📜 라이선스 (License)

이 프로젝트는 [MIT License](LICENSE)에 따라 라이선스가 부여됩니다.

---

**만든 사람:** [강보현, 김건, 김덕원, 김기은](https://github.com/APP-iOS7/MyWay-BDGG)
