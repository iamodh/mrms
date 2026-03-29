# ADR-001: id + Unique Index (복합 PK 대신)

## 상태

채택됨

## 맥락

중복 신청 방지를 위해 (race_id, name, phone_number) 조합의 유일성을 보장해야 한다. 두 가지 선택지가 있었다:

1. 복합 PK (race_id, name, phone_number)
2. 단일 id PK + Unique Index

## 결정

**단일 id PK + Unique Index** 방식을 선택한다.

## 이유

- Rails 생태계에서 단일 id PK가 컨벤션이며, 복합 PK는 라우팅/association/유지보수에 마찰을 만든다
- Unique Index는 동시 요청에서도 DB가 최종적으로 중복을 차단한다
- Rails의 `has_many`, `belongs_to`, URL 라우팅 등이 모두 단일 PK를 전제로 설계되어 있다
