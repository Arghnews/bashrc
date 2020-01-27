#!/usr/bin/env python3

import operator
import re
import signal
import string
import sys

# For now at least - think this should be fine
def handle_broken_pipe(signal_number, stack_frame):
    # Something like history | head will not get this exit status anyway unless
    # set -o pipefail is on
    sys.exit(0)

signal.signal(signal.SIGPIPE, handle_broken_pipe)

def main(argv):

    rstrip_cmds = True

    cmd_to_index = {}
    prev_cmd = None
    reg = re.compile("^ *[0-9]+  ")

    # We keep track of entries processed and run the regex to find the end of
    # the index and start of the line entries. Running the regex on every single
    # line however is a little slow (can feel the delay before the command
    # returns slightly more). Also we know that the end position will be the
    # same except when the number of digits changes ie.
    # 99999
    # 100000
    # So we just do the regex near 100, 1000, 10000 etc.
    # Near and not at in case there are lines with non-printable characters that
    # we skip and we'd skip finding the new position
    entry_count = 0
    next_change = 1
    delta = 100

    pos = None

    for line in sys.stdin:
        entry_count += 1

        if pos is None or abs(next_change - entry_count) <= delta:
            m = re.match(reg, line)
            if m is None:
                # If we can't match, then skip the line
                # This happens at least on lines that contain ascii
                # non-printable "garbage" characters so we can safely skip them
                continue
            pos = m.end()
            if next_change <= entry_count:
                next_change *= 10

        cmd_start = pos
        index_end = pos - 2

        # This was my hist file entry that broke trying to parse that as a numb
        # For now at least just skipping the "fg" line.
        #  81269  jobs
        #  81270  fg 1`
        #  fg
        #  81271  fg
        #  This "fixes" this by gluing the "fg" line to back of the 81270  fg 1`
        #  line.
        #  Ie. this should fix multiline entries (except if they happen to have
        #  a line that looks like one of these history entries).
        try:
            index = int(line[:index_end].strip())
            cmd = line[cmd_start:]
        except ValueError:
            if prev_cmd:
                cmd = "\n".join((prev_cmd, line))
                index = cmd_to_index[prev_cmd]
                del cmd_to_index[prev_cmd]
        if rstrip_cmds:
            cmd = cmd.rstrip()
        cmd_to_index[cmd] = index
        prev_cmd = cmd


    printable_chars = frozenset(string.printable)
    index_to_cmd = sorted(
            [(index, cmd) for cmd, index in cmd_to_index.items()
                if all(c in printable_chars for c in cmd)],
            key = operator.itemgetter(0))

    # Padding to turn this     to    this
    #                 $99999  ls     $ 99999  ls
    #                 $100000  pwd   $100000  pwd
    digits_width = len(str(entry_count))

    print("\n".join("  ".join((str(index).rjust(digits_width), cmd))
        for index, cmd in index_to_cmd))

if __name__ == "__main__":
    sys.exit(main(sys.argv))
