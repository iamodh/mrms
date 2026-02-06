# MRMS (Marathon Registration Management System) TECHSPEC

## 1. 구현

### 1.1 현재 상황에서 구현해야 할 것

#### 1단계: 핵심 기능

**신청자 기능**

- 마라톤 대회 신청 (이름, 생년월일, 주소, 휴대폰 번호, 코스 선택)
- 신청 완료 시 고유 코드 발급
  - 형식: 영문 대문자 + 숫자 포함 8자리 (예: "A1B2C3D4")
  - 유니크 보장: DB unique index
  - 재발급: 1단계 미지원 (이름 + 전화번호로 조회 시 코드 표시로 대체)
- 신청 내역 조회 (고유 코드 + 이름)
- 취소/환불 (신청 마감 기간 전에만 가능, 자동 처리)
  - 취소 가능 여부는 서버에서 검증 (프론트엔드 버튼 숨김만으로 의존하지 않음)
  - 멱등성 보장: 이미 canceled/refunded 상태면 성공 응답 반환 (에러 아님)
- 신청 정보 수정은 1단계에서 지원하지 않음 (잘못 입력 시 취소 후 재신청으로 안내)

**관리자 기능**

- 관리자 인증
  - 환경변수(ADMIN_ID, ADMIN_PW)와 비교 후 세션 기반 인증
  - HTTPS 필수 (Kamal + Traefik + Let's Encrypt)
  - 로그인 시도 제한은 2단계에서 검토
- 대회 정보 설정 (대회명, 일시, 장소 등)
  - 1단계에서는 Race 레코드를 시드(seed)로 1개만 생성
  - 관리자 UI에서 대회 추가/삭제 기능은 제공하지 않음
  - 다중 대회 지원은 2단계 범위
- 코스 설정 (5km, 10km, 하프, 풀코스 기본 존재, 미개설 코스는 capacity = 0)
  - capacity=0인 코스는 신청 폼에서 선택지로 표시하지 않음
- 코스별 정원 설정
- 신청 마감 설정 (신청 마감일)
- 신청자 목록 조회
- 신청자 목록 정렬 (기본: 최신 신청일 순, 이름 오름차순/내림차순)
- 신청자 목록 필터링
  - 코스별 필터
  - 상태별 필터 (전체 / 유효 신청(applied, 기본) / 취소(canceled) / 환불(refunded))
  - 인덱스 전략: 1,000명 규모에서 복합 인덱스는 필수 아님, 성능 이슈 발생 시 추가 검토

**데이터 무결성**

- 중복 신청 방지
  - DB Unique Index로 최종 보장: (race_id, name, phone_number) 조합
  - 복합 PK 대신 id + Unique Index 방식을 선택한 이유:
    - Rails 생태계에서 단일 id PK가 컨벤션이며, 복합 PK는 라우팅/association/유지보수에 마찰을 만든다
    - Unique Index는 동시 요청에서도 DB가 최종적으로 중복을 차단한다
  - name/phone_number 정규화 (저장 전 처리)
    - name: 모든 공백 제거 ("홍 길 동" → "홍길동")
    - phone: 숫자만 추출 ("010-1234-5678" → "01012345678")
    - 이유: "홍길동" vs "홍 길동", "010-1234-5678" vs "01012345678" 등 동일인 우회 방지
    - 적용 위치: 모델 콜백(before_validation)에서 일괄 처리
- 정원 초과 신청 방지 (동시성 대응)
  - 단순 count 체크가 아닌 DB 트랜잭션 기반 설계
  - 이유: Race Condition 방지 (동시 요청 시 정원 초과 INSERT 차단)
  - 정원 카운트 기준: `status = 'applied'`인 신청만 카운트 (canceled, refunded 제외)
  - Row Lock 방식 (기본 채택):
    1. 트랜잭션 시작
    2. Course 행 잠금 (FOR UPDATE)
    3. 현재 신청 수 확인 (applied 상태만)
    4. 정원 초과 시 실패 (명확한 사용자 메시지 반환)
    5. 정원 내 시 Registration 생성
    6. 커밋
  - (후반부 대안) remaining_slots 패턴
    - 원자적 UPDATE로 빠르지만, 취소/환불 시 정합성 관리가 더 필요함
    - MVP에는 row lock 방식이 구현/운영 리스크가 더 낮아 적합
- 마감 후 신청 차단
  - 마감 판정 규칙 (OR 조건): 다음 중 하나라도 해당하면 신청 불가
    1. 시간 마감 도래 (신청 마감일 경과)
    2. 코스 정원 초과 (applied 상태 신청 수 ≥ capacity)

**에러 처리**

- 사용자 친화적 에러 메시지 표시 (서버 에러 메시지 직접 노출 방지)

| 상황      | 사용자 메시지                                              | HTTP 상태 |
| --------- | ---------------------------------------------------------- | --------- |
| 중복 신청 | "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."    | 422       |
| 정원 초과 | "선택하신 코스의 정원이 마감되었습니다."                   | 422       |
| 시간 마감 | "신청 기간이 종료되었습니다."                              | 422       |
| 조회 실패 | "입력하신 정보와 일치하는 신청 내역이 없습니다."           | 404       |
| 서버 오류 | "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요." | 500       |

- 입력 검증 에러: 필드별 구체적 메시지 (예: "전화번호 형식이 올바르지 않습니다")
- 에러 페이지: 404, 500 커스텀 페이지
- 로깅: 서버 에러 로그 기록 (디버깅 및 모니터링용)
- 폼 상태 유지: 에러 발생 시 입력값 보존

#### 2단계: 후반부 추가 기능

**기능 관점**

- 관리자 대시보드 (신청 현황 요약, 코스별 차트, 최근 신청 목록)
- 수동 마감 기능 (관리자가 직접 신청 마감 처리)
- 신청 정보 수정 기능
- 다중 대회 지원 (Race 추가/삭제 UI)
- 결제 연동 (토스페이먼츠 등 PG사 연동)
- SMS/카카오톡 메시지 발송 기능
- 카카오 소셜 로그인 (카카오톡 메시지 연동 시)
- 신청자 목록 엑셀 다운로드
- 날짜별 부분 환불 정책 (예: D-30 100%, D-14 50%, D-7 환불불가)
- 관리자 로그인 시도 제한 (brute force 방지)
- 조회 API 보안 강화 (시도 제한, 실패 시 구체적 에러 미노출, 이상 패턴 탐지)

**DB/기술 관점**

- 실시간 폴링 (코스별 잔여 인원 자동 갱신)
  - 폴링 주기, 캐싱 전략, 부하 대비 설계
- remaining_slots 패턴 검토 (정원 관리 최적화)
- registrations_count counter cache 적용 (조회 성능 최적화)
- PostgreSQL + RDS 전환 (필요 시)
  - 전환 시점: 동시 수백 명의 밀리초 단위 선착순 경쟁, 수평 확장(다중 서버) 필요, 복잡한 분석 쿼리 실시간 실행
  - 현재 규모(1000명)에서는 SQLite로 충분

**보안 관점**

- 개인정보 암호화 저장 (전화번호, 주소 등)
- Rate Limiting (신청 폭주 시 서버 보호)
- 관리자 2FA
- 관리자 로그인 시도 제한 (brute force 방지)
- 조회 API 보안 강화 (시도 제한, 실패 시 구체적 에러 미노출, 이상 패턴 탐지)
- RAILS_MASTER_KEY + credentials 방식 (민감 정보 암호화 관리)

---

### 1.2 현재 상황에서 구현이 필요하지 않은 것

- 회원가입/로그인 시스템 (신청자는 비회원으로 신청)
- 다중 대회 관리 (단일 대회 전용 시스템)
- 관리자 권한 구분 (단일 관리자)
- 날짜별 부분 환불 정책 (2단계에서 구현)
- 다국어 지원
- 모바일 앱

---

## 2. 목적

### 2.1 이 웹 프로그램을 통해 이루고자 하는 목적

**기존 시스템의 문제 해결**

- **신뢰할 수 있는 신청 데이터 보장**
  - 중복 신청 방지 (DB Unique Index + 정규화)
  - 정원 초과 방지 (Row Lock 트랜잭션)
- 서버 오류 메시지 노출 → 사용자 친화적 메시지
- 메시지 오발송 → 대상자 필터링 후 발송 (2단계)

**사용자/관리자 경험 개선**

- 신청 현황 확인 (코스별 잔여 인원, 페이지 로드 시 1회 조회)
  - 실시간 폴링은 2단계에서 검토
  - 1단계 구현 시 폴링 추가가 용이하도록 잔여 인원 조회 로직을 별도 API로 분리
- 신청 내역 조회/취소 (고유 코드 + 이름, 수정은 2단계)
- 관리자 목록 조회/정렬/필터링
- 마감 관리 (수동 마감 + 정원 자동 마감)
- 날짜별 부분 환불 정책 (2단계)

**보안**

- Rails 기본 보안 기능 활용
  - **CSRF 방지**
    - 문제: 관리자가 로그인 상태에서 악성 사이트 방문 시, 악성 사이트가 관리자 권한으로 MRMS에 요청을 보낼 수 있음 (예: 신청 삭제)
    - 해결: Rails가 폼마다 고유 토큰 발급 → 요청 시 토큰 검증 → 토큰 없는 외부 요청 차단
  - **SQL Injection 방지**
    - 문제: 입력값에 악성 SQL 삽입 (예: `' OR '1'='1`) → 의도치 않은 데이터 조회/삭제
    - 해결: ActiveRecord가 모든 입력값 자동 이스케이프 → 특수문자가 SQL로 해석되지 않음
  - **XSS 방지**
    - 문제: 입력값에 악성 스크립트 삽입 (예: `<script>해킹코드</script>`) → 다른 사용자 브라우저에서 실행
    - 해결: 뷰 출력 시 자동 이스케이프 → `<script>`가 텍스트로 표시됨
  - **Mass Assignment 방지**
    - 문제: 폼에 허용되지 않은 필드 추가 (예: `admin=true`) → 권한 상승
    - 해결: Strong Parameters로 허용된 필드만 저장 → 나머지 무시
  - **세션 탈취 방지**
    - 문제: 쿠키 탈취 시 세션 정보 노출 (예: 관리자 여부)
    - 해결: Rails가 세션 데이터 암호화 저장 → 탈취해도 복호화 불가
- 추가 보안 검토 (2단계 보안 관점 참조)

---

### 2.2 이 웹 프로그램을 사용해도 현재는 이루지 않을 목적

**2단계에서 구현 예정**

- 대상자 필터링 메시지 발송 (SMS/카카오톡)
- 날짜별 부분 환불 정책
- 결제 연동 (토스페이먼츠)
- 카카오 소셜 로그인
- 엑셀 다운로드
- 추가 보안 (2단계 보안 관점 참조)

**현재 범위에서 제외**

- 다중 대회 관리 (범용 마라톤 플랫폼화)
- 다른 마라톤 대회 소개 및 정보 제공
- 참가자 커뮤니티 기능
- 마라톤 기록 관리 및 통계
- 훈련 프로그램 제공
- 참가자 간 소셜 기능

---

## 3. 현재 상태

### 3.1 현재 어느 정도까지 작업이 완료되었는가?

**현재 단계: 기획 완료**

- [x] 문제 정의 및 해결 방안 도출
- [x] 핵심 기능 범위 결정
- [x] 기술 스택 선정
- [x] TECHSPEC.md 작성
- [ ] PLAN.md 작성
- [ ] CLAUDE.md 작성
- [ ] Rails 프로젝트 생성
- [ ] 데이터베이스 설계
- [ ] 기능 구현

**개발 환경 준비 상태**

| 항목          | 상태                | 버전/내용              |
| ------------- | ------------------- | ---------------------- |
| OS            | ✅ 준비 완료        | WSL2 Ubuntu            |
| 에디터        | ✅ 준비 완료        | VS Code + WSL 플러그인 |
| Ruby          | ✅ 설치 완료        | 3.4.7                  |
| Rails         | ✅ 설치 완료        | 8.1.1                  |
| DB (개발)     | ⏳ 프로젝트 생성 시 | SQLite                 |
| DB (프로덕션) | 📋 예정             | SQLite                 |

---

### 3.2 다음은 어떤 작업이 필요한가?

**즉시 진행할 작업**

1. Rails 프로젝트 생성 (`rails new mrms`)
2. 데이터베이스 스키마 설계
3. 모델 생성 (Race, Course, Registration 등)
4. 관리자 인증 구현

**이후 순차 진행**

1. 관리자 기능 구현 (대회/코스 설정, 신청자 목록 조회/정렬/필터링)
2. 신청자 기능 구현 (신청, 조회, 취소) + 중복 검증 및 정원 관리 로직
3. 에러 처리 및 사용자 피드백
4. 잔여 인원 표시 (페이지 로드 시 1회 조회, 폴링 대비 API 분리)
5. UI/UX 개선
6. 프로덕션 배포

**2단계 (후반부)**

1. 결제 연동 (토스페이먼츠)
2. 메시지 발송 (SMS/카카오톡)
3. 카카오 소셜 로그인
4. 엑셀 다운로드
5. 날짜별 부분 환불 정책
6. 추가 보안 (2단계 보안 관점 참조)

---

## 4. 아키텍쳐

### 4.1 현재 적용한 아키텍쳐

**애플리케이션 아키텍쳐**

```
┌─────────────────────────────────────────────┐
│                Rails 8.1.1                  │
├─────────────────────────────────────────────┤
│  Controller (요청 처리)                      │
│      ↓                                      │
│  Model (비즈니스 로직, 데이터 검증)            │
│      ↓                                      │
│  View (ERB 템플릿 + Hotwire)                 │
└─────────────────────────────────────────────┘
```

- **패턴:** Rails 기본 MVC (Model-View-Controller)
- **프론트엔드:** Rails 기본 뷰 (ERB) + Hotwire (Turbo, Stimulus)
- **실시간 현황:** 주기적 폴링 (AJAX)

**사용 이유:**

- Rails 컨벤션을 따르는 단순하고 명확한 구조
- 단일 대회 관리 시스템에 적합한 규모
- 추가 패턴(Service Object 등) 없이 충분히 구현 가능

---

### 4.2 배포 아키텍쳐

**개발 환경**

```
┌─────────────────────────────────────────────┐
│            WSL2 Ubuntu (로컬)               │
├─────────────────────────────────────────────┤
│  VS Code + WSL 플러그인                      │
│  Ruby 3.4.7                                 │
│  Rails 8.1.1                                │
│  SQLite (개발 DB)                           │
└─────────────────────────────────────────────┘
```

**프로덕션 환경 (AWS)**

```
┌─────────────────────────────────────────────┐
│                   AWS                       │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────┐        │
│  │           EC2 (단일)             │        │
│  │  ┌─────────────────────────────┐│        │
│  │  │     Rails + SQLite          ││        │
│  │  │     (Kamal 배포)            ││        │
│  │  └─────────────────────────────┘│        │
│  └─────────────────────────────────┘        │
└─────────────────────────────────────────────┘
```

**배포 흐름 (Kamal)**

1. 로컬에서 Dockerfile로 이미지 빌드
2. Docker Hub에 이미지 푸시
3. EC2에서 이미지 pull 후 컨테이너 실행

**Kamal 배포 시 필수 환경변수**

| 환경변수          | 용도             |
| ----------------- | ---------------- |
| `SECRET_KEY_BASE` | 세션 암호화      |
| `ADMIN_ID`        | 관리자 로그인 ID |
| `ADMIN_PW`        | 관리자 로그인 PW |

---

### 4.3 단계별 인프라 계획

| 단계        | 구성                          | 비고                           |
| ----------- | ----------------------------- | ------------------------------ |
| 개발 (로컬) | WSL2 + SQLite                 | 빠른 개발                      |
| 1단계 완료  | EC2 + SQLite + Kamal          | 핵심 기능 배포                 |
| 2단계       | + S3                          | 엑셀 다운로드 파일 저장        |
| 선택        | + Route 53 + ACM + CloudWatch | 커스텀 도메인, HTTPS, 모니터링 |

**SQLite 선택 이유**

1,000명 규모 마라톤 신청 시스템에서 SQLite는 충분하다:

- **트래픽 패턴:** 며칠에 걸쳐 신청이 분산됨 (밀리초 단위 선착순 경쟁이 아님)
- **쓰기 성능:** 단일 쓰기가 수 밀리초면 완료
- **운영 복잡도:** DB 서버 없음 → 배포/백업/유지보수가 단순함
- **Rails 8 기본:** WAL 모드 + IMMEDIATE 트랜잭션이 기본 적용되어 동시성 문제 자동 처리

> **Rails 8의 SQLite 동시성 처리:** 읽기/쓰기 블로킹 최소화(WAL)와 트랜잭션 충돌 방지(IMMEDIATE)가 프레임워크 레벨에서 설정됨. `course.lock!` 같은 코드가 PostgreSQL과 다르게 동작하지만(row lock → DB lock), 이 규모에서는 차이가 체감되지 않음.

**PostgreSQL 전환이 필요한 시점**

다음 조건 중 하나라도 해당하면 전환 검토:

- 동시 수백 명의 밀리초 단위 선착순 경쟁
- 수평 확장(다중 서버) 필요
- 복잡한 분석 쿼리 실시간 실행

**전환 대비**

SQLite 특화 문법에 의존하지 않도록 PostgreSQL 호환성을 고려해서 작성:

- boolean: SQLite는 0/1이지만 Rails가 추상화함
- datetime/JSON: PostgreSQL 표준 형식 사용
- 제약조건/인덱스: PostgreSQL 호환 문법 우선

**전환 체크리스트**

1. 로컬에 PostgreSQL 설치 및 DB 생성
2. database.yml 수정 (development → PostgreSQL)
3. rails db:migrate 실행
4. 기존 시드 데이터 재생성
5. 전체 테스트 실행 (특히 동시성 테스트)

## 5. 라우트 설계

### 5.1 신청자 영역

| HTTP   | Path                             | Controller#Action      | 용도                |
| ------ | -------------------------------- | ---------------------- | ------------------- |
| GET    | `/`                              | `home#show`            | 홈                  |
| GET    | `/courses/:id/registrations/new` | `registrations#new`    | 신청 폼             |
| POST   | `/courses/:id/registrations`     | `registrations#create` | 신청 생성 → 완료 뷰 |
| GET    | `/lookup`                        | `lookup#new`           | 조회 폼             |
| POST   | `/lookup`                        | `lookup#create`        | 검증 → 상세 뷰      |
| DELETE | `/lookup`                        | `lookup#cancel`        | 취소 처리           |

**흐름:**

1. 홈(`/`)에서 대회 정보와 코스별 신청 링크, 조회 링크 표시
2. 코스 신청 링크 클릭 → 신청 폼(`/courses/:id/registrations/new`)
3. 폼 제출 → 신청 생성 후 완료 뷰 렌더링 (신청 코드 표시)
4. 조회 링크 클릭 → 조회 폼(`/lookup`)
5. 코드 + 이름 입력 → 검증 후 상세 뷰 렌더링
6. 취소 버튼 → DELETE 요청으로 취소 처리

---

### 5.2 관리자 영역

| HTTP   | Path                      | Controller#Action           | 용도           |
| ------ | ------------------------- | --------------------------- | -------------- |
| GET    | `/admin/login`            | `admin/sessions#new`        | 로그인 폼      |
| POST   | `/admin/login`            | `admin/sessions#create`     | 로그인 처리    |
| DELETE | `/admin/logout`           | `admin/sessions#destroy`    | 로그아웃       |
| GET    | `/admin`                  | `admin/registrations#index` | 신청자 목록    |
| GET    | `/admin/courses`          | `admin/courses#index`       | 코스 목록      |
| GET    | `/admin/courses/:id/edit` | `admin/courses#edit`        | 코스 수정 폼   |
| PATCH  | `/admin/courses/:id`      | `admin/courses#update`      | 코스 수정 저장 |

**흐름:**

1. 로그인(`/admin/login`) → 세션 생성 → 신청자 목록으로 리다이렉트
2. 신청자 목록(`/admin`)에서 정렬/필터링
3. 코스 설정 클릭 → 코스 목록(`/admin/courses`)
4. 코스 선택 → 수정 폼(`/admin/courses/:id/edit`) → 저장

---

### 5.3 routes.rb

```ruby
Rails.application.routes.draw do
  # 신청자
  root "home#show"

  resources :courses, only: [] do
    resources :registrations, only: [:new, :create]
  end

  get "lookup", to: "lookup#new"
  post "lookup", to: "lookup#create"
  delete "lookup", to: "lookup#cancel"

  # 관리자
  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    root "registrations#index"
    resources :registrations, only: [:index]
    resources :courses, only: [:index, :edit, :update]
  end
end
```

---

## 6. 데이터베이스 스키마

### 6.1 모델 구조

**Race (대회)**

| 컬럼                  | 타입     | 설명        |
| --------------------- | -------- | ----------- |
| id                    | integer  | PK          |
| name                  | string   | 대회명      |
| event_date            | datetime | 대회 일시   |
| location              | string   | 장소        |
| registration_deadline | datetime | 신청 마감일 |
| created_at            | datetime | 생성일      |
| updated_at            | datetime | 수정일      |

**Course (코스)**

| 컬럼       | 타입     | 설명                                |
| ---------- | -------- | ----------------------------------- |
| id         | integer  | PK                                  |
| race_id    | integer  | FK (Race)                           |
| name       | string   | 코스명 (5km / 10km / 하프 / 풀코스) |
| capacity   | integer  | 정원, 기본값: 0                     |
| fee        | integer  | 참가비 (원)                         |
| start_time | time     | 출발 시간                           |
| created_at | datetime | 생성일                              |
| updated_at | datetime | 수정일                              |

**Registration (신청)**

| 컬럼              | 타입     | 설명                                                  |
| ----------------- | -------- | ----------------------------------------------------- |
| id                | integer  | PK                                                    |
| race_id           | integer  | FK (Race)                                             |
| course_id         | integer  | FK (Course)                                           |
| name              | string   | 이름 (공백 제거 후 저장)                              |
| birth_date        | date     | 생년월일                                              |
| gender            | string   | 성별 (male / female)                                  |
| phone_number      | string   | 휴대폰 번호 (숫자만 저장)                             |
| address           | string   | 주소                                                  |
| confirmation_code | string   | 고유 코드 (영문 대문자 + 숫자 8자리)                  |
| status            | string   | 상태 (applied / canceled / refunded), 기본값: applied |
| canceled_at       | datetime | 취소 일시 (nullable)                                  |
| created_at        | datetime | 생성일                                                |
| updated_at        | datetime | 수정일                                                |

### 인덱스

| 테이블        | 컬럼                          | 타입   | 용도             |
| ------------- | ----------------------------- | ------ | ---------------- |
| registrations | [race_id, name, phone_number] | unique | 중복 신청 방지   |
| registrations | confirmation_code             | unique | 고유 코드 조회   |
| registrations | course_id                     | index  | 코스별 신청 조회 |
| courses       | race_id                       | index  | 대회별 코스 조회 |

### 관계도

```
Race 1 ──< Course
Race 1 ──< Registration
Course 1 ──< Registration
```

---

## 7. 핵심 구현 로직

### 7.1 데이터 정규화 (Registration)

저장 전 `before_validation` 콜백에서 처리:

```ruby
class Registration < ApplicationRecord
  before_validation :normalize_name, :normalize_phone_number

  private

  def normalize_name
    self.name = name.gsub(/\s+/, '') if name.present?
  end

  def normalize_phone_number
    self.phone_number = phone_number.gsub(/\D/, '') if phone_number.present?
  end
end
```

**이유:** "홍길동" vs "홍 길동", "010-1234-5678" vs "01012345678" 동일인 중복 신청 방지

---

### 7.2 신청 생성 (정원 + 중복 방지)

**방어 레이어:**

| 위협                  | 방어 수단             | 시점      |
| --------------------- | --------------------- | --------- |
| 정원 초과 (동시 신청) | Row Lock + count 체크 | INSERT 전 |
| 중복 신청 (같은 사람) | DB Unique Index       | INSERT 시 |

**Migration:**

```ruby
add_index :registrations, [:race_id, :name, :phone_number], unique: true
```

**Model:**

```ruby
class Registration < ApplicationRecord
  validates :name, uniqueness: {
    scope: [:race_id, :phone_number],
    message: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
  }
end
```

**Controller:**

```ruby
def create
  create_registration(@course, registration_params)
  redirect_to complete_path, notice: "신청이 완료되었습니다."
rescue CapacityExceededError => e
  redirect_to new_registration_path, alert: e.message
rescue ActiveRecord::RecordNotUnique
  redirect_to new_registration_path, alert: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
end

private

def create_registration(course, params)
  Course.transaction do
    course.lock!

    current_count = course.registrations.where(status: :applied).count
    if current_count >= course.capacity
      raise CapacityExceededError, "선택하신 코스의 정원이 마감되었습니다."
    end

    course.registrations.create!(params.merge(status: :applied))
  end
end
```

**실행 흐름:**

1. 트랜잭션 시작
2. Course 행 잠금 (`lock!` → FOR UPDATE)
3. applied 상태 신청 수 확인
4. 정원 초과? → CapacityExceededError, 롤백, 끝
5. 정원 OK → Registration INSERT 시도
6. DB unique index 검사 (INSERT 시점에 자동)
7. 중복? → RecordNotUnique, 롤백, 끝
8. 성공 → 커밋

---

### 7.3 마감 판정

```ruby
class Race < ApplicationRecord
  def registration_closed?
    registration_deadline.present? && Time.current > registration_deadline
  end
end

class Course < ApplicationRecord
  def full?
    registrations.where(status: :applied).count >= capacity
  end

  def available?
    !race.registration_closed? && !full?
  end
end
```

**마감 조건 (OR):**

- 시간 마감: `registration_deadline`이 존재하고 현재 시간 초과
- 정원 초과: `applied 수 >= capacity`

**신청 시 검증 흐름:**

```ruby
# RegistrationsController
def create
  course = Course.find(params[:course_id])

  unless course.available?
    message = if course.race.registration_closed?
                "신청 기간이 종료되었습니다."
              else
                "선택하신 코스의 정원이 마감되었습니다."
              end

    redirect_to new_registration_path, alert: message and return
  end

  # 정원 초과 방지 로직 (6.3) 진행...
end
```

**흐름:**

1. 마감 여부 먼저 체크 (트랜잭션 불필요)
2. 마감 시 사유별 메시지 반환
3. 통과 시 6.2 정원 + 중복 체크 (트랜잭션) 진행

---

### 7.4 고유 코드 생성

```ruby
class Registration < ApplicationRecord
  before_create :generate_confirmation_code

  private

  def generate_confirmation_code
    loop do
      self.confirmation_code = SecureRandom.alphanumeric(8).upcase
      break unless Registration.exists?(confirmation_code: confirmation_code)
    end
  end
end
```

**형식:** 영문 대문자 + 숫자 8자리 (예: "A1B2C3D4")

---

### 7.5 취소 처리 (멱등성 보장)

```ruby
class Registration < ApplicationRecord
  class NotCancelableError < StandardError; end

  enum :status, { applied: 'applied', canceled: 'canceled', refunded: 'refunded' }

  def cancelable?
    applied? && !race.registration_closed?
  end

  def cancel!
    # 멱등성: 이미 취소/환불 상태면 성공으로 처리
    return true if canceled? || refunded?

    # 취소 가능 여부 서버 검증
    raise NotCancelableError, "취소 가능 기간이 지났습니다." unless cancelable?

    update!(status: :canceled, canceled_at: Time.current)
  end
end
```

**취소 요청 흐름:**

```ruby
# RegistrationsController
def cancel
  registration = Registration.find_by!(confirmation_code: params[:code])

  registration.cancel!
  redirect_to registration_path(registration), notice: "신청이 취소되었습니다."
rescue ActiveRecord::RecordNotFound
  redirect_to lookup_registration_path, alert: "신청 내역을 찾을 수 없습니다."
rescue Registration::NotCancelableError => e
  redirect_to registration_path(registration), alert: e.message
end
```

**규칙:**

- 조회 페이지에서 취소 진행 → confirmation_code만으로 식별
- 이미 canceled/refunded 상태면 성공 응답 (에러 아님)
- 신청 마감일 이후에는 취소 불가
- 서버에서 취소 가능 여부 검증 (프론트엔드 버튼 숨김에만 의존하지 않음)
- `cancelable?` 메서드 분리로 뷰에서 재사용 가능
- `canceled_at`으로 취소 시점 기록 (2단계 환불 정책 대비)

---

### 7.6 관리자 인증

**환경변수 설정:**

```bash
# 개발 (.env 파일, .gitignore에 추가)
ADMIN_ID=test_admin
ADMIN_PW=test_password

# 프로덕션 (AWS 환경변수 또는 Kamal secrets)
ADMIN_ID=real_admin
ADMIN_PW=실제_복잡한_비밀번호
```

**컨트롤러 역할:**

| 컨트롤러                    | 역할                               |
| --------------------------- | ---------------------------------- |
| `Admin::SessionsController` | 로그인/로그아웃 (출입증 발급/회수) |
| `Admin::BaseController`     | 관리자 페이지 보호 (출입증 검사)   |

**동작 흐름:**

```
[로그인 전]
GET /admin/dashboard
    → require_admin에서 session[:admin] 확인
    → 없음 → 로그인 페이지로 리다이렉트

[로그인]
POST /admin/login (id, password)
    → ENV와 비교
    → 일치 → session[:admin] = true + 세션 쿠키 발급
    → 불일치 → flash.now[:alert] + render :new

[로그인 후]
GET /admin/dashboard
    → 브라우저가 세션 쿠키 자동 전송
    → 서버가 쿠키로 세션 복원
    → session[:admin] == true → 통과

[로그아웃]
DELETE /admin/logout
    → session.delete(:admin)
    → 로그인 페이지로 리다이렉트
```

**구현:**

```ruby
class Admin::SessionsController < ApplicationController
  def new
    # 로그인 폼 표시
  end

  def create
    if params[:id] == ENV['ADMIN_ID'] && params[:password] == ENV['ADMIN_PW']
      session[:admin] = true
      redirect_to admin_dashboard_path, notice: "로그인 성공"
    else
      flash.now[:alert] = "아이디 또는 비밀번호가 올바르지 않습니다."
      render :new
    end
  end

  def destroy
    session.delete(:admin)
    redirect_to admin_login_path, notice: "로그아웃 되었습니다."
  end
end

class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    unless session[:admin]
      redirect_to admin_login_path, alert: "관리자 로그인이 필요합니다."
    end
  end
end
```

**핵심 포인트:**

- 세션 쿠키: 서버가 `session[:admin] = true` 저장 → 브라우저가 쿠키로 보관 → 매 요청마다 자동 전송
- `Admin::BaseController` 상속: 모든 Admin 컨트롤러에 `require_admin` 자동 적용
- HTTPS 필수 (Kamal + Traefik + Let's Encrypt)

---

## 8. 테스트 전략

### 8.1 필수 검증 항목 (P0)

데이터 무결성과 동시성 관련 테스트. 실패 시 서비스 신뢰도에 직접 영향.

| 항목              | 시나리오                                 | 기대 결과               |
| ----------------- | ---------------------------------------- | ----------------------- |
| 마감 후 신청 차단 | 마감일 경과 후 신청 시도                 | 신청 거부 + 에러 메시지 |
| 정원 초과 방지    | 정원 1명 남은 상태, 2개 스레드 동시 신청 | 1건 성공, 1건 에러      |
| 중복 신청 방지    | 동일 정보로 동시에 2건 신청              | 1건만 성공, 1건 에러    |
| 마감 후 취소 차단 | 마감일 경과 후 취소 시도                 | 취소 거부 + 에러 메시지 |

### 8.2 추가 검증 항목 (P1)

경계값 및 일반 기능 테스트. 상세 케이스는 PLAN.md에서 정의.

| 항목                   | 시나리오                   | 기대 결과                  |
| ---------------------- | -------------------------- | -------------------------- |
| 정원 경계값            | 99/100명 상태에서 신청     | 100번째 성공, 101번째 실패 |
| 마감 경계값            | 마감 1초 전/후 신청        | 전: 성공, 후: 실패         |
| 취소 멱등성 (canceled) | 이미 취소된 신청 다시 취소 | 에러 없이 성공 응답        |
| 취소 멱등성 (refunded) | 환불 완료된 신청 취소 시도 | 에러 없이 성공 응답        |
| 이름 정규화            | "홍 길 동" 입력            | "홍길동"으로 저장          |
| 전화번호 정규화        | "010-1234-5678" 입력       | "01012345678"로 저장       |
| 고유 코드 형식         | 신청 완료 시               | 영문 대문자 + 숫자 8자리   |
| 고유 코드 유니크       | 대량 신청 시               | 모든 코드 중복 없음        |
| 관리자 로그인          | 올바른 ID/PW 입력          | 세션 생성 + 대시보드 이동  |
| 관리자 로그인 실패     | 잘못된 ID/PW 입력          | 에러 메시지 + 폼 유지      |
| 비인증 접근            | 로그인 없이 /admin 접근    | 로그인 페이지로 리다이렉트 |

### 8.3 테스트 도구

| 용도             | 도구                                            |
| ---------------- | ----------------------------------------------- |
| 단위/통합 테스트 | Minitest (Rails 기본)                           |
| 동시성 테스트    | `Thread` + `ActiveRecord::Base.connection_pool` |
| 픽스처 데이터    | Fixtures 또는 FactoryBot                        |
