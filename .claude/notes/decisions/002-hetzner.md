# ADR-003: Hetzner Cloud + Kamal 선택

## 상태

채택됨

## 맥락

SQLite 단일 서버 환경에서 배포 플랫폼을 선택해야 한다. 주요 후보는 AWS, Hetzner + Kamal, Vercel이었다.

## 결정

**Hetzner CX23 + Kamal**을 선택한다.

## 이유

### Hetzner vs AWS

| | AWS 프리티어 (t2.micro) | Hetzner CX23 (~$4.09/월) |
|---|---|---|
| vCPU | 1 | 2 |
| RAM | 1GB | 4GB |
| 디스크 | 30GB EBS (IOPS 제한) | 40GB NVMe SSD |
| 트래픽 | 15GB/월 (초과 시 과금) | 20TB/월 |
| 비용 | 1년 무료 → 이후 ~$8/월 | 처음부터 ~$4.09/월 |
| 설정 | VPC, 보안그룹, IAM 필요 | SSH 키만 등록하면 끝 |
| 한국 리전 | 있음 (서울) | 없음 (독일/핀란드/미국) |

- 같은 비용으로 RAM 4배, NVMe SSD — SQLite + Rails에 유리
- 트래픽 20TB — 사실상 무제한
- VPC/IAM 없이 SSH만으로 배포 가능
- 레이턴시 증가(한국 ↔ 독일 약 200~250ms)는 마라톤 신청 서비스 특성상 문제되지 않음

### Kamal vs Vercel

| 항목 | Kamal | Vercel |
|------|-------|--------|
| 월 비용 | VPS 고정 (~€5) | 트래픽/함수 호출 비례 |
| 배포 속도 | Docker 빌드+푸시+풀 (2~5분) | git push → 수십 초 |
| 스케일링 | 수동 | 자동 |
| 프레임워크 | Rails, Django 등 서버 앱에 최적 | Next.js에 최적 |
| 학습 가치 | Docker, 리눅스, 네트워크 전반 | 플랫폼 사용법만 |

Rails 서버 앱 + 비용 통제 + 인프라 학습 목적에 Kamal이 적합하다.
