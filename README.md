# MRMS(Marathon Registration and Management System)
마라톤 대회 참가 접수를 관리하는 Rails 기반 웹 시스템입니다.

## 기술 스택

  | 구분 | 기술 | 버전 |
  |------|------|------|
  | Framework | Ruby on Rails | 8.1.1 |
  | Language | Ruby | 3.4.7 |
  | Database | SQLite | - |
  | Testing | Minitest | Rails 기본 |
  | Frontend | Hotwire (Turbo + Stimulus) | - |
  | Deployment | Kamal + Docker | - |
  | Linter | RuboCop | - |

## AI Workflow
<img width="8192" height="2850" alt="Marathon Application-2026-02-11-063615" src="https://github.com/user-attachments/assets/04250713-7a55-45fc-81ea-ca8fc92a2a39" />

## 배포 아키텍쳐

<img width="725" height="818" alt="image" src="https://github.com/user-attachments/assets/4eb8d24d-e6e5-4789-8456-dc6678394671" />

## 요청 흐름 (사용자 → 서버 → 응답)

| 단계 | 위치 | 동작 |
|------|------|------|
| ① | 브라우저 → 서버 | 사용자가 `http://서버IP`로 접속. 서버의 80번 포트에 도착 |
| ② | Docker 포트 매핑 | 80번 포트가 kamal-proxy 컨테이너에 매핑되어 있으므로 요청 전달 |
| ③ | kamal-proxy → Rails | Docker 내부 네트워크를 통해 Rails 앱 컨테이너의 Puma로 라우팅 |
| ④ | Rails 앱 | 컨트롤러 → 모델 → SQLite 조회 → HTML 생성 |
| ⑤ | 역순 반환 | Rails → kamal-proxy → 브라우저에 HTML 응답 |

## 배포 흐름 (개발자 → 서버)

| 단계 | 동작 |
|------|------|
| 1 | WSL에서 `kamal deploy` 실행 |
| 2 | Docker 이미지 빌드 (Rails 코드 + Ruby + Gems 패키징) |
| 3 | Docker Hub에 이미지 push |
| 4 | Kamal이 SSH로 Hetzner 서버에 접속 |
| 5 | 서버에서 Docker Hub로부터 이미지 pull |
| 6 | 새 Rails 앱 컨테이너 실행 |
| 7 | kamal-proxy가 새 컨테이너로 연결 전환 (무중단) |
| 8 | 구 컨테이너 삭제 |

## 컨테이너 구성

### kamal-proxy (컨테이너 1)
- 외부 포트 80, 443이 매핑된 유일한 진입점
- Let's Encrypt SSL 자동 발급 처리
- 무중단 배포 시 v1 → v2 전환을 담당
- Kamal이 자동으로 설치하고 관리

### Rails 앱 (컨테이너 2)
- Puma 웹 서버 위에서 Rails 앱 실행
- 외부 포트 매핑 없음 (kamal-proxy를 통해서만 접근 가능)
- SQLite DB 파일은 Docker volume mount로 서버 디스크에 저장
- 배포 시 이 컨테이너만 새 버전으로 교체

## 포트 사용 현황

| 포트 | 서비스 | 위치 | 외부 접근 |
|------|--------|------|-----------|
| 22 | SSH | Docker 밖 (서버 OS) | O (개발자만) |
| 80 | HTTP | kamal-proxy 컨테이너 | O (사용자) |
| 443 | HTTPS | kamal-proxy 컨테이너 | O (사용자) |
| 3000 | Puma | Rails 앱 컨테이너 | X (내부 전용) |

## SQLite DB가 컨테이너 밖에 저장되는 이유

컨테이너는 배포할 때마다 삭제되고 새로 생성된다. DB 파일이 컨테이너 안에 있으면 배포할 때마다 데이터가 날아간다. Docker volume mount로 서버 디스크의 특정 경로를 컨테이너 안에 연결해두면, 컨테이너가 교체되어도 DB 파일은 서버 디스크에 그대로 남아있다.

```
서버 디스크: /data/mrms/db/production.sqlite3
                ↕ (volume mount)
컨테이너 내부: /rails/storage/production.sqlite3
```

컨테이너가 v1이든 v2든 같은 서버 디스크 경로를 바라보므로 데이터가 유지된다.
