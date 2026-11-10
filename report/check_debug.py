#!/usr/bin/env python3
"""Check the observer against the GNU disassembly and arithmetic, without RTL access."""
import re
import sys
from pathlib import Path

log_path, dump_path = map(Path, sys.argv[1:3])
instructions = {}
for line in dump_path.read_text().splitlines():
    match = re.match(r"\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(\S+)", line)
    if match:
        pc, word, mnemonic = match.groups()
        instructions[int(pc, 16)] = (int(word, 16), mnemonic)

count = 0
for line in log_path.read_text().splitlines():
    if not line.startswith("ADD "):
        continue
    fields = dict(re.findall(r"(\w+)=([0-9a-fx]+)", line))
    pc = int(fields['pc'], 16)
    word = int(fields['instr'], 16)
    actual_word, mnemonic = instructions[pc]
    assert word == actual_word and mnemonic == 'add', (pc, fields, instructions[pc])
    for name, shift in [('rd', 7), ('rs1', 15), ('rs2', 20)]:
        assert int(fields[name][1:]) == (word >> shift) & 31, (pc, name)
    assert int(fields['opcode'], 16) == word & 127
    assert int(fields['funct3'], 16) == (word >> 12) & 7
    assert int(fields['funct7'], 16) == word >> 25
    expected = (int(fields['rs1_value'], 16) + int(fields['rs2_value'], 16)) & 0xffffffff
    assert int(fields['result'], 16) == expected, (hex(pc), fields, hex(expected))
    count += 1

assert 'Test passed' in log_path.read_text(), 'ISA test did not pass'
assert count > 0, 'No ADD events were recorded'
print(f'PASS: {count} ADD events match objdump, register fields and 32-bit sums.')
