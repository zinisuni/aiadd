# 시스템 설계 다이어그램

이 디렉토리는 시스템 설계 관련 다이어그램들을 포함하고 있습니다.

## 다이어그램 목록

- [유스케이스 다이어그램](usecase.md) - 시스템의 주요 기능과 사용자 상호작용을 표현
- [마인드맵](mindmap.md) - 시스템의 주요 구성 요소와 구조를 계층적으로 표현
- [클래스 다이어그램](class.md) - 시스템의 주요 클래스들과 그들 간의 관계를 표현

## 다이어그램 생성 방법

### 자동 생성 스크립트 사용

1. 다이어그램 생성 스크립트 실행:
```bash
./generate.sh
```

생성된 이미지는 `images/` 디렉토리에 저장됩니다.

### 수동 생성

1. 개별 다이어그램 생성:
```bash
mmdc -i [다이어그램파일].md -o images/[다이어그램파일].png
```

예시:
```bash
mmdc -i usecase.md -o images/usecase.png
```

## 다이어그램 보기 방법

1. **GitHub에서 직접 보기**
   - GitHub에서 마크다운 파일을 열면 Mermaid 다이어그램이 자동으로 렌더링됩니다.

2. **생성된 이미지로 보기**
   - `images/` 디렉토리에 있는 PNG 파일을 확인합니다.

3. **Mermaid Live Editor 사용**
   - https://mermaid.live 에서 다이어그램 코드를 붙여넣어 실시간으로 확인할 수 있습니다.

4. **VS Code에서 보기**
   - VS Code에 Mermaid 확장을 설치하여 마크다운 미리보기에서 확인할 수 있습니다.
   - 추천 확장: "Markdown Preview Mermaid Support" 또는 "Mermaid Preview"

## 주의사항

- 생성된 이미지 파일은 `images/` 디렉토리에 저장되며, 이 디렉토리는 .gitignore에 포함되어 있습니다.
- 다이어그램을 수정한 후에는 반드시 스크립트를 실행하여 이미지를 다시 생성해야 합니다.
- 새로운 다이어그램을 추가할 때는 이 README.md 파일에도 추가해주세요.