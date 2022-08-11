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

    # Build the memory section.
    pmp = (0, 0)
    if "memory" in table and "pmp" in table["memory"]:
        pmp = (table["memory"]["pmp"]["regions"], table["memory"]["pmp"]["modes"])
    section_memory = struct.pack(
        "<II",
        pmp[0],
        pmp[1])

    # Build the memory regions section.
    section_memory_regions = b""
    memory_region_count = len(table["memory"]["regions"])
    for region in table["memory"]["regions"]:
        section_memory_regions += struct.pack(
            "<III",
            region["rank"],
            region["offset"],
            region["length"])

    # Build the devices section.
    section_devices = b""
    device_count = len(table["devices"])
    for device in table["devices"]:
        string_offset = len(section_strings)
        section_strings += device["class"].encode("utf-8") + b"\0"

        section_devices += struct.pack(
            "<II",
            string_offset,
            device["base"])


    with open(sys.argv[2], "wb") as outfile:
        outfile.write(b"\0" * 20)
        offset0 = outfile.tell()
        outfile.write(section_loader)
        offset1 = outfile.tell()
        outfile.write(section_memory_regions)
        offset2 = outfile.tell()
        outfile.write(section_devices)
        offset4 = outfile.tell()
        outfile.write(section_memory)
        offset3 = outfile.tell()
        outfile.write(section_strings)

        outfile.seek(0)
        outfile.write(struct.pack(
            "<IIIIIII",
            offset0,
            memory_region_count,
            offset1,
            device_count,
            offset2,
            offset3,
            offset4
        ))
