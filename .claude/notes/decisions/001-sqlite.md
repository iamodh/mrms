# ADR-002: SQLite 선택

## 상태

채택됨

## 맥락

1,000명 규모 마라톤 신청 시스템의 데이터베이스를 선택해야 한다.

## 결정

**SQLite**를 개발 및 프로덕션 데이터베이스로 사용한다.

## 이유

- **트래픽 패턴:** 며칠에 걸쳐 신청이 분산됨 (밀리초 단위 선착순 경쟁이 아님)
- **쓰기 성능:** 단일 쓰기가 수 밀리초면 완료
- **운영 복잡도:** DB 서버 없음 → 배포/백업/유지보수가 단순함
- **Rails 8 기본:** WAL 모드 + IMMEDIATE 트랜잭션이 기본 적용되어 동시성 문제 자동 처리

> `course.lock!` 같은 코드가 PostgreSQL과 다르게 동작하지만(row lock → DB lock), 이 규모에서는 차이가 체감되지 않음.

## PostgreSQL 전환 시점

다음 조건 중 하나라도 해당하면 전환 검토:

- 동시 수백 명의 밀리초 단위 선착순 경쟁
- 수평 확장(다중 서버) 필요
- 복잡한 분석 쿼리 실시간 실행

## 전환 체크리스트

1. 로컬에 PostgreSQL 설치 및 DB 생성
2. database.yml 수정 (development → PostgreSQL)
3. rails db:migrate 실행
4. 기존 시드 데이터 재생성
5. 전체 테스트 실행 (특히 동시성 테스트)

## 호환성 가이드

SQLite 특화 문법에 의존하지 않도록 PostgreSQL 호환성을 고려해서 작성:

- boolean: SQLite는 0/1이지만 Rails가 추상화함
- datetime/JSON: PostgreSQL 표준 형식 사용
- 제약조건/인덱스: PostgreSQL 호환 문법 우선
