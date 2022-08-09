#!/usr/bin/env -S python3
import sys
if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} <input> <output>")
    sys.exit(1)

import toml
import struct
with open(sys.argv[1], "r") as infile:
    table = toml.load(infile)

    # Keep track of the strings section.
    section_strings = b""

    # Initialize the loader section.
    section_loader = struct.pack(
        "<II",
        table["loader"]["kernel"],
        table["loader"]["stack"])

    # Build the memory regions section.
    section_memory_regions = b""
    for region in table["memory"]["regions"]:
        section_memory_regions += struct.pack(
            "<III",
            region["rank"],
            region["offset"],
            region["length"])

    # Build the devices section.
    section_devices = b""
    for device in table["devices"]:
        string_offset = len(section_strings)
        section_strings += device["class"].encode("utf-8") + b"\0"

        section_devices += struct.pack(
            "<II",
            string_offset,
            device["base"])


    with open(sys.argv[2], "wb") as outfile:
        outfile.write(b"\0" * 16)
        offset0 = outfile.tell()
        outfile.write(section_loader)
        offset1 = outfile.tell()
        outfile.write(section_memory_regions)
        offset2 = outfile.tell()
        outfile.write(section_devices)
        offset3 = outfile.tell()
        outfile.write(section_strings)

        outfile.seek(0)
        outfile.write(struct.pack(
            "<IIII",
            offset0,
            offset1,
            offset2,
            offset3
        ))
