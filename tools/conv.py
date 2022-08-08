#!/usr/bin/env -S python3
import sys
if len(sys.argv) < 3:
	print(f"Usage: {sys.argv[0]} <input> <output>")
	sys.exit(1)

with open(sys.argv[1], "rb") as infile:
	buffer = infile.read()
	target = ""
	with open(sys.argv[2], "wb") as outfile:
		target += f"-- The good RISC-V tololchain. :^)\n"
		target += f"-- Auto-generated memory init file from source file <{sys.argv[1]}>\n"
		target += f"-- Size: {len(buffer)} bytes\n"
		target += "\n"
		target += "library ieee;\n"
		target += "use ieee.std_logic_1164.all;\n"
		target += "\n"
		target += "library neorv32;\n"
		target += "use neorv32.neorv32_package.all;\n"
		target += "\n"
		target += "package neorv32_application_image is\n"
		target += "\n"
		target += "  constant application_init_image : mem32_t := (\n"

		counter = 0
		byte_counter = 0
		acc = 0
		for byte in range(len(buffer)):
			acc >>= 8
			acc |= buffer[byte] << 24

			byte_counter += 1
			if byte_counter == 4:
				target += "    {:08d} => x\"{:08x}\"{}\n".format(
					counter, 
					acc,
					{False: ",", True: ""}[byte == len(buffer) - 1])
				acc = 0
				byte_counter = 0
				counter += 1
		if byte_counter != 0:
			target += "    {:08d} => x\"{:08x}\"\n".format(
				counter, 
				acc)
		
		target += "  );\n"
		target += "\n"
		target += "end neorv32_application_image;\n"

		outfile.write(target.encode("ascii"))
