# API Key Security Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove tracked sensitive files from the `google-ocr` submodule and prevent future accidental commits of secrets.

**Architecture:** Update `.gitignore` in the submodule to cover all sensitive file patterns, run `git rm --cached` to untrack files (preserving local copies), sanitize `.env.example` to remove real secrets, and commit changes in both the submodule and the parent repo.

**Tech Stack:** Git, .gitignore

---

### Task 1: Update submodule `.gitignore` with missing patterns

**Files:**
- Modify: `src/aiadd/ocr/google-ocr/.gitignore`

The existing `.gitignore` already has `google-vision-key*.json` and `.env` patterns, but is missing `.env.*` variants and environment-specific directories.

**Step 1: Add missing patterns to `.gitignore`**

Open `src/aiadd/ocr/google-ocr/.gitignore` and add the following block at the end:

```gitignore
### Sensitive environment files ###
.env.*
!.env.example

### Environment-specific config (secrets) ###
src/main/resources/env/dev/
src/main/resources/env/stg/
src/main/resources/env/docker/
src/main/resources/env/local/

### Keystore ###
src/main/resources/keystore/
```

**Step 2: Verify patterns are correct**

Run from inside the submodule directory (`src/aiadd/ocr/google-ocr/`):

```bash
cd src/aiadd/ocr/google-ocr && git status
```

Expected: The `.gitignore` file itself shows as modified. The previously tracked sensitive files will NOT yet disappear from tracking (they must be explicitly `git rm --cached`).

**Step 3: Commit the `.gitignore` update**

```bash
cd src/aiadd/ocr/google-ocr && git add .gitignore && git commit -m "chore: add sensitive file patterns to .gitignore"
```

---

### Task 2: Untrack sensitive `.env` files

**Files:**
- Untrack: `src/aiadd/ocr/google-ocr/.env.dev`
- Untrack: `src/aiadd/ocr/google-ocr/.env.docker`
- Untrack: `src/aiadd/ocr/google-ocr/.env.local`
- Untrack: `src/aiadd/ocr/google-ocr/.env.prod`
- Untrack: `src/aiadd/ocr/google-ocr/.env.stg`

**Step 1: Remove `.env.*` files from Git tracking (keep local)**

```bash
cd src/aiadd/ocr/google-ocr && git rm --cached .env.dev .env.docker .env.local .env.prod .env.stg
```

Expected output: 5 lines of `rm '.env.XXX'`

**Step 2: Verify files are untracked but still on disk**

```bash
cd src/aiadd/ocr/google-ocr && git status
```

Expected: The 5 files appear under "Changes to be committed" as `deleted:`. Running `ls .env.*` still shows all files on disk.

**Step 3: Commit**

```bash
cd src/aiadd/ocr/google-ocr && git commit -m "chore: untrack .env environment files with secrets"
```

---

### Task 3: Untrack environment-specific config directories

**Files:**
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/dev/common.yml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/dev/logback-spring.xml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/docker/common.yml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/docker/logback-spring.xml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/local/common.yml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/local/logback-spring.xml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/stg/common.yml`
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/env/stg/logback-spring.xml`

**Step 1: Remove tracked env config files from Git**

```bash
cd src/aiadd/ocr/google-ocr && git rm --cached -r src/main/resources/env/dev/ src/main/resources/env/docker/ src/main/resources/env/local/ src/main/resources/env/stg/
```

Expected output: 8 lines of `rm 'src/main/resources/env/...'`

**Step 2: Verify**

```bash
cd src/aiadd/ocr/google-ocr && git status
```

Expected: 8 files listed as `deleted:` under staged changes.

**Step 3: Commit**

```bash
cd src/aiadd/ocr/google-ocr && git commit -m "chore: untrack environment-specific config directories (contain passwords)"
```

---

### Task 4: Untrack keystore file

**Files:**
- Untrack: `src/aiadd/ocr/google-ocr/src/main/resources/keystore/keystore.p12`

**Step 1: Remove keystore from Git tracking**

```bash
cd src/aiadd/ocr/google-ocr && git rm --cached src/main/resources/keystore/keystore.p12
```

Expected: `rm 'src/main/resources/keystore/keystore.p12'`

**Step 2: Verify**

```bash
cd src/aiadd/ocr/google-ocr && git status
```

Expected: 1 file listed as `deleted:` under staged changes.

**Step 3: Commit**

```bash
cd src/aiadd/ocr/google-ocr && git commit -m "chore: untrack SSL keystore file"
```

---

### Task 5: Sanitize `.env.example`

The current `.env.example` contains REAL secrets (OCR keys, encryption keys, Naver secrets, passwords). It must be sanitized to contain only placeholder values.

**Files:**
- Modify: `src/aiadd/ocr/google-ocr/.env.example`

**Step 1: Replace `.env.example` with sanitized version**

Replace the entire contents of `src/aiadd/ocr/google-ocr/.env.example` with:

```env
# 로컬 개발 환경 설정 (.env.example)
# 이 파일을 .env.local로 복사한 후 실제 값을 입력하세요.

# Google Cloud 설정
GOOGLE_CLOUD_PROJECT_ID=your-gcp-project-id
GOOGLE_APPLICATION_CREDENTIALS=./google-credentials.json

# OCR 암호화 설정
OCR_ENCRYPT_KEY=your-ocr-encrypt-key
OCR_ENCRYPT_URL=http://localhost:55031/v1/web/receive

OCR_TO_KEYIN_URL=http://localhost:55031/v1/web/keyin

OCR_DECRYPT_PARAM_KEY=your-ocr-decrypt-param-key

# OCR 통계 로그
OCR_STATICS_LOG_URL=https://your-stats-endpoint/log
OCR_STATICS_LOG_KEY=your-ocr-statics-log-key

# 네이버 CLOVA OCR API 설정
NAVER_OCR_API_URL=https://your-naver-ocr-endpoint
NAVER_OCR_SECRET_KEY=your-naver-ocr-secret-key

# 카카오 OCR API 설정
KAKAO_OCR_API_URL=https://dapi.kakao.com/v2/vision/text/ocr
KAKAO_OCR_API_KEY=your-kakao-api-key

# 애플리케이션 설정
APP_UPLOAD_DIR=uploads

# 이미지 저장 설정 (0 : false , 1 : true)
SAVE_IMAGE=1

# 로깅 설정
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_EXAMPLE=DEBUG

# 플래그 설정
# LGU Receive Flag (ocr -> viewpay web), 0=false, 1=true
SEND_FRONT_RECIVE_FLAG=1
# ENV 전체 조회
ENV_ALL_GET=1
# 통계 적재 플래그 (sass 통계 적재 0=false, 1=true)
OCR_STATICS_USAGE=0

# 테스트 페이지 비밀번호
TEST_PAGE_PASSWORD="your-test-password"

# JWT 설정
JWT_TOKEN_SECRET=your-jwt-token-secret
JWT_TOKEN_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000
```

**Step 2: Verify no real secrets remain**

Scan for known secret patterns:

```bash
cd src/aiadd/ocr/google-ocr && grep -iE '(WlVscF|VVV3Rm|WZQKN6|kXp2s5|gate21|test123|77217A)' .env.example
```

Expected: No output (no matches).

**Step 3: Commit**

```bash
cd src/aiadd/ocr/google-ocr && git add .env.example && git commit -m "chore: sanitize .env.example - replace real secrets with placeholders"
```

---

### Task 6: Remove tracked card sample image and add to .gitignore

**Files:**
- Delete from Git: `src/aiadd/ocr/local-ai/credit_card_image.jpg`
- Modify: `src/aiadd/ocr/local-ai/.gitignore` (or create if not exists)

**Step 1: Add image patterns to local-ai .gitignore**

Create or append to `src/aiadd/ocr/local-ai/.gitignore`:

```gitignore
# Card sample images (sensitive)
*.jpg
*.jpeg
*.png
*.bmp
```

**Step 2: Remove card image from Git tracking**

```bash
cd /Users/hspark/Code/hspark/aiadd && git rm --cached src/aiadd/ocr/local-ai/credit_card_image.jpg
```

Expected: `rm 'src/aiadd/ocr/local-ai/credit_card_image.jpg'`

**Step 3: Commit in parent repo**

```bash
cd /Users/hspark/Code/hspark/aiadd && git add src/aiadd/ocr/local-ai/.gitignore && git commit -m "chore: remove tracked card sample image, add image gitignore"
```

---

### Task 7: Update parent repo submodule reference and commit

**Files:**
- Modify: parent repo's submodule reference for `src/aiadd/ocr/google-ocr`

**Step 1: Stage updated submodule reference in parent repo**

```bash
cd /Users/hspark/Code/hspark/aiadd && git add src/aiadd/ocr/google-ocr
```

**Step 2: Commit parent repo**

```bash
cd /Users/hspark/Code/hspark/aiadd && git commit -m "chore: update google-ocr submodule - remove tracked secrets"
```

**Step 3: Verify final state**

```bash
cd /Users/hspark/Code/hspark/aiadd/src/aiadd/ocr/google-ocr && git ls-files | grep -iE '(\.env\.|keystore|env/dev|env/stg|env/docker|env/local)'
```

Expected: Only `.env.example` and `src/main/resources/env/example/` files appear. No `.env.dev`, `.env.prod`, etc.

---

### Post-Implementation: Key Rotation Checklist

**WARNING**: All the following credentials have been exposed on a public GitHub repo and MUST be rotated:

- [ ] **Google Cloud 서비스 계정 키** - GCP Console > IAM > 서비스 계정 > 키 삭제 후 재생성 (hspark, zinsiuni, arshelp 모든 계정)
- [ ] **Naver OCR Secret Key** - Naver Cloud Platform에서 재발급
- [ ] **OCR 암호화 키** (`OCR_ENCRYPT_KEY`) - 새 키 생성
- [ ] **OCR 복호화 파라미터 키** (`OCR_DECRYPT_PARAM_KEY`) - 새 키 생성
- [ ] **OCR 통계 로그 키** (`OCR_STATICS_LOG_KEY`) - 새 키 생성
- [ ] **JWT Token Secret** - 새 시크릿 생성
- [ ] **DB 비밀번호** (`gate21#$`) - DB에서 비밀번호 변경
- [ ] **테스트 페이지 비밀번호** - 새 비밀번호 설정
- [ ] **SSL 키스토어** (`keystore.p12`) - 새 인증서 발급
