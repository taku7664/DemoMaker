# DemoMaker

데모를 html로 간단하게 나타내도록 해주는 Skill

기술 변경 사항을 글로 설명하는 대신 브라우저에서 직접 눌러 보게 만듭니다. 만들어진 데모는 파일 하나로
완결되므로 서버나 빌드 과정 없이 그대로 열어서 보고, 그대로 첨부해서 보낼 수 있습니다.
**Claude Code** 와 **Codex** 양쪽에서 같은 스킬로 쓸 수 있습니다.

## 설치

```powershell
powershell -ExecutionPolicy Bypass -File install\install.ps1
```

```bash
sh install/install.sh
```

기본값은 두 도구 모두에 설치하는 것입니다. 한쪽만 설치하거나 특정 저장소 안에만 두려면 다음과 같이 합니다.

| 하려는 일 | PowerShell | sh |
| --- | --- | --- |
| Claude Code 에만 설치 | `install\install.ps1 -Target claude` | `install/install.sh --target claude` |
| Codex 에만 설치 | `install\install.ps1 -Target codex` | `install/install.sh --target codex` |
| 현재 저장소 안에만 설치 | `install\install.ps1 -Scope repo` | `install/install.sh --scope repo` |
| 설치본 지우기 | `install\install.ps1 -Uninstall` | `install/install.sh --uninstall` |

설치되는 위치는 다음과 같습니다. 이미 실행 중인 세션이라면 한 번 다시 시작해야 목록에 나타납니다.

| 도구 | 개인 설치 | 저장소 설치 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/demo-maker/` | `<저장소>/.claude/skills/demo-maker/` |
| Codex | `~/.agents/skills/demo-maker/` | `<저장소>/.agents/skills/demo-maker/` |

## 부르는 법

| 도구 | 명시적으로 부르기 | 저절로 불려 나오기 |
| --- | --- | --- |
| Claude Code | `/demo-maker` | 데모를 만들어 달라는 요청에서 자동으로 |
| Codex | `$demo-maker` (또는 `/skills` 목록에서 선택) | 같음 |

## 구성

```
DemoMaker/
├─ shared/                       ← 두 도구가 함께 쓰는 자산 (여기만 고치면 양쪽에 반영됩니다)
│  ├─ templates/                    복사해서 채우는 템플릿 세 종
│  └─ reference/                    규격 문서와 공통 스타일 원본
├─ claude/skills/demo-maker/      ← Claude Code 용 SKILL.md
├─ codex/skills/demo-maker/       ← Codex 용 SKILL.md 와 agents/openai.yaml
└─ install/                       ← 설치 스크립트 (install.ps1, install.sh)
```

| 파일 | 내용 |
| --- | --- |
| `shared/templates/demo-compare.html` | 조작이 필요한 좌우 비교형 데모 |
| `shared/templates/demo-auto.html` | 조작이 필요 없는 자동 재생형 데모 |
| `shared/templates/demo-cases.html` | 규칙을 경우별로 확인하는 케이스 표형 데모 |
| `shared/reference/STYLE.md` | 데모 규격과 내보내기 전 점검표 |
| `shared/reference/base.css` | 공통 스타일 원본 |

두 도구는 스킬을 찾는 경로와 참고 자료 폴더의 이름이 서로 다릅니다. Claude Code 는 `reference/` 를,
Codex 는 `references/` 를 쓰므로 설치 스크립트가 복사할 때 이름을 맞춰 줍니다. 그래서 `shared/` 에는
폴더가 하나만 있습니다.

## 고칠 때

- **템플릿이나 규격을 고칠 때** 는 `shared/` 만 고치면 됩니다. 다시 설치하면 양쪽에 반영됩니다.
- **스킬 본문을 고칠 때** 는 `claude/` 와 `codex/` 의 `SKILL.md` 를 함께 고칩니다. 두 파일의 차이는
  참고 자료 폴더 이름과 부르는 방법을 적은 세 군데뿐이므로, 한쪽을 고친 뒤 `diff` 로 확인하십시오.
- `install/install.ps1` 은 **UTF-8 BOM 으로 저장해야 합니다.** Windows PowerShell 5.1 은 BOM 이 없는
  파일을 시스템 코드 페이지로 읽기 때문에, BOM 을 빼면 한글 주석이 깨지면서 스크립트가 중간에 멈춥니다.

## 쓰는 법

세 템플릿은 그 자체로 동작하는 완성된 데모입니다. 먼저 브라우저에서 열어 어떤 형식인지 확인한 뒤,
맞는 것을 새 파일로 복사하고 파일 안의 `[고칠 자리]` 표시를 따라가며 내용을 채웁니다.
표시를 모두 없애면 초안이 끝나고, 그다음 `shared/reference/STYLE.md` 의 점검표를 확인합니다.
