#!/usr/bin/env sh
#
# DemoMaker 스킬을 Claude Code 와 Codex 에 설치합니다. (macOS · Linux · Git Bash)
#
# 저장소의 shared/ 에 있는 템플릿과 참고 자료를, 대상 도구가 읽는 스킬 폴더로 복사합니다.
# 두 도구는 스킬을 찾는 경로와 참고 자료 폴더의 이름이 서로 다르므로 이 스크립트가 맞춰 줍니다.
#
#     Claude Code : <범위>/.claude/skills/demo-maker/   (참고 자료 폴더 이름은 reference)
#     Codex       : <범위>/.agents/skills/demo-maker/   (참고 자료 폴더 이름은 references)
#
# 쓰는 법
#   ./install.sh                     두 도구 모두에 설치합니다
#   ./install.sh --target codex      Codex 에만 설치합니다
#   ./install.sh --scope repo        현재 저장소 안에만 설치합니다
#   ./install.sh --repo-path /work/x 지정한 저장소 안에만 설치합니다
#   ./install.sh --dest-root /tmp/t  설치 위치를 직접 지정합니다 (시험용)
#   ./install.sh --uninstall         설치본을 지웁니다

set -eu

SKILL_NAME='demo-maker'
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_ROOT=$(dirname -- "$SCRIPT_DIR")

TARGET='all'
SCOPE='user'
REPO_PATH=''
DEST_ROOT=''
UNINSTALL='no'

while [ $# -gt 0 ]; do
    case "$1" in
        --target)     TARGET="$2"; shift 2 ;;
        --scope)      SCOPE="$2"; shift 2 ;;
        --repo-path)  REPO_PATH="$2"; shift 2 ;;
        --dest-root)  DEST_ROOT="$2"; shift 2 ;;
        --uninstall)  UNINSTALL='yes'; shift ;;
        -h|--help)    sed -n '3,22p' "$0"; exit 0 ;;
        *)            echo "모르는 인자입니다: $1" >&2; exit 1 ;;
    esac
done

case "$TARGET" in
    claude|codex|all) ;;
    *) echo "--target 은 claude, codex, all 중 하나여야 합니다." >&2; exit 1 ;;
esac

destination_root() {
    tool="$1"
    if [ -n "$DEST_ROOT" ]; then printf '%s/%s' "$DEST_ROOT" "$tool"; return; fi
    if [ "$SCOPE" = 'user' ]; then printf '%s' "$HOME"; return; fi
    if [ -n "$REPO_PATH" ]; then printf '%s' "$REPO_PATH"; return; fi
    pwd
}

install_one() {
    tool="$1"
    skill_source="$SOURCE_ROOT/$tool/skills/$SKILL_NAME"
    if [ ! -d "$skill_source" ]; then
        echo "원본을 찾지 못했습니다: $skill_source" >&2
        exit 1
    fi

    # 도구마다 스킬을 찾는 폴더와 참고 자료 폴더의 이름이 다릅니다.
    if [ "$tool" = 'claude' ]; then
        holder='.claude/skills'
        reference_name='reference'
    else
        holder='.agents/skills'
        reference_name='references'
    fi

    destination="$(destination_root "$tool")/$holder/$SKILL_NAME"

    if [ "$UNINSTALL" = 'yes' ]; then
        if [ -d "$destination" ]; then
            rm -rf "$destination"
            echo "[$tool] 지웠습니다 — $destination"
        else
            echo "[$tool] 설치되어 있지 않습니다 — $destination"
        fi
        return
    fi

    # 예전 설치본이 남아 있으면 지운 자리에 새로 놓습니다. 파일이 섞이면 원인을 찾기 어렵습니다.
    rm -rf "$destination"
    mkdir -p "$destination/templates" "$destination/$reference_name"

    cp -R "$skill_source/." "$destination/"
    cp "$SOURCE_ROOT/shared/templates/"*.html "$destination/templates/"
    cp "$SOURCE_ROOT/shared/reference/"* "$destination/$reference_name/"

    count=$(find "$destination" -type f | wc -l | tr -d ' ')
    echo "[$tool] 설치했습니다 — $destination (파일 $count 개)"
}

if [ "$TARGET" = 'all' ]; then
    install_one claude
    install_one codex
else
    install_one "$TARGET"
fi

if [ "$UNINSTALL" != 'yes' ]; then
    echo ''
    echo '불러 쓰는 법:'
    if [ "$TARGET" = 'all' ] || [ "$TARGET" = 'claude' ]; then echo '  Claude Code : /demo-maker'; fi
    if [ "$TARGET" = 'all' ] || [ "$TARGET" = 'codex' ];  then echo '  Codex       : $demo-maker  (또는 /skills 목록에서 선택)'; fi
    echo '이미 실행 중인 세션이라면 한 번 다시 시작해야 목록에 나타납니다.'
fi
