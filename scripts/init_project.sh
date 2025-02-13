#!/bin/bash

# 프로젝트 초기화 스크립트

# Git 저장소가 이미 존재하는지 확인
if [ -d ".git" ]; then
    echo "Git repository already exists."
else
    echo "Initializing Git repository..."
    git init
fi

# 기본 디렉토리 구조 생성
directories=(
    "docs/planning"
    "docs/development"
    "docs/design"
    "docs/accounting"
    "docs/sales"
    "docs/legal"
    "docs/marketing"
    "docs/hr"
    "docs/customer_service"
    "docs/it_support"
    "src/aiadd"
    "src/aiadw"
    "src/common"
    "src/tests"
    "data"
    "config"
    "scripts"
    "images"
)

echo "Creating directory structure..."
for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    touch "$dir/.gitkeep"  # 빈 디렉토리도 Git에서 추적하기 위한 파일
done

# README.md 파일이 없는 경우에만 생성
if [ ! -f "README.md" ]; then
    echo "Creating README.md..."
    cat > README.md << 'EOL'
# AI Project

## Overview
This project follows AIADD (AI Agent Driven Development) and AIADW (AI Agent Driven Work) methodologies.

## Project Structure
- /docs - Project documentation and resources
- /src - Source code
- /data - Data files and scripts
- /config - Configuration files
- /scripts - Utility scripts
- /images - Image storage

## Getting Started
1. Clone this repository
2. Run `./scripts/init_project.sh` to initialize the project structure
3. Start developing!
EOL
fi

echo "Creating .gitignore file..."
cat > .gitignore << 'EOL'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.idea/
.vscode/
*.swp
*.swo
*~

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
.env
venv/
ENV/

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs and databases
*.log
*.sqlite
*.db

# Build output
/build
/dist
/out

# Coverage reports
/coverage
.coverage
.coverage.*
coverage.xml
*.cover
EOL

# 스크립트 실행 권한 부여
chmod +x scripts/init_project.sh

echo "Project structure initialized successfully!"
echo "You can now start working on your project."