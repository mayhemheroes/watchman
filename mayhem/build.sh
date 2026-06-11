#!/usr/bin/env bash
#
# watchman/mayhem/build.sh — build serde_bser's cargo-fuzz roundtrip target (ASan libFuzzer) and a
# standalone file-input reproducer. The fuzzed code is watchman's `serde_bser` crate (BSER
# encode/decode for Watchman). Upstream has no fuzz harness; mayhem/fuzz/ carries the old fork's
# roundtrip harness additively.
set -euo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${MAYHEM_JOBS:=$(nproc)}"
export MAYHEM_JOBS
export CARGO_BUILD_JOBS="$MAYHEM_JOBS"

cd "$SRC"

FUZZ_DIR="mayhem/fuzz"
TARGET="roundtrip"
TRIPLE="x86_64-unknown-linux-gnu"

# ASan via RUSTFLAGS (Rust/cargo-fuzz path — not clang $SANITIZER_FLAGS).
export RUSTFLAGS="${RUSTFLAGS:-} --cfg fuzzing -Zsanitizer=address -Cdebuginfo=1 -Cforce-frame-pointers"

echo "=== cargo fuzz build (ASan libFuzzer): $TARGET ==="
echo "RUSTFLAGS=$RUSTFLAGS"
cargo fuzz build --fuzz-dir "$FUZZ_DIR" -O --debug-assertions "$TARGET"
bin="$SRC/$FUZZ_DIR/target/$TRIPLE/release/$TARGET"
[ -x "$bin" ] || { echo "ERROR: fuzz binary missing at $bin" >&2; exit 1; }
cp "$bin" "/mayhem/$TARGET"
echo "built /mayhem/$TARGET"

# Standalone reproducer: same harness, no sanitizer — runs once on a single input file (Mayhem
# file-input / POV replay). Mirrors the old fork's roundtrip_no_inst (non-instrumented [[bin]]).
echo "=== building standalone reproducer: ${TARGET}-standalone ==="
(
  cd "$FUZZ_DIR"
  RUSTFLAGS="--cfg fuzzing -Clink-dead-code -Cdebug-assertions -Ccodegen-units=1" \
    cargo build --release --bin "$TARGET"
)
standalone="$SRC/$FUZZ_DIR/target/release/$TARGET"
[ -x "$standalone" ] || { echo "ERROR: standalone binary missing at $standalone" >&2; exit 1; }
cp "$standalone" "/mayhem/${TARGET}-standalone"
echo "built /mayhem/${TARGET}-standalone"

echo "build.sh complete:"
ls -la "/mayhem/$TARGET" "/mayhem/${TARGET}-standalone"
