# API Key Security - Design Document

**Date**: 2026-02-26
**Status**: Approved
**Approach**: `.gitignore` + `git rm --cached`

## Problem

Public GitHub repo (`zinisuni/aiadd`)에 민감한 API 키, 서비스 계정 Private Key, DB 비밀번호 등이 커밋되어 노출된 상태.

## Affected Files

### google-ocr 서브모듈 내 민감 파일

**`.env` 파일 (6개)**:
- `.env`, `.env.dev`, `.env.stg`, `.env.prod`, `.env.docker`, `.env.local`
- 포함 내용: Naver OCR Secret Key, OCR 암호화 키, JWT Secret, DB 비밀번호, Google Cloud Project ID

**Google 서비스 계정 키 JSON (4개)**:
- `src/main/resources/google-vision-key.json`
- `src/main/resources/google-vision-key-hspark.json`
- `src/main/resources/google-vision-key-zinsiuni.json`
- `src/main/resources/google-vision-key-arshelp.json`
- 포함 내용: GCP 서비스 계정 Private Key (전문)

**인증서/키스토어**:
- `src/main/resources/keystore/keystore.p12`

**환경별 설정 파일 (비밀번호 포함)**:
- `src/main/resources/env/dev/common.yml`
- `src/main/resources/env/stg/common.yml`
- `src/main/resources/env/docker/common.yml`
- `src/main/resources/env/local/common.yml`

### 유지할 파일
- `.env.example` - 비밀 값 없는 템플릿
- `src/main/resources/env/example/common.yml` - 예시 설정

## Solution

### Step 1. `google-ocr` 서브모듈 `.gitignore` 업데이트

추가할 패턴:
```gitignore
# 환경별 설정 파일 (민감 정보 포함)
.env
.env.*
!.env.example

# Google 서비스 계정 키
google-vision-key*.json
src/main/resources/google-vision-key*.json

# 키스토어
src/main/resources/keystore/keystore.p12

# 환경별 설정 (example 제외)
src/main/resources/env/dev/
src/main/resources/env/stg/
src/main/resources/env/docker/
src/main/resources/env/local/
```

### Step 2. `git rm --cached`로 추적 해제

서브모듈 디렉토리에서 대상 파일들의 Git 추적 해제. 로컬 파일은 유지됨.

### Step 3. `.env.example` 검증

기존 `.env.example`에 실제 비밀 값이 없는지 확인.

### Step 4. 키 교체 필요 목록

이미 노출된 키이므로 반드시 교체 필요:
- [ ] Google Cloud 서비스 계정 키 (모든 계정: hspark, zinsiuni, arshelp)
- [ ] Naver OCR Secret Key (`WlVscFdtZWFD...`, `VVV3Rm9mbFJJ...`)
- [ ] OCR 암호화 키 (`WZQKN6VJX0p8ToA7M5L2G3YNFTCYB4MQ`)
- [ ] OCR 복호화 파라미터 키
- [ ] OCR 통계 로그 키
- [ ] JWT Token Secret
- [ ] DB 비밀번호 (`gate21#$`)
- [ ] 테스트 페이지 비밀번호
- [ ] SSL 키스토어 (keystore.p12)

## Risk Notes

- Git 히스토리에는 키가 남아있음. 키 교체가 실질적 보안 대책.
- `git filter-repo`로 히스토리 정리는 별도 작업으로 가능하나, 키 교체가 우선.
