#!/bin/bash
echo "$2  $1" | sha256sum -c --quiet && "$1: OK" || "$1: FAIL"