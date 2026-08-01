#!/bin/bash
# Runs the test suites with the settings that are actually fastest on this hardware.
#
# XCUITest parallelises by cloning the simulator and handing each clone a whole test *class*,
# not a test method. Two consequences, both measured on an 8-core / 16GB machine:
#
#   1. A long test class cannot be split. When all fourteen cycle modes lived in one class it
#      pinned the run at ~8 minutes no matter how many workers were available. They are sharded
#      into four classes now (see CycleModeUITests.swift).
#   2. More workers is not better. Each clone is a full iOS simulator, so RAM runs out before
#      cores do. Measured, end-to-end target only:
#
#         serial ................................. 8:26
#         4 workers, one big mode class .......... 8:21   (no gain: one class, one worker)
#         4 workers, sharded ..................... 9:37   (thrashing; a clone failed to launch)
#         3 workers, sharded ..................... >10:00
#         2 workers, sharded ..................... 5:33   <- and CPU use went 7% -> 79%
#
# On a machine with more RAM, raise WORKERS. The class sharding is what lets that pay off.
set -euo pipefail

SCHEME="AsteraDev"
PROJECT="AsteraDev.xcodeproj"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
WORKERS="${WORKERS:-2}"

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null; then
    echo "xcodegen is required: brew install xcodegen" >&2
    exit 1
fi

echo "==> Regenerating the project"
xcodegen generate >/dev/null

echo "==> Consistency checks"
python3 scripts/build_privacy.py --check
python3 scripts/check_consistency.py

echo "==> Tests (${WORKERS} parallel workers)"
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -parallel-testing-enabled YES \
    -maximum-parallel-testing-workers "$WORKERS" \
    "$@"
