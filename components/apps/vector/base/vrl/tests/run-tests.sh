#!/bin/bash

set -euf -o pipefail

vector -q vrl -i tests/inputs/critial-read-write.input -p filter-siem.vrl
