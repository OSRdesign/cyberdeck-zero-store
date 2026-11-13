#!/bin/sh
# SPDX-FileCopyrightText: 2026 M5Stack Technology CO LTD
# SPDX-License-Identifier: MIT

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

if grep -R -n -E 'appstore::native_|#include[[:space:]]+"appstore_native\.hpp"' "$root/main/ui"; then
    echo "UI must not call or include the native backend directly" >&2
    exit 1
fi

if grep -R -n -- '"--package-helper"' "$root/main/ui"; then
    echo "UI must submit typed privileged package requests, not construct helper commands" >&2
    exit 1
fi

if grep -n 'backend_capture' "$root/main/ui/appstore.cpp"; then
    echo "AppStore UI must route backend work through task/package services" >&2
    exit 1
fi

# CyberDeck Zero fork: the package helper's apt-get install never pulls Recommends (owner decision 2026-11-13)
if ! grep -q -F 'command = {"apt-get", "-y", "--no-install-recommends"};' "$root/main/backend/appstore_native.cpp"; then
    echo "package helper apt-get install must pass --no-install-recommends" >&2
    exit 1
fi
if [ "$(grep -c -F '"apt-get"' "$root/main/backend/appstore_native.cpp")" -ne 1 ]; then
    echo "package helper: a new apt-get command must also pass --no-install-recommends (update this test)" >&2
    exit 1
fi

echo "backend boundary tests passed"
