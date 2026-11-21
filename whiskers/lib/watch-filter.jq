# Turns raw journal entries (journalctl -o json) into Whiskers events. Anything not matched is dropped.
# SPDX-License-Identifier: GPL-3.0-or-later
def msg: (.MESSAGE // "") | if type == "array" then implode else tostring end;
def kernel: ._TRANSPORT == "kernel";
def ts: ((.__REALTIME_TIMESTAMP // "0") | tonumber / 1000000 | floor);

ts as $t
| msg as $m
| if .MESSAGE_ID == "fc2e22bc6ee647b6b90729ab34a250b1" then
    {kind: "crash", comm: (.COREDUMP_COMM // "unknown"), exe: (.COREDUMP_EXE // ""),
     signal: (.COREDUMP_SIGNAL_NAME // ("signal " + (.COREDUMP_SIGNAL // "?"))), pid: (.COREDUMP_PID // ""), raw: $m}
  elif .MESSAGE_ID == "d9b373ed55a64feb8242e02dbe79a49c" then
    {kind: "unit-failed", unit: (.UNIT // .USER_UNIT // ""), user: (.USER_UNIT != null), raw: $m}
  elif kernel and ($m | test("Out of memory: Killed process")) then
    {kind: "oom", proc: ([$m | capture("Killed process [0-9]+ \\((?<p>[^)]+)\\)").p][0] // "an app"), raw: $m}
  elif (.SYSLOG_IDENTIFIER == "systemd-oomd") and ($m | test("^Killed ")) then
    {kind: "oom", proc: ([$m | capture("Killed (?<p>\\S+)").p][0] // "an app"), raw: $m}
  elif (.SYSLOG_IDENTIFIER == "systemd-logind") and ($m | test("^(suspend|hibernate|hybrid-sleep|suspend-then-hibernate) requested from client")) then
    {kind: "sleep-request", action: ($m | split(" ")[0]),
     client: ([$m | capture("\\('(?<c>[^']+)'\\)").c][0] // "an app"), raw: $m}
  elif ($m | test("Wakeup pending\\. Abort|Freezing of tasks failed|Some devices failed to (suspend|power down)|Failed to put system to sleep|PM: hibernation: .*(failed|error)"; "i")) then
    {kind: "sleep-failed", raw: $m}
  elif kernel and ($m | test("I/O error, dev |critical medium error|EXT4-fs error|BTRFS error|nvme[0-9]+: (I/O [0-9]+ .*timeout|resetting controller)")) then
    {kind: "disk-error", dev: ([$m | capture("(?<d>(nvme[0-9]+n?[0-9]*|sd[a-z]+))").d][0] // "a drive"), raw: $m}
  elif kernel and ($m | test("ring [a-z0-9_.]+ timeout|GPU reset begin|NVRM: Xid|GPU has fallen off the bus")) then
    {kind: "gpu", raw: $m}
  elif kernel and ($m | test("temperature above threshold, cpu clock throttled|critical temperature reached")) then
    {kind: "thermal", raw: $m}
  else empty end
| . + {time: $t}
