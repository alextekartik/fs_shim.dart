#!/bin/bash

# Fast fail the script on failures.
set -e

pub run test -p vm,dartium,firefox,chrome --reporter expanded
# pub run test -p firefox -j 1 --reporter expanded