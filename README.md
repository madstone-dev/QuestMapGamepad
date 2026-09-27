# QuestMap Gamepad

포에버의 기본 게임패드 UI와 함께 사용하는 가벼운 퀘스트 지도 애드온입니다.
An independent quest-map addon for WoW Forever, designed around the native gamepad UI.

**0.2.0 기능 구현판 / functional preview:** 지도·미니맵 표시와 패드 설정창을 구현했습니다. 자동 테스트는 통과했으며 **실제 게임의 패드 입력·차단 팝업 검증은 아직 남아 있습니다.** 안정판 또는 CurseForge 출시 완료를 의미하지 않습니다.

## 기능

- 월드맵과 미니맵에 시작(!), 목표, 완료(?) 위치 표시.
- 다른 지역과 대륙·전체 지도에 위치 변환, 겹치는 핀 묶기.
- 같은 위치에 서로 다른 종류가 겹치면 `+`로 표시하고 툴팁·핀 목록에서 모두 확인.
- 지도에서 체크로 표시 종류 변경; 월드맵/미니맵 설정 개별 저장.
- 핀 툴팁, 저레벨/반복 퀘스트 필터와 크기 설정.
- 패드 커서/사용자가 지정한 단축키로 설정창 열기, 방향키·왼쪽 스틱 탐색, 체크, 크기 변경, 닫기.
- 설정창에서 퀘스트 핀 목록을 넘기며 목표 진행도와 좌표 읽기.
- 기본 대화·추적창·아이템 사용은 게임 UI가 담당.

자동 수락/완료, NPC 툴팁 재작성, 자체 추적창, 이름표, 파티 통신, 광고는 제공하지 않습니다.

## 설치와 조작

1. [Releases](https://github.com/madstone-dev/QuestMapGamepad/releases)에서 설치 ZIP을 받습니다. GitHub 자동 Source code ZIP은 설치 패키지가 아닙니다.
2. ZIP의 `QuestMapGamepad` 폴더를 WoW Forever의 `Interface/AddOns` 아래에 넣고 게임을 다시 시작합니다.
3. 처음에는 다른 퀘스트 애드온을 끄고 QuestMap Gamepad만 켜서 확인합니다.
4. 지도·미니맵의 **Q** 버튼 또는 `/qmg`로 설정을 엽니다. 체크는 이 애드온의 핀에만 적용됩니다.

패드는 기본 커서 모드로 Q를 누르거나, 게임의 단축키 설정에서 **QuestMap Gamepad → 퀘스트 핀 설정**에 원하는 버튼 조합을 지정합니다. 기존 버튼 배정은 변경하지 않습니다. 설정창 안에서는 방향키/왼쪽 스틱으로 이동, PAD1(남쪽 버튼)로 확인, PAD2(동쪽 버튼)로 닫습니다. 확인/취소 교환 옵션이 있습니다. 핀 크기는 좌우 입력으로 바꿉니다. 전투·NPC 대화가 시작되면 설정창이 닫힙니다.

`/qmg status`: 버전·좌표 누락 개수 · `/qmg log`: 최근 차단 진단 · `/qmg refresh`: 표시 갱신.

## 데이터 범위

시작 위치는 MIT로 제공되는 ATT 파생 데이터 **3,983개 퀘스트**를 포함합니다. 목표·완료 보고 위치는 게임 API가 제공하는 POI/다음 위치를 사용합니다. **모든 몬스터의 개별 출현 위치를 포함한 전체 Questie DB는 아닙니다.** 게임이 좌표를 제공하지 않는 퀘스트는 위치를 추측하지 않고 진단의 `missingActive`에 집계합니다.

직업·종족·레벨·선행·대체 퀘스트 조건을 적용합니다. 모든 평판/아이템/이벤트/서버 단계 조건을 알 수는 없어 일부 시작 표시는 실제 수락 가능 여부와 다를 수 있습니다. 기간·단계가 불명확한 이벤트 시작 표시는 보수적으로 제외합니다. 자세한 범위와 재현 순서는 [게임 내 확인 안내](docs/TESTING.md)에 있습니다.

## 개발

```sh
python -m pip install -r requirements-dev.txt
python -m unittest discover -s tests -v
python tools/package.py
```

애드온 폴더는 `addon/QuestMapGamepad`, 설치 ZIP은 `dist`에 생성됩니다. 대상 TOC Interface는 Forever beta의 `16001`입니다. beta API 변경에 따라 추가 검증이 필요합니다.

## 라이선스와 후원

직접 작성한 코드는 MIT입니다. ATT 파생 시작 데이터는 Forever Quest Pins에서 명시적으로 MIT로 분리 제공한 자료를 사용하며 원 고지와 출처를 보존합니다. Questie 및 Forever Quest Pins의 애드온 구현 코드는 포함하지 않습니다. [외부 자료 고지](THIRD_PARTY_NOTICES.md)를 확인하세요.

모든 기능은 무료입니다. 외부 프로젝트 페이지에서 자발적 후원을 받을 수 있으나 현재 후원 링크는 설정하지 않았습니다. 게임 안에는 후원 요청을 넣지 않습니다.

## English quick start

Install the release ZIP's `QuestMapGamepad` folder into `Interface/AddOns` and restart WoW Forever.
Open `/qmg` or click Q using your mouse/native controller cursor. An optional game key binding is also available.
Navigate with D-pad/left stick; PAD1 confirms, PAD2 closes (swappable). Settings are separate for each map surface.
This preview bundles MIT ATT-derived quest starts and reads native objective/turn-in POIs. It does not contain
every spawn location. Live client/gamepad/taint validation is pending; see [testing and limitations](docs/TESTING.md).

[로드맵](docs/ROADMAP.md) · [기여 안내](CONTRIBUTING.md) · [외부 자료](THIRD_PARTY_NOTICES.md)
