NEON//WIRE — Reverse Engineering Challenges
============================================

Part of the group CTF box. Three standalone binaries hidden across the
NEON//WIRE network, each requiring static or dynamic reverse engineering
to recover its flag. Same universe as the network and web nodes.

Challenges (3 flags)
---------------------
| # | Node      | Name                        | Vulnerability                                  | Flag |
|---|-----------|-----------------------------|-------------------------------------------------|------|
| 1 | VAULT-07  | NEON//WIRE Secure Vault      | Chained reversible cipher (weak obfuscation)     | flag{...} |
| 2 | RELAY-11  | NEON//WIRE Diagnostic Relay  | Predictable PRNG seed, SUID-root binary          | flag{...} |
| 3 | CACHE-23  | NEON//WIRE Encrypted Cache   | Runtime-only secret decryption                   | flag{...} |

Challenge 2 also functions as a vertical privilege-escalation root path
solving it yields a root shell, not just the flag.

Setup — no Docker needed for RE-01 / RE-03
--------------------------------------------
Both are standalone stripped x86-64 binaries with no dependencies beyond glibc:

    chmod +x vm_check hidden_flag
    ./vm_check <access_key>
    ./hidden_flag unlock

Setup — RE-02 requires Docker
-------------------------------
The vulnerability depends on a root-owned SUID binary, a permission bit that
cannot survive plain file transfer and must be set at image-build time. The group's 
run.sh already loads the image and starts the container
(re-diagnostic-relay) automatically at boot — just attach to it:

    docker exec -it re-diagnostic-relay bash

If running RE-02 standalone, outside the group script: 

    docker load -i debug_helper_image.tar.gz
    docker run --rm -it ctf-debug-helper

Inside the container: `whoami` starts as `player`, supplying the correct
token to `/usr/local/bin/debug_helper` prints the flag and drops a root shell.

Notes for players
--------------------
- RE-01 and RE-03 have no flag stored as plaintext anywhere in the binary 
  `strings` alone will not find them.
- RE-02's valid token changes every hour, solve tools must compute it against
  the target's current clock, not a cached value.
- None of these challenges require Ghidra/gdb specifically, but static
  disassembly (Ghidra) is the fastest path for RE-01 and RE-03, RE-02 can be
  solved with just a small C program reproducing the same PRNG sequence.

Integration (for the group VM/init-script)
---------------------------------------------
Self-contained under `Reverse_engineering/`. RE-01 and RE-03 need no setup
beyond making the binaries executable. RE-02 is started automatically by the group's run.sh, which loads the
image and launches it detached as re-diagnostic-relay:

    docker load -i Reverse_engineering/RE-02_Diagnostic_Relay/debug_helper_image.tar.gz
    docker run -d -it --name re-diagnostic-relay ctf-debug-helper

No ports are exposed by any of these three challenges (all are local
binaries, not network services). Marker-only material (source code, solve
scripts) is under each challenge's `marker-only/` folder — do not ship it to
other groups.

See `RE_Challenges_Setup_Instructions.pdf` in this folder for the full
per-challenge instructions.
