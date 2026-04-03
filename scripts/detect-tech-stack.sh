#!/usr/bin/env bash
set -e

# Heuristic detection of language/framework from project files
# Usage: detect-tech-stack.sh [<repo_root>]

REPO_ROOT="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

[ -z "$REPO_ROOT" ] && REPO_ROOT=$(get_repo_root)

language=""
framework=""
testing=""
storage=""
platform=""
project_type=""

# Go
if [ -f "$REPO_ROOT/go.mod" ]; then
    go_ver=$(grep '^go ' "$REPO_ROOT/go.mod" 2>/dev/null | awk '{print $2}' || true)
    language="Go ${go_ver}"
    testing="go test"
    platform="linux"
    grep -q 'github.com/spf13/cobra' "$REPO_ROOT/go.mod" 2>/dev/null && framework="${framework:+$framework, }Cobra"
    grep -q 'github.com/gin-gonic/gin' "$REPO_ROOT/go.mod" 2>/dev/null && framework="${framework:+$framework, }Gin"
    grep -q 'github.com/labstack/echo' "$REPO_ROOT/go.mod" 2>/dev/null && framework="${framework:+$framework, }Echo"
    grep -q 'github.com/gofiber/fiber' "$REPO_ROOT/go.mod" 2>/dev/null && framework="${framework:+$framework, }Fiber"
    [ -d "$REPO_ROOT/cmd" ] && project_type="cli"
fi

# Node.js / TypeScript
if [ -f "$REPO_ROOT/package.json" ]; then
    [ -f "$REPO_ROOT/tsconfig.json" ] && language="TypeScript" || language="JavaScript"
    grep -q '"next"' "$REPO_ROOT/package.json" 2>/dev/null && framework="${framework:+$framework, }Next.js"
    grep -q '"react"' "$REPO_ROOT/package.json" 2>/dev/null && framework="${framework:+$framework, }React"
    grep -q '"vue"' "$REPO_ROOT/package.json" 2>/dev/null && framework="${framework:+$framework, }Vue"
    grep -q '"express"' "$REPO_ROOT/package.json" 2>/dev/null && framework="${framework:+$framework, }Express"
    grep -q '"@nestjs/core"' "$REPO_ROOT/package.json" 2>/dev/null && framework="${framework:+$framework, }NestJS"
    grep -q '"vitest"' "$REPO_ROOT/package.json" 2>/dev/null && testing="vitest"
    grep -q '"jest"' "$REPO_ROOT/package.json" 2>/dev/null && testing="${testing:+$testing, }jest"
    [ -z "$project_type" ] && project_type="web-app"
fi

# Python
if [ -f "$REPO_ROOT/pyproject.toml" ] || [ -f "$REPO_ROOT/setup.py" ] || [ -f "$REPO_ROOT/requirements.txt" ]; then
    language="Python"
    if [ -f "$REPO_ROOT/pyproject.toml" ]; then
        grep -qi 'django' "$REPO_ROOT/pyproject.toml" 2>/dev/null && framework="${framework:+$framework, }Django"
        grep -qi 'fastapi' "$REPO_ROOT/pyproject.toml" 2>/dev/null && framework="${framework:+$framework, }FastAPI"
        grep -qi 'flask' "$REPO_ROOT/pyproject.toml" 2>/dev/null && framework="${framework:+$framework, }Flask"
        grep -qi 'pytest' "$REPO_ROOT/pyproject.toml" 2>/dev/null && testing="pytest"
    fi
fi

# PHP
if [ -f "$REPO_ROOT/composer.json" ]; then
    language="PHP"
    grep -q '"symfony/' "$REPO_ROOT/composer.json" 2>/dev/null && framework="${framework:+$framework, }Symfony"
    grep -q '"laravel/' "$REPO_ROOT/composer.json" 2>/dev/null && framework="${framework:+$framework, }Laravel"
    grep -q '"api-platform/' "$REPO_ROOT/composer.json" 2>/dev/null && framework="${framework:+$framework, }API Platform"
    grep -q '"phpunit/' "$REPO_ROOT/composer.json" 2>/dev/null && testing="PHPUnit"
fi

# Rust
if [ -f "$REPO_ROOT/Cargo.toml" ]; then
    language="Rust"
    testing="cargo test"
    grep -qi 'actix' "$REPO_ROOT/Cargo.toml" 2>/dev/null && framework="${framework:+$framework, }Actix"
    grep -qi 'axum' "$REPO_ROOT/Cargo.toml" 2>/dev/null && framework="${framework:+$framework, }Axum"
    grep -qi 'clap' "$REPO_ROOT/Cargo.toml" 2>/dev/null && project_type="cli"
fi

# Storage from docker compose
for dc_file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/docker-compose.yaml" "$REPO_ROOT/compose.yaml"; do
    if [ -f "$dc_file" ]; then
        grep -qi 'postgres' "$dc_file" 2>/dev/null && storage="${storage:+$storage, }PostgreSQL"
        grep -qi 'mysql\|mariadb' "$dc_file" 2>/dev/null && storage="${storage:+$storage, }MySQL"
        grep -qi 'redis' "$dc_file" 2>/dev/null && storage="${storage:+$storage, }Redis"
        grep -qi 'mongo' "$dc_file" 2>/dev/null && storage="${storage:+$storage, }MongoDB"
        break
    fi
done

# Fallbacks
[ -z "$language" ] && language="NEEDS CLARIFICATION"
[ -z "$framework" ] && framework="NEEDS CLARIFICATION"
[ -z "$testing" ] && testing="NEEDS CLARIFICATION"
[ -z "$storage" ] && storage="N/A"
[ -z "$platform" ] && platform="NEEDS CLARIFICATION"
[ -z "$project_type" ] && project_type="NEEDS CLARIFICATION"

echo "=== Tech Stack ==="
echo "LANGUAGE=$language"
echo "FRAMEWORK=$framework"
echo "TESTING=$testing"
echo "STORAGE=$storage"
echo "PLATFORM=$platform"
echo "PROJECT_TYPE=$project_type"
