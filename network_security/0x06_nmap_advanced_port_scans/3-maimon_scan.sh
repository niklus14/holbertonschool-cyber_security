#!/bin/bash
sudo nmap -sM -phttp,https,ftp,ssh,telnet -vv "$1"
