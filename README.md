# QuestMap Gamepad

포에버의 기본 게임패드 UI와 함께 사용하는 가벼운 퀘스트 지도 애드온을 개발합니다.
An independent quest-map addon for WoW Forever, designed around the native gamepad UI.

**개발 초기 단계 / pre-alpha:** 현재는 설정 저장과 핀 필터 코어만 구현했습니다. 지도 핀 렌더링, 퀘스트 데이터, 설정창, 패드 탐색은 아직 구현되지 않았습니다. 설치해도 퀘스트 위치가 표시되지 않습니다. 게임 내 호환성 검증 및 CurseForge 출시는 아직 진행하지 않았습니다.

## 목표

- 월드맵과 미니맵에 시작(!), 목표, 완료(?) 위치 표시.
- 다른 지역을 열어도 해당 지역 표시, 대륙 지도에서 겹치는 핀 묶기.
- 지도에서 체크로 표시 종류 변경; 월드맵/미니맵 설정 개별 저장.
- 핀 툴팁, 저레벨/반복 퀘스트 필터와 크기 설정.
- 패드로 설정창 열기, 항목 이동, 체크, 크기 변경, 닫기.
- 기본 대화·추적창·아이템 사용은 게임 UI가 담당.

자동 수락/완료, NPC 툴팁 재작성, 자체 추적창, 이름표, 파티 통신, 광고는 제공하지 않습니다.

## 개발

```sh
python -m pip install -r requirements-dev.txt
python -m unittest discover -s tests -v
```

개발용 애드온 폴더는 `addon/QuestMapGamepad`입니다. 대상 TOC Interface는 설치된 Forever beta에서 확인한 `16001`이며 향후 클라이언트 변경에 따라 검증이 필요합니다. `/qmg`는 현재 개발 상태를 출력합니다.

## 라이선스와 후원

이 저장소의 직접 작성한 코드는 MIT입니다. Questie나 Forever Quest Pins의 소스, 아이콘, 데이터베이스는 포함하지 않습니다. 향후 외부 데이터는 적용 라이선스와 출처를 확인한 뒤 고지를 보존해 추가합니다. 참고한 기존 프로젝트를 자체 제작물로 표시하지 않습니다.

모든 기능은 무료로 제공할 계획입니다. 외부 프로젝트 페이지에서 자발적 후원을 받을 수 있도록 준비하되, 현재 후원 링크는 설정하지 않았습니다. 게임 안에는 후원 요청을 넣지 않습니다.

[로드맵](docs/ROADMAP.md) · [기여 안내](CONTRIBUTING.md) · [외부 자료](THIRD_PARTY_NOTICES.md)
