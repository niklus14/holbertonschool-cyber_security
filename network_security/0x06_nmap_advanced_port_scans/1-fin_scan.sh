#!/bin/bash
sudo nmap -sF -p80,85 -ff -T2 $1
