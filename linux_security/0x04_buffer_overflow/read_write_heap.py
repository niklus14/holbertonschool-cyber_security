#!/usr/bin/python3

import sys


def usage():
    print("Usage: read_write_heap.py pid search_string replace_string")
    sys.exit(1)


if len(sys.argv) != 4:
    usage()

pid = sys.argv[1]
search = sys.argv[2].encode()
replace = sys.argv[3].encode()

if len(replace) > len(search):
    print("Error")
    sys.exit(1)

heap_start = None
heap_end = None

with open(f"/proc/{pid}/maps", "r") as maps:
    for line in maps:
        if "[heap]" in line:
            addresses = line.split()[0]
            heap_start, heap_end = addresses.split("-")
            heap_start = int(heap_start, 16)
            heap_end = int(heap_end, 16)
            break

if heap_start is None:
    print("Error")
    sys.exit(1)

with open(f"/proc/{pid}/mem", "rb+") as mem:
    mem.seek(heap_start)
    heap = mem.read(heap_end - heap_start)

    index = heap.find(search)

    if index == -1:
        print("Error")
        sys.exit(1)

    mem.seek(heap_start + index)
    mem.write(replace + b"\x00" * (len(search) - len(replace)))
