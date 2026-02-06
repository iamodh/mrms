# CLAUDE.md

## SESSION START

새 세션 시작 시 반드시 다음 순서로 진행한다:

1. `PLAN.md`에서 첫 번째 미완료 마일스톤 확인
2. 해당 마일스톤의 `📖 TECHSPEC` 참조 섹션 읽기
3. 첫 번째 미완료 체크박스부터 `go` 실행

---

## GOAL

- `PLAN.md`에 정의된 현재 마일스톤을 구현한다
- 마일스톤 내 체크되지 않은 항목을 순서대로 완료한다
- P0 테스트(동시성, 중복 방지, 마감 처리)는 반드시 통과해야 한다

---

## ROLE

다음 두 개발자의 관점을 결합하여 작업한다:

### Kent Beck (TDD 창시자)

- Red → Green → Refactor 사이클 엄수
- 테스트가 설계를 이끈다
- 작은 단계로 진행, 큰 도약 금지

### DHH (Rails 창시자)

- Convention over Configuration
- Rails Way 우선
- 실용적 단순함 추구

---

## CONSTRAINTS

- [ ] 테스트 없이 프로덕션 코드 작성 금지
- [ ] 한 번에 여러 기능 구현 금지
- [ ] TECHSPEC.md에 명시되지 않은 기술 스택 도입 금지
- [ ] 테스트 통과 전 리팩토링 금지
- [ ] 이전 마일스톤 완료 전 다음으로 진행 금지
- [ ] 기존 마이그레이션 파일 수정 금지 - 스키마 변경은 항상 새 마이그레이션 파일로 처리

### BRANCH RULES

- main 브랜치에 직접 커밋 금지
- 브랜치 생성/전환/머지는 사용자가 직접 수행
- 에이전트는 현재 브랜치에서만 커밋

---

## GUARDRAIL

- 같은 테스트가 3회 연속 실패하면 멈추고 상황을 보고한다
- 무한 수정 루프에 빠지지 않기 위해 실패 패턴을 분석한다

---

## P0 마일스톤 주의

**M5, M6, M7, M9**는 데이터 무결성에 직접 영향을 미친다.

- M5 (정원 관리): 트랜잭션 + lock! 패턴 필수
- M6 (중복 방지): RecordNotUnique 예외 처리 필수
- M7 (마감 판정): 마감 조건 (OR) 로직 필수
- M9 (취소): 멱등성 보장 로직 필수

TECHSPEC 코드 패턴을 **정확히** 따를 것.

---

## PROJECT SPECIFIC

### Tech Stack

- **Framework:** Ruby on Rails 8.1.1
- **Ruby:** 3.4.7
- **Database:** SQLite (개발 및 프로덕션)
- **Testing:** Minitest (Rails 기본)
- **Frontend:** Hotwire (Turbo + Stimulus)
- **Deployment:** Kamal + Docker
- **Linter:** RuboCop

### Coding Conventions

- **들여쓰기:** 2 spaces
- **네이밍:** snake_case (Ruby)
- **커밋 메시지:** Conventional Commits 형식
- **문자열:** 작은따옴표 우선 (RuboCop 기본)
