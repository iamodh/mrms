# MRMS (Marathon Registration Management System) TECHSPEC

## 1. 구현

### 1.1 신청자 기능

- 마라톤 대회 신청 (이름, 생년월일, 주소, 휴대폰 번호, 코스 선택)
- 신청 완료 시 고유 코드 발급
  - 형식: 영문 대문자 + 숫자 포함 8자리 (예: "A1B2C3D4")
  - 유니크 보장: DB unique index
  - 재발급 미지원 (이름 + 전화번호로 조회 시 코드 표시로 대체)
- 신청 내역 조회 (고유 코드 + 이름)
- 취소/환불 (신청 마감 기간 전에만 가능, 자동 처리)
- 신청 정보 수정 미지원 (잘못 입력 시 취소 후 재신청으로 안내)

### 1.2 관리자 기능

- 관리자 인증
- 대회 정보 설정 (대회명, 일시, 장소 등)
  - Race 레코드를 시드(seed)로 1개만 생성
  - 관리자 UI에서 대회 추가/삭제 기능은 제공하지 않음
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
- 엑셀 다운로드

### 1.3 데이터 무결성

- 중복 신청 방지
  - DB Unique Index: (race_id, name, phone_number)
  - name/phone_number 정규화 (저장 전 처리)
    - name: 모든 공백 제거 ("홍 길 동" → "홍길동"), 최대 10글자
    - address: 최대 30글자
    - phone: 숫자만 추출 ("010-1234-5678" → "01012345678"), 최대 11자리
- 정원 초과 신청 방지 (동시성 대응)
  - DB 트랜잭션 + Row Lock 기반 설계
  - 정원 카운트 기준: `status = 'applied'`인 신청만 카운트 (canceled, refunded 제외)
  - Row Lock 방식 (기본 채택):
    1. 트랜잭션 시작
    2. Course 행 잠금 (FOR UPDATE)
    3. 현재 신청 수 확인 (applied 상태만)
    4. 정원 초과 시 실패 (명확한 사용자 메시지 반환)
    5. 정원 내 시 Registration 생성
    6. 커밋
- 마감 후 신청 차단
  - 마감 판정 규칙 (OR 조건): 다음 중 하나라도 해당하면 신청 불가
    1. 시간 마감 도래 (신청 마감일 경과)
    2. 코스 정원 초과 (applied 상태 신청 수 ≥ capacity)
- 취소 멱등성
  - 이미 canceled/refunded 상태면 성공 응답 반환 (에러 아님)
  - 취소 가능 여부는 서버에서 검증 (프론트엔드 버튼 숨김만으로 의존하지 않음)

### 1.4 에러 처리

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
- 추가 보안 검토 (2단계)

---

### 2.2 2단계 구현 항목

**기능**

- 신청 정보 수정 기능
- 수동 마감 기능 (관리자가 직접 신청 마감 처리)
- 관리자 대시보드 (신청 현황 요약, 코스별 차트, 최근 신청 목록)
- 다중 대회 지원 (Race 추가/삭제 UI)
- 결제 연동 (토스페이먼츠 등 PG사 연동)
- 날짜별 부분 환불 정책 (예: D-30 100%, D-14 50%, D-7 환불불가)
- SMS/카카오톡 메시지 발송 (대상자 필터링 후 발송)
- 카카오 소셜 로그인 (카카오톡 메시지 연동 시)

**보안**

- 관리자 로그인 시도 제한 (brute force 방지)
- 관리자 2FA
- 개인정보 암호화 저장 (전화번호, 주소 등)
- Rate Limiting (신청 폭주 시 서버 보호)
- 조회 API 보안 강화 (시도 제한, 실패 시 구체적 에러 미노출, 이상 패턴 탐지)
- RAILS_MASTER_KEY + credentials 방식 (민감 정보 암호화 관리)

**DB/기술**

- 실시간 폴링 (코스별 잔여 인원 자동 갱신, 폴링 주기/캐싱 전략)
- remaining_slots 패턴 검토 (정원 관리 최적화)
- registrations_count counter cache 적용 (조회 성능 최적화)
- PostgreSQL + RDS 전환 (동시 수백 명 선착순 경쟁, 수평 확장 필요 시)

**현재 범위에서 제외**

- 다중 대회 관리 (범용 마라톤 플랫폼화)
- 다른 마라톤 대회 소개 및 정보 제공
- 참가자 커뮤니티 기능
- 마라톤 기록 관리 및 통계
- 훈련 프로그램 제공
- 참가자 간 소셜 기능

---

## 3. 작업 목록

### 3.1 기반

- 프로젝트 초기화 (Rails, RuboCop, 보안 gem, 환경변수)
- 데이터베이스 스키마 (Race, Course, Registration 테이블, 인덱스)
- 시드 데이터 (Race 1개, Course 4개)
- 모델 기본 설정 (Association, Validation, Fixture)

### 3.2 신청자 기능

- 신청 폼 (available 코스만 표시, 잔여 인원 표시)
- 입력 정규화 (이름 공백 제거, 전화번호 숫자만 추출)
- 신청 완료 & 고유 코드 발급
- 신청 내역 조회 (고유 코드 + 이름)
- 취소 처리

### 3.3 관리자 기능

- 관리자 인증 (환경변수 기반, 세션)
- 대회/코스 정보 조회
- 코스 정원 및 마감일 설정
- 신청자 목록 조회/정렬/필터링
- 엑셀 다운로드

### 3.4 데이터 무결성

- 정원 초과 방지 (Row Lock + 트랜잭션)
- 중복 신청 방지 (Unique Index + RecordNotUnique 처리)
- 마감 판정 (시간 마감 OR 정원 초과)
- 취소 멱등성

### 3.5 에러 처리 & UI

- 에러 메시지 (중복, 정원, 마감, 조회 실패, 서버 오류)
- 폼 상태 유지
- 네비게이션
- 에러 페이지 (404, 500)
- UI 스타일링

### 3.6 배포

- 첫 배포 (Hetzner + Kamal, HTTP)
- 도메인 + SSL (Let's Encrypt)
- 프로덕션 시드 데이터

---

## 4. 아키텍쳐

### 4.1 개발 환경

| 항목 | 기술 |
| ---- | ---- |
| OS | WSL2 Ubuntu |
| 에디터 | VS Code + WSL 플러그인 |
| Framework | Ruby on Rails 8.1.1 |
| Ruby | 3.4.7 |
| Database | SQLite |
| Testing | Minitest |
| Frontend | Hotwire (Turbo + Stimulus) |
| Deployment | Kamal + Docker |
| Linter | RuboCop |

### 4.2 애플리케이션 아키텍쳐

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
- Rails 컨벤션을 따르는 단순하고 명확한 구조
- 추가 패턴(Service Object 등) 없이 충분히 구현 가능

---

### 4.3 배포 아키텍쳐

**프로덕션 환경 (Hetzner Cloud)**

```
┌─────────────────────────────────────────────┐
│              Hetzner Cloud                  │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────┐        │
│  │        CX23 VPS (단일)          │        │
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
3. Hetzner VPS에서 이미지 pull 후 컨테이너 실행

**Kamal 배포 시 필수 환경변수**

| 환경변수          | 용도             |
| ----------------- | ---------------- |
| `SECRET_KEY_BASE` | 세션 암호화      |
| `ADMIN_ID`        | 관리자 로그인 ID |
| `ADMIN_PW`        | 관리자 로그인 PW |

---

### 4.4 단계별 인프라 계획

| 단계        | 구성                              | 비고                           |
| ----------- | --------------------------------- | ------------------------------ |
| 개발 (로컬) | WSL2 + SQLite                     | 빠른 개발                      |
| 1단계 완료  | Hetzner CX23 + SQLite + Kamal     | 핵심 기능 배포 (M9.5)          |
| 2단계       | + 도메인 + Let's Encrypt (자동)   | kamal-proxy가 SSL 자동 처리    |
| 선택        | + S3 호환 스토리지                | 엑셀 다운로드 파일 저장        |

## 5. 라우트 설계

### 5.1 신청자 영역

| HTTP   | Path                                    | Controller#Action      | 용도         |
| ------ | --------------------------------------- | ---------------------- | ------------ |
| GET    | `/`                                     | `home#show`            | 홈           |
| GET    | `/courses/:id/registrations/new`        | `registrations#new`    | 신청 폼      |
| POST   | `/courses/:id/registrations`            | `registrations#create` | 신청 생성    |
| GET    | `/courses/:id/registrations/:id`        | `registrations#show`   | 신청 완료    |
| GET    | `/lookup`                               | `lookup#new`           | 조회 폼      |
| POST   | `/lookup`                               | `lookup#create`        | 조회 처리    |
| DELETE | `/lookup`                               | `lookup#cancel`        | 취소 처리    |

### 5.2 관리자 영역

| HTTP   | Path                        | Controller#Action           | 용도           |
| ------ | --------------------------- | --------------------------- | -------------- |
| GET    | `/admin/login`              | `admin/sessions#new`        | 로그인 폼      |
| POST   | `/admin/login`              | `admin/sessions#create`     | 로그인 처리    |
| DELETE | `/admin/logout`             | `admin/sessions#destroy`    | 로그아웃       |
| GET    | `/admin`                    | `admin/dashboard#show`      | 대시보드       |
| GET    | `/admin/race/edit`          | `admin/races#edit`          | 마감일 수정 폼 |
| PATCH  | `/admin/race`               | `admin/races#update`        | 마감일 수정    |
| GET    | `/admin/courses/:id/edit`   | `admin/courses#edit`        | 코스 수정 폼   |
| PATCH  | `/admin/courses/:id`        | `admin/courses#update`      | 코스 수정      |
| GET    | `/admin/registrations`      | `admin/registrations#index` | 신청자 목록    |

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
| registrations | course_id                     | FK     | 코스별 신청 조회 |
| registrations | race_id                       | FK     | 대회별 신청 조회 |
| courses       | race_id                       | FK     | 대회별 코스 조회 |

### 관계도

```
Race 1 ──< Course
Race 1 ──< Registration
Course 1 ──< Registration
```

---

## 7. 핵심 구현 로직

### 7.1 데이터 정규화 (Registration)

```ruby
class Registration < ApplicationRecord
  normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
  normalizes :phone_number, with: ->(phone_number) { phone_number.gsub(/\D/, "") }
end
```

---

### 7.2 신청 생성 (정원 + 중복 방지)

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
rescue RegistrationClosedError, CapacityExceededError => e
  redirect_to new_registration_path, alert: e.message
rescue ActiveRecord::RecordNotUnique
  redirect_to new_registration_path, alert: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
end

private

def create_registration(course, params)
  Course.transaction do
    course.lock!

    raise RegistrationClosedError, "신청 기간이 종료되었습니다." if course.race.registration_closed?
    raise CapacityExceededError, "선택하신 코스의 정원이 마감되었습니다." if course.full?

    course.registrations.create!(params.merge(race: course.race, status: :applied))
  end
end
```

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

---

### 7.6 관리자 인증

**환경변수 설정:**

```bash
# 개발 (.env 파일, .gitignore에 추가)
ADMIN_ID=test_admin
ADMIN_PW=test_password

# 프로덕션 (Kamal secrets)
ADMIN_ID=real_admin
ADMIN_PW=실제_복잡한_비밀번호
```

**컨트롤러 역할:**

| 컨트롤러                    | 역할                               |
| --------------------------- | ---------------------------------- |
| `Admin::SessionsController` | 로그인/로그아웃 (출입증 발급/회수) |
| `Admin::BaseController`     | 관리자 페이지 보호 (출입증 검사)   |

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

---

### 7.7 신청자 목록 엑셀 다운로드

```ruby
# admin/registrations_controller.rb
def index
  # ... 기존 필터/정렬 로직 ...

  respond_to do |format|
    format.html
    format.xlsx { send_registrations_xlsx }
  end
end

private

def send_registrations_xlsx
  package = Axlsx::Package.new
  package.workbook.add_worksheet(name: "신청자목록") do |sheet|
    sheet.add_row %w[이름 생년월일 성별 전화번호 주소 코스 상태 확인코드 신청일]
    @registrations.each do |r|
      sheet.add_row [
        r.name, r.birth_date.to_s, r.gender_label,
        r.formatted_phone_number, r.address, r.course.name,
        r.status_label, r.confirmation_code,
        r.created_at.strftime("%Y-%m-%d %H:%M")
      ]
    end
  end
  send_data package.to_stream.read,
    filename: "신청자목록_#{Date.current.strftime('%Y%m%d')}.xlsx",
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
end
```

**엑셀 컬럼:**

| 컬럼 | 소스 |
|------|------|
| 이름 | `registration.name` |
| 생년월일 | `registration.birth_date` (YYYY-MM-DD) |
| 성별 | `registration.gender_label` (남/여) |
| 전화번호 | `registration.formatted_phone_number` (010-1234-5678) |
| 주소 | `registration.address` |
| 코스 | `registration.course.name` |
| 상태 | `registration.status_label` (신청/취소/환불) |
| 확인코드 | `registration.confirmation_code` |
| 신청일 | `registration.created_at` (YYYY-MM-DD HH:MM) |

**파일명:** `신청자목록_YYYYMMDD.xlsx` (현재 필터/정렬이 엑셀에도 동일 반영)

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
| 픽스처 데이터    | Fixtures                                        |

### 8.4 테스트 코드 예제

#### Associations

```ruby
test "has many courses" do
  race = races(:marathon_2026)
  assert_includes race.courses, courses(:five_km)
  assert_includes race.courses, courses(:ten_km)
end
```

#### Validations

```ruby
test "requires name" do
  race = Race.new(event_date: 1.month.from_now)
  assert_not race.valid?
  assert_includes race.errors[:name], "can't be blank"
end
```

#### Business Logic

```ruby
test "registration_closed? returns true when deadline has passed" do
  assert races(:closed_race).registration_closed?
end

test "full? returns true when capacity reached" do
  course = courses(:full_10km)
  assert course.full?
end
```
