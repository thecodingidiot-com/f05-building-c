#!/bin/bash

set -o pipefail

# Color codes (disabled if not a tty)
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_RESET='\033[0m'

if [[ ! -t 1 ]]; then
    C_GREEN=''
    C_RED=''
    C_RESET=''
fi

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

hr() {
    echo "────────────────────────────────────────────"
}

banner() {
    echo "════════════════════════════════════════════"
    echo "  f05 — Building C  /  test.sh"
    echo "════════════════════════════════════════════"
}

pass() {
    local label="$1"
    echo -e "${C_GREEN}PASS${C_RESET}  $label"
    pass_count=$((pass_count + 1))
}

fail() {
    local label="$1"
    local reason="$2"
    echo -e "${C_RED}FAIL${C_RESET}  $label"
    echo "      $reason"
    fail_count=$((fail_count + 1))
}

celebrate() {
    echo ""
    echo "════════════════════════════════════════════"
    echo ""
    echo "Doom shipped with a Makefile."
    echo "So does yours."
    echo ""
    echo "════════════════════════════════════════════"
}

# ─────────────────────────────────────────────────────────────────────────────
# Pre-flight
# ─────────────────────────────────────────────────────────────────────────────

for tool in gcc make valgrind; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: $tool not found. Install it and rerun."
        exit 1
    fi
done

if [[ ! -f Makefile || ! -f sort.c || ! -f lines.c || ! -f lines.h ]]; then
    echo "Error: expected a multi-file project in the current directory."
    echo "Need: Makefile, sort.c, lines.c, lines.h"
    echo ""
    echo "Copy this script into your f05-practice directory and run it from"
    echo "there once you have built the multi-file solution."
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────────────

pass_count=0
fail_count=0

TEST_INPUT_FILE=$(mktemp)
TEST_EXPECTED=$(printf 'apple\nbanana\ncherry\n')
printf 'banana\ncherry\napple\n' > "$TEST_INPUT_FILE"

cleanup() {
    make clean >/dev/null 2>&1 || true
    rm -f _sort_san "$TEST_INPUT_FILE"
}
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────────────────
# Checks
# ─────────────────────────────────────────────────────────────────────────────

check_make() {
    local label="make builds the project cleanly"
    make clean >/dev/null 2>&1 || true
    if ! make >/tmp/_make.out 2>/tmp/_make.log; then
        fail "$label" "make failed — see /tmp/_make.log"
        return 1
    fi
    if grep -qi 'warning' /tmp/_make.log; then
        fail "$label" "build emitted warnings — see /tmp/_make.log"
        return 1
    fi
    pass "$label"
    return 0
}

check_sort_correct() {
    local label="./sort produces correctly sorted output"
    if [[ ! -x sort ]]; then
        fail "$label" "no ./sort binary found after make"
        return
    fi
    local actual
    actual=$(./sort "$TEST_INPUT_FILE" 2>/dev/null)
    if [[ "$actual" == "$TEST_EXPECTED" ]]; then
        pass "$label"
    else
        local got
        got=$(echo "$actual" | tr '\n' ' ')
        fail "$label" "expected: apple banana cherry  got: $got"
    fi
}

check_sort_missing_file() {
    local label="./sort returns exit code 1 on a missing file"
    if [[ ! -x sort ]]; then
        fail "$label" "no ./sort binary found"
        return
    fi
    ./sort /nonexistent_f05_test_file >/dev/null 2>&1
    local code=$?
    if [[ "$code" -eq 1 ]]; then
        pass "$label"
    else
        fail "$label" "expected exit code 1, got $code"
    fi
}

check_sort_no_args() {
    local label="./sort returns exit code 1 with no arguments"
    if [[ ! -x sort ]]; then
        fail "$label" "no ./sort binary found"
        return
    fi
    ./sort >/dev/null 2>&1
    local code=$?
    if [[ "$code" -eq 1 ]]; then
        pass "$label"
    else
        fail "$label" "expected exit code 1, got $code"
    fi
}

check_valgrind() {
    local label="./sort runs clean under valgrind"
    if [[ ! -x sort ]]; then
        fail "$label" "no ./sort binary found"
        return
    fi
    if valgrind --error-exitcode=1 --leak-check=full --quiet \
        ./sort "$TEST_INPUT_FILE" >/dev/null 2>/tmp/_vg.log; then
        pass "$label"
    else
        fail "$label" "valgrind reported errors — see /tmp/_vg.log"
    fi
}

check_sanitisers() {
    local label="rebuild with -fsanitize=address,undefined runs clean"
    if ! gcc -Wall -Wextra -Werror -std=c99 -g -O0 -fsanitize=address -fsanitize=undefined \
        sort.c lines.c -o _sort_san 2>/tmp/_san_build.log; then
        fail "$label" "sanitiser build failed — see /tmp/_san_build.log"
        return
    fi
    if ./_sort_san "$TEST_INPUT_FILE" >/dev/null 2>/tmp/_san_run.log; then
        pass "$label"
    else
        fail "$label" "sanitiser run reported errors — see /tmp/_san_run.log"
    fi
}

check_release() {
    local label="make release builds a stripped, optimised binary"
    local debug_size release_size obj_before obj_after out rc

    make fclean >/dev/null 2>&1 || true
    if ! make >/dev/null 2>/tmp/_rel_debug.log; then
        fail "$label" "the debug build failed — see /tmp/_rel_debug.log"
        return
    fi
    debug_size=$(stat -c%s sort)
    obj_before=$(stat -c%.Y sort.o 2>/dev/null || echo 0)

    # A 'release' named in .PHONY but never given a recipe exits 0 with
    # "Nothing to be done", so the exit status alone proves nothing.
    out=$(make release 2>/tmp/_rel_build.log); rc=$?
    if (( rc != 0 )); then
        fail "$label" "no working 'release' target — see /tmp/_rel_build.log"
        return
    fi
    if grep -q "Nothing to be done for .release." <<<"$out"; then
        fail "$label" "'release' is declared but has no recipe"
        return
    fi
    if [[ ! -x sort ]]; then
        fail "$label" "make release produced no ./sort binary"
        return
    fi
    release_size=$(stat -c%s sort)

    if file sort 2>/dev/null | grep -q "not stripped"; then
        fail "$label" "the release binary still has its symbol table — is 'strip' in the target?"
        return
    fi
    if (( release_size >= debug_size )); then
        fail "$label" "release ($release_size B) is not smaller than debug ($debug_size B)"
        return
    fi

    # Object files carry no record of the flags that produced them, so a
    # release target that skips fclean silently links the DEBUG objects and
    # still yields a smaller, stripped binary. Only a real rebuild proves it.
    obj_after=$(stat -c%.Y sort.o 2>/dev/null || echo 0)
    if [[ "$obj_after" == "$obj_before" ]]; then
        fail "$label" "release relinked the debug objects — 'release' must fclean first"
        return
    fi

    # ...and a rebuild with the debug flags is not a release build.
    # (Captured first: 'make -n | grep -q' would SIGPIPE make, and this
    # script runs under 'set -o pipefail'.)
    local dry
    dry=$(make -n release 2>/dev/null)
    if ! grep -qE -- '-O[123sz]' <<<"$dry"; then
        fail "$label" "release rebuilds, but with no optimisation level — expected -O2"
        return
    fi

    pass "$label ($debug_size B -> $release_size B)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'HELP'
Usage: bash test.sh [OPTION]

  (no arguments)    Run all checks against the project in the current directory.
  --help, -h        Show this message.

── Setup ────────────────────────────────────────────────────────────────────

Copy this script into your f05-practice directory and run it from there:

  cp test.sh ~/f05-practice/
  cd ~/f05-practice
  bash test.sh

The directory must contain your finished multi-file project:

  Makefile, sort.c, lines.c, lines.h

── What the tester checks ───────────────────────────────────────────────────

  1. make builds the project cleanly with no warnings.
  2. ./sort sorts the lines of a file alphabetically.
  3. ./sort returns exit code 1 when given a missing file.
  4. ./sort returns exit code 1 when given no arguments.
  5. ./sort runs clean under valgrind --leak-check=full.
  6. A rebuild with -fsanitize=address -fsanitize=undefined runs clean
     on the same input.
  7. make release rebuilds from scratch and produces a stripped binary
     smaller than the debug build.

HELP
    exit 0
fi

if [[ -n "$1" ]]; then
    echo "Unknown option: $1"
    echo "Run bash test.sh --help for usage."
    exit 1
fi

banner
echo ""

if check_make; then
    check_sort_correct
    check_sort_missing_file
    check_sort_no_args
    check_valgrind
    check_sanitisers
    check_release
fi

echo ""
hr
TOTAL=$((pass_count + fail_count))
echo "  $pass_count / $TOTAL checks passed"

if [[ "$fail_count" -eq 0 ]]; then
    celebrate
    exit 0
else
    echo ""
    echo "Fix the failing checks and rerun."
    exit 1
fi
