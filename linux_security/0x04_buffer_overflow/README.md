# Heap Memory Reader & Writer

## Overview

This project demonstrates a low-level memory manipulation technique on Linux systems by directly accessing a process's heap memory. It allows searching for a specific byte sequence in a target process and replacing it in-place.

This type of technique is commonly associated with topics like:

* Memory forensics
* Reverse engineering
* Exploit development (e.g., buffer overflow research)
* Debugging and runtime patching

## Features

* Reads heap memory of a running process via `/proc/[pid]/mem`
* Locates heap boundaries using `/proc/[pid]/maps`
* Searches for a user-defined byte sequence
* Replaces the sequence safely (without expanding memory)
* Pads remaining bytes to maintain memory integrity

## Requirements

* Linux-based operating system
* Python 3.x
* Root privileges (required to access another process's memory)

## Usage

```bash
sudo python3 read_write_heap.py <pid> <search_string> <replace_string>
```

### Example

```bash
sudo python3 read_write_heap.py 1234 password hacked
```

## How It Works

1. The script parses `/proc/[pid]/maps` to locate the heap segment.
2. It reads the heap memory using `/proc/[pid]/mem`.
3. Searches for the given byte sequence.
4. If found, it overwrites the memory with the replacement string.
5. If the replacement is shorter, the remaining bytes are padded with null bytes (`\x00`).

## Limitations

* Replacement string must not exceed the length of the search string.
* Works only on accessible processes (permissions required).
* May not work on protected or hardened systems (e.g., SELinux, ptrace restrictions).

## Security Context

This project is intended for **educational and research purposes only**.

It demonstrates concepts relevant to:

* Buffer overflow analysis
* Memory corruption techniques
* Process memory inspection

Do NOT use this tool on systems or processes without proper authorization.

## Disclaimer

The author is not responsible for any misuse or damage caused by this tool. Use it responsibly and only in controlled environments such as labs or CTF challenges.
