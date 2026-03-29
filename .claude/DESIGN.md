# MRMS Design System

> Claude Code는 스타일링 작업 시 이 문서를 참조한다.
> Tailwind CSS 클래스를 사용하며, 커스텀 CSS는 최소화한다.

---

## 톤 & 성격

- **밝고 에너지 넘치는** 러닝/마라톤 느낌
- 장식 최소화, 정보 전달 우선
- 한국어 가독성: 충분한 line-height, 넉넉한 패딩
- 공공 신청 서비스의 신뢰감 + 스포츠의 활기

---

## CSS 프레임워크

- **Tailwind CSS** (`tailwindcss-rails` gem)
- 커스텀 CSS 파일 작성 금지 — Tailwind 유틸리티 클래스만 사용
- 필요 시 `application.css`에서 Tailwind `@theme` 또는 `@layer`로 확장

---

## 색상 토큰

| 용도 | Hex | Tailwind 방식 | 사용처 |
|------|-----|--------------|--------|
| **Primary** | `#FF6900` | 커스텀 정의 필요 | 버튼, 링크, 강조 |
| **Primary Hover** | `#FF8C33` | | 버튼 호버 |
| **Primary Dark** | `#CC5400` | | 활성 탭, 진한 강조 |
| **Primary Light BG** | `#FFF3E6` | | 선택된 항목 배경, 알림 배경 |
| **Danger** | `#DC2626` | `red-600` | 에러 메시지, 취소 버튼 |
| **Danger Light BG** | `#FEF2F2` | `red-50` | 에러 알림 배경 |
| **Success** | `#16A34A` | `green-600` | 성공 메시지, 완료 상태 |
| **Success Light BG** | `#F0FDF4` | `green-50` | 성공 알림 배경 |
| **Background** | `#F9FAFB` | `gray-50` | 페이지 배경 |
| **Surface** | `#FFFFFF` | `white` | 카드, 폼 배경 |
| **Text Primary** | `#111827` | `gray-900` | 본문, 제목 |
| **Text Secondary** | `#6B7280` | `gray-500` | 보조 텍스트, placeholder |
| **Text Tertiary** | `#9CA3AF` | `gray-400` | 비활성 텍스트 |
| **Border** | `#E5E7EB` | `gray-200` | 입력 필드 테두리, 구분선 |
| **Border Hover** | `#D1D5DB` | `gray-300` | 호버 시 테두리 |

### Tailwind 커스텀 색상 설정

```css
/* app/assets/tailwind/application.css */
@theme {
  --color-primary: #FF6900;
  --color-primary-hover: #FF8C33;
  --color-primary-dark: #CC5400;
  --color-primary-light: #FFF3E6;
}
```

이렇게 하면 `bg-primary`, `text-primary-dark`, `hover:bg-primary-hover` 등으로 사용 가능.

---

## 타이포그래피

### 폰트

```html
<!-- app/views/layouts/application.html.erb <head> 안에 추가 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css" />
```

```css
/* Tailwind 설정 */
@theme {
  --font-sans: "Pretendard Variable", "Pretendard", -apple-system, BlinkMacSystemFont, system-ui, Roboto, sans-serif;
}
```

### 크기 & 행간

| 요소 | 크기 | 행간 | Tailwind 클래스 |
|------|------|------|----------------|
| 페이지 제목 (h1) | 24px | 1.3 | `text-2xl font-bold` |
| 섹션 제목 (h2) | 20px | 1.4 | `text-xl font-semibold` |
| 본문 | 16px | 1.7 | `text-base leading-relaxed` |
| 보조 텍스트 | 14px | 1.5 | `text-sm` |
| 에러 메시지 | 14px | 1.5 | `text-sm text-red-600` |

---

## 레이아웃

### 사용자 페이지 — 모바일 우선

```
max-w-lg mx-auto px-4 py-6
```

- `max-w-lg` (512px) — 폼 중심 페이지에 적합
- 모바일에서 전체 너비, 데스크탑에서 중앙 정렬
- 좌우 `px-4` (16px) 여백 확보

### 관리자 페이지 — 상단 네비게이션 바

```
max-w-5xl mx-auto px-4 py-6
```

- `max-w-5xl` (1024px) — 테이블 표시에 충분한 너비
- 상단에 네비게이션 바 (탭 형태)

### 관리자 네비게이션 바 구조

```erb
<%# app/views/layouts/admin.html.erb 또는 shared partial %>
<nav class="bg-white border-b border-gray-200">
  <div class="max-w-5xl mx-auto px-4">
    <div class="flex items-center justify-between h-14">
      <div class="flex items-center gap-1">
        <a href="/admin" class="px-3 py-2 text-sm font-medium rounded-md
          <%= current_page?(admin_root_path) ? 'bg-primary-light text-primary-dark' : 'text-gray-600 hover:text-gray-900' %>">
          대시보드
        </a>
        <a href="/admin/registrations" class="px-3 py-2 text-sm font-medium rounded-md ...">
          신청자 목록
        </a>
        <a href="/admin/courses" class="px-3 py-2 text-sm font-medium rounded-md ...">
          코스 설정
        </a>
      </div>
      <a href="/admin/logout" data-turbo-method="delete" class="text-sm text-gray-500 hover:text-gray-700">
        로그아웃
      </a>
    </div>
  </div>
</nav>
```

---

## 컴포넌트 패턴

### 버튼

```erb
<%# Primary 버튼 (신청, 저장 등 주요 액션) %>
<button class="w-full bg-primary hover:bg-primary-hover text-white font-medium
  py-3 px-6 rounded-lg transition-colors">
  참가 신청하기
</button>

<%# Secondary 버튼 (취소, 돌아가기 등 보조 액션) %>
<a class="text-gray-600 hover:text-gray-900 text-sm font-medium">
  돌아가기
</a>

<%# Danger 버튼 (신청 취소 등 파괴적 액션) %>
<button class="w-full bg-red-600 hover:bg-red-700 text-white font-medium
  py-3 px-6 rounded-lg transition-colors">
  신청 취소
</button>
```

- 모바일: `w-full` (전체 너비), `py-3` (터치 타겟 48px 이상)
- 버튼 사이 간격: `mt-3` 또는 `gap-3`

### 폼 필드

```erb
<%# Label %>
<label class="block text-sm font-medium text-gray-900 mb-1">
  이름 <span class="text-red-600">*</span>
</label>

<%# Input %>
<input type="text" class="w-full border border-gray-200 rounded-lg px-3 py-2.5
  text-base focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary
  placeholder:text-gray-400" />

<%# Select %>
<select class="w-full border border-gray-200 rounded-lg px-3 py-2.5
  text-base focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary">
  <option>코스를 선택하세요</option>
</select>

<%# 에러 메시지 %>
<p class="text-sm text-red-600 mt-1">이름을 입력해주세요.</p>
```

- 필드 간 간격: `space-y-4` 또는 `mb-4`
- 라벨은 항상 입력 필드 위에 배치
- `py-2.5` — 모바일 터치에 충분한 높이

### 카드

```erb
<%# 정보 카드 (완료 페이지, 조회 결과 등) %>
<div class="bg-white rounded-xl border border-gray-200 p-5">
  <h2 class="text-lg font-semibold text-gray-900 mb-3">신청 완료</h2>
  <dl class="space-y-2 text-sm">
    <div class="flex justify-between">
      <dt class="text-gray-500">확인 코드</dt>
      <dd class="font-mono font-semibold text-gray-900">AB12CD34</dd>
    </div>
  </dl>
</div>
```

### 테이블 (관리자 신청자 목록)

```erb
<div class="overflow-x-auto">
  <table class="w-full text-sm">
    <thead>
      <tr class="border-b border-gray-200">
        <th class="text-left py-3 px-3 font-semibold text-gray-900">이름</th>
        <th class="text-left py-3 px-3 font-semibold text-gray-900">코스</th>
        <th class="text-left py-3 px-3 font-semibold text-gray-900">상태</th>
        <th class="text-left py-3 px-3 font-semibold text-gray-900">확인코드</th>
        <th class="text-left py-3 px-3 font-semibold text-gray-900">신청일</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-b border-gray-100 hover:bg-gray-50">
        <td class="py-3 px-3">홍길동</td>
        <td class="py-3 px-3">풀코스</td>
        <td class="py-3 px-3">
          <span class="inline-block px-2 py-0.5 text-xs font-medium rounded-full
            bg-green-50 text-green-700">신청완료</span>
        </td>
        <td class="py-3 px-3 font-mono text-gray-900">AB12CD34</td>
        <td class="py-3 px-3 text-gray-500">2026-03-13</td>
      </tr>
    </tbody>
  </table>
</div>
```

### 상태 뱃지

| 상태 | 배경 | 텍스트 | 클래스 |
|------|------|--------|--------|
| applied (신청완료) | `bg-green-50` | `text-green-700` | `bg-green-50 text-green-700` |
| canceled (취소) | `bg-gray-100` | `text-gray-600` | `bg-gray-100 text-gray-600` |
| refunded (환불) | `bg-red-50` | `text-red-700` | `bg-red-50 text-red-700` |

### 필터/정렬 바 (관리자)

```erb
<div class="flex flex-wrap items-center gap-2 mb-4">
  <%# 코스 필터 %>
  <select class="border border-gray-200 rounded-lg px-3 py-2 text-sm">
    <option>전체 코스</option>
  </select>
  <%# 상태 필터 %>
  <select class="border border-gray-200 rounded-lg px-3 py-2 text-sm">
    <option>전체 상태</option>
  </select>
  <%# 정렬 %>
  <select class="border border-gray-200 rounded-lg px-3 py-2 text-sm">
    <option>신청일순</option>
    <option>이름순</option>
  </select>
</div>
```

### 플래시 메시지

```erb
<%# 성공 %>
<div class="bg-green-50 border border-green-200 text-green-800 rounded-lg px-4 py-3 text-sm">
  신청이 완료되었습니다.
</div>

<%# 에러 %>
<div class="bg-red-50 border border-red-200 text-red-800 rounded-lg px-4 py-3 text-sm">
  선택하신 코스의 정원이 마감되었습니다.
</div>
```

---

## 페이지별 가이드

### 사용자 — 홈 (/)

- 대회명 + 날짜를 크게 표시
- 코스 목록 카드 (잔여 인원 표시)
- "참가 신청" CTA 버튼 (Primary, 크게)
- "신청 조회" 링크 (보조)

### 사용자 — 신청 폼

- 한 컬럼 레이아웃, 위에서 아래로 순서대로 입력
- 코스 선택 → 개인정보 입력 → 제출
- 코스별 잔여 인원 실시간 표시
- 에러 시 스크롤 맨 위 + 에러 요약

### 사용자 — 완료 페이지

- 확인 코드를 크게 (font-mono, text-2xl)
- 신청 정보 요약 카드
- "신청 조회 페이지로" 링크

### 사용자 — 조회/취소

- 이름 → 확인 코드 순서로 입력 폼
- 조회 결과를 카드로 표시
- 취소 버튼은 Danger 스타일, 확인 dialog 포함

### 관리자 — 대시보드

- 대회 기본 정보 카드 (대회명, 마감일, 상태)
- 코스별 현황 요약 (정원 / 신청수 / 잔여)
- 빠른 링크: 신청자 목록, 코스 설정

### 관리자 — 신청자 목록

- 상단: 필터/정렬 바
- 중앙: 테이블 (반응형 overflow-x-auto)
- 짝수 행 배경색 없음 — hover:bg-gray-50으로 대체 (깔끔함)

### 관리자 — 코스/마감일 수정

- 폼 레이아웃은 사용자 폼과 동일한 패턴
- 저장 버튼: Primary 스타일

### 에러 페이지 (404, 500)

- 중앙 정렬, 큰 숫자 + 한국어 메시지
- "홈으로 돌아가기" 링크

---

## 하지 말 것

- ❌ 다크모드 (MVP에서 불필요)
- ❌ 커스텀 CSS 파일 추가 (Tailwind 유틸리티만 사용)
- ❌ JavaScript 애니메이션 (Tailwind transition 정도만)
- ❌ 아이콘 라이브러리 (텍스트와 이모지로 충분)
- ❌ 그라데이션, 그림자 남용 (border + 배경색으로 구분)
