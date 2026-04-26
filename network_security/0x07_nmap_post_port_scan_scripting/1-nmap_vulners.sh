#!/bin/bash
nmap -p 80,443 -sV --script=vulners "$1"
