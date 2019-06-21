#!/usr/bin/env python3

import operator
import re
import sys

def gen(line, stdin):
    yield line
    yield from stdin

def main(argv):

    rstrip_cmds = True

    first_line = next(sys.stdin)
    if first_line:
        pos = re.match("^\s*[0-9]+\s\s", first_line).end()
        index_end, cmd_start = pos - 2, pos

    cmd_to_index = {}
    for line in gen(first_line, sys.stdin):
        line = line[:-1]
        index = int(line[:index_end].strip())
        cmd = line[cmd_start:]
        if rstrip_cmds:
            cmd = cmd.rstrip()
        cmd_to_index[cmd] = index
    index_to_cmd = sorted([(index, cmd) for cmd, index in cmd_to_index.items()],
            key = operator.itemgetter(0))
    print("\n".join("  ".join((str(index), cmd)) for index, cmd in index_to_cmd))

if __name__ == "__main__":
    sys.exit(main(sys.argv))
