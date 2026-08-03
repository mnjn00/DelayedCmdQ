<div align="center">

<img src="docs/images/icon.png" width="112" alt="Delayed Cmd+Q">

# Delayed Cmd+Q

**⌘Q를 잘못 눌렀다고 작업을 잃을 수는 없습니다.**

⌘Q를 톡 누르는 대신 꾹 누르고 있으세요. 누르는 동안 원이 시계 방향으로 채워지고,<br>
도중에 손을 떼면 아무 일도 일어나지 않습니다.

[![Platform](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/mnjn00/DelayedCmdQ?color=brightgreen)](https://github.com/mnjn00/DelayedCmdQ/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/mnjn00/DelayedCmdQ/total?color=orange)](https://github.com/mnjn00/DelayedCmdQ/releases)

[English](README.md) · **한국어** · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-dark.gif">
  <img src="docs/images/demo-light.gif" width="440" alt="⌘Q를 누르고 있는 동안 시계 방향으로 채워지는 원">
</picture>

</div>

---

## 왜 필요한가

⌘Q는 ⌘Tab 바로 아래, ⌘W에서 한 칸 옆에 있습니다. 실수로 누르는 순간 앱은 사라지고,
저장하지 않은 것도 함께 사라집니다.

Delayed Cmd+Q는 어떤 앱에도 도달하기 전에 이 단축키를 가로챕니다. 이제 종료하려면
의도적으로 누르고 있어야 하고, 원이 얼마나 더 버텨야 하는지 정확히 보여줍니다. 도중에
손을 떼면 키 입력은 그대로 폐기되며, 앱은 단축키가 눌렸다는 사실조차 알지 못합니다.

## 기능

- **눌러서 종료** — 직접 정한 시간만큼 ⌘Q를 누르고 있어야 종료됩니다
- **미니멀 HUD** — 12시 방향에서 시계 방향으로 채워지는 테두리만 있는 원
- **지연 시간 조절** — 0.3 ~ 5.0초, 설정 창에서 바로 미리 보기
- **연속 종료 선택** — 계속 눌러 다음 앱으로 이어가거나, 첫 앱에서 멈추거나
- **레이아웃 인식** — AZERTY, QWERTZ는 물론 한글·일본어 입력 중에도 정확하게 동작
- **방해하지 않음** — 메뉴 막대 전용, Dock 아이콘 없음, 언제든 일시 중지
- **다른 단축키는 그대로** — ⌘⇧Q(로그아웃)와 ⌘⌥Q는 가로채지 않습니다

<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/ring-dark.png">
  <img src="docs/images/ring-light.png" width="620" alt="0, 25, 50, 75, 100퍼센트 상태의 원">
</picture>
</div>

## 설치

### 다운로드

1. [최신 릴리스](https://github.com/mnjn00/DelayedCmdQ/releases/latest)에서 **`DelayedCmdQ.zip`** 을 받습니다.
2. 압축을 풀고 `DelayedCmdQ.app`을 `/Applications`로 옮깁니다.
3. 다운로드 격리 속성을 제거합니다:

```bash
xattr -dr com.apple.quarantine /Applications/DelayedCmdQ.app
```

> [!NOTE]
> 3번이 필요한 이유는 이 앱이 공증(notarize)이 아닌 ad-hoc 서명을 쓰기 때문입니다.
> 유료 Apple Developer 계정을 두고 있지 않습니다. 이 과정을 건너뛰면 macOS가 앱이
> 손상되었다고 알립니다. 명령어 실행이 꺼려진다면 [소스에서 빌드](#소스에서-빌드)해도
> 결과는 동일합니다.

### 소스에서 빌드

macOS 14 이상과 Xcode 26(Swift 6)이 필요합니다.

```bash
git clone https://github.com/mnjn00/DelayedCmdQ.git
cd DelayedCmdQ
./Scripts/build-app.sh
cp -R build/DelayedCmdQ.app /Applications/
```

`UNIVERSAL=1`을 붙이면 Intel + Apple Silicon 유니버설 바이너리로 빌드됩니다.

## 첫 실행

⌘Q를 가로채려면 **손쉬운 사용** 권한이 필요합니다.

1. 앱을 실행하면 권한을 요청하며 설정 창이 열립니다.
2. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**으로 이동합니다.
3. **Delayed Cmd+Q**를 켭니다.

권한을 허용하는 즉시 동작을 시작하며, 재실행할 필요는 없습니다. 앱은 메뉴 막대에만
있고 Dock 아이콘은 없습니다.

> [!IMPORTANT]
> 소스에서 다시 빌드하면 ad-hoc 서명이 바뀌어 macOS가 권한을 초기화합니다. 손쉬운 사용
> 목록에서 기존 항목을 `−`로 지우고 새 빌드를 추가하세요.

## 설정

메뉴 막대 아이콘에서 열거나 <kbd>⌘</kbd><kbd>,</kbd>를 누르세요.

| 항목 | 설명 | 기본값 |
| --- | --- | --- |
| **지연 시간** | ⌘Q를 눌러야 하는 시간 | `1.0초` |
| **연속 종료 허용** | 누르고 있는 동안 다음 앱도 이어서 종료 | 꺼짐 |
| **일시 중지** | ⌘Q를 원래 동작으로 되돌림 | 꺼짐 |
| **로그인 시 실행** | 로그인 항목으로 등록 | 꺼짐 |
| **앱 아이콘 표시** | 원 가운데에 종료될 앱의 아이콘 표시 | 켜짐 |

설정 창 위쪽의 원을 클릭하면 현재 지연 시간으로 미리 볼 수 있습니다.

### 연속 종료

**꺼짐**(기본값)이면 첫 앱이 종료된 뒤에는 아무리 오래 누르고 있어도 더 이상 아무 일도
일어나지 않습니다.

**켜짐**이면 포커스가 실제로 다른 앱으로 옮겨갈 때까지 기다렸다가, 그 앱을 대상으로 원을
처음부터 다시 채웁니다. 매번 끝까지 눌러야 종료되므로 한 번의 키 입력으로 여러 앱이
한꺼번에 사라지지는 않습니다. 3초 안에 포커스가 옮겨가지 않으면 — 예를 들어 저장 확인
대화상자가 뜬 경우 — 연쇄는 그대로 멈춥니다.

## 내부 구조

```
Sources/DelayedCmdQKit/
  App/         앱 델리게이트, 메뉴 막대, 메인 메뉴, 설정 창
  Core/        이벤트 탭, 홀드 상태 기계, 카운트다운, 권한, 키보드 레이아웃
  Overlay/     오버레이 패널과 진행 원 뷰
  Settings/    환경설정 모델과 설정 화면
```

동작의 핵심은 세 가지입니다.

- **`QuitKeyMonitor`** 는 세션 이벤트 탭에 `.defaultTap` 모드로 붙어 ⌘Q 키다운을 통째로
  버립니다. 최전면 앱은 단축키가 눌렸다는 사실 자체를 알지 못하며, 홀드가 끝나면
  `QuitCoordinator`가 명시적으로 종료를 요청합니다.
- **`QuitHoldMachine`** 은 홀드의 모든 상태 전이를 담은 순수 값 타입입니다. 이벤트가 아닌
  의미 단위 입력을 받으므로, 손쉬운 사용 권한이나 가짜 `CGEvent` 없이도 전체 수명주기를
  테스트할 수 있습니다.
- **`KeyboardLayout`** 은 `UCKeyTranslate`로 현재 ASCII 가능 레이아웃에서 Q의 키 코드를
  찾습니다. macOS가 커맨드 단축키에 쓰는 것과 같은 기준이라, Q가 QWERTY와 다른 위치에
  있는 환경에서도 정확합니다.

### 개발

```bash
swift build     # 컴파일
swift test      # 테스트 실행
```

이벤트 탭과 오버레이는 시스템 권한과 화면이 필요해 단위 테스트 대상이 아닙니다. 홀드 상태
기계, 단축키 매칭, 지연 시간 정책, 설정 저장은 모두 테스트로 덮여 있습니다.

## 땡스투

이 아이디어를 macOS에서 처음 선보인 [qblocker](https://github.com/steve228uk/qblocker)에서
영감을 받았습니다.

## 라이선스

[MIT](LICENSE) © mnjn00
