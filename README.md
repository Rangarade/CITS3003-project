# Running the CTF

The main `run.sh` script starts and prepares all CTF services, including the required Docker containers.

## Starting the CTF

From the project directory, run:

```bash
sudo ./run.sh
```

The script will:

* Check that the required dependencies are available.
* Start Docker if necessary.
* Launch the Web and Network services.
* Prepare the Reverse Engineering challenges.
* Start the required Docker containers for the Horizontal and Vertical Escalation challenges.

Keep the terminal running while using the CTF.

To stop all running services and containers, press:

```text
Ctrl+C
```

Once started, `run.sh` will display the access information for each challenge.



# NEON//WIRE — Network Challenges

The NEON//WIRE network contains three network-based challenges. Each challenge requires players to enumerate an exposed network service and exploit the intended vulnerability to recover a flag.

The challenges are designed to provide a progression through the NEON//WIRE environment, with **Challenge 2 required before Challenge 3 can be completed**.

## Challenges

| # | Node   | Name                              | Vulnerability | Flag        |
| - | ------ | --------------------------------- | ------------- | ----------- |
| 1 | NW-042 | NEON//WIRE Backup Node            | ...           | `flag{...}` |
| 2 | NW-042 | NEON//WIRE Authentication Service | ...           | `flag{...}` |
| 3 | NW-042 | NEON//WIRE Session Service        | ...           | `flag{...}` |

## Player Notes

The following guidelines apply to the NEON//WIRE challenges:

* Solve the challenges through the exposed network services and information provided by them.
* Enumeration of the supplied services is expected.
* Relevant logs, configuration files, and service responses may contain information required to progress.
* Do **not** inspect or modify the challenge source code to obtain flags.
* Do **not** brute-force credentials or passwords.
* Do **not** attack the underlying operating system or attempt to gain root access unless explicitly required by a challenge.
* Do **not** attack services or systems outside the supplied CTF environment.
* Large-scale scanning, fuzzing, or unrelated attacks are not required.
* The intended solutions do not require searching the internet for flags or challenge-specific solutions.

## Challenge Progression

The intended progression is:

```text
Challenge 1
    ↓
Challenge 2
    ↓
Challenge 3
```

Challenge 2 provides information or access required to complete Challenge 3.



# IRONVEIL — Horizontal Escalation Challenges

3 vulnerabilities chained together to reach the final flag.

3 flags in total.


## Notes for players

* These challenges are intended to be solved through the vulnerabilities
  provided.
* Relevant logs, configuration files and service responses may contain
  information required to progress.
* Do not inspect or modify the challenge source code to obtain the flags.
* Do not attempt to gain root access on this image.
* Do not attack services or systems outside the supplied CTF environment.



# IRONVEIL — Vertical Escalation Challenges

Three different vulnerabilities that all allow root escalation. Acquiring root by any means
grants access to the root flag, the two advanced attacks each grant their own flags.

3 flags.

All 3 root access challenges are completely independent, and can be completed in any order.

## Notes for players
* These challenges are intended to be solved through the vulnerabilities
  provided.
* While you may choose to write a script, it is never strictly mandatory.
* Relevant logs, configuration files and service responses may contain
  information required to progress.
* Do not inspect or modify the challenge source code to obtain the flags.
* Do not attack services or systems outside the supplied CTF environment.




# NEON//WIRE — Reverse Engineering Challenges


Part of the group CTF box. Three standalone binaries hidden across the
NEON//WIRE network, each requiring static or dynamic reverse engineering
to recover its flag. Same universe as the network and web nodes.

## Challenges (3 flags)
| # | Node      | Name                        | Flag |
|---|-----------|-----------------------------|------|
| 1 | VAULT-07  | NEON//WIRE Secure Vault      | flag{...} |
| 2 | RELAY-11  | NEON//WIRE Diagnostic Relay  | flag{...} |
| 3 | CACHE-23  | NEON//WIRE Encrypted Cache   | flag{...} |

Challenge 2 also functions as a vertical privilege-escalation root path
solving it yields a root shell, not just the flag.

## Setup — no Docker needed for RE-01 / RE-03
Both are standalone stripped x86-64 binaries with no dependencies beyond glibc:

    chmod +x vm_check hidden_flag
    ./vm_check <access_key>
    ./hidden_flag unlock

## Setup — RE-02 requires Docker
This challenge requires specific file permissions to be set at image-build time, which don't survive a plain file transfer, so it must be run via the Docker image rather than copied binaries. The group's run.sh already loads the image and starts the container (re-diagnostic-relay) automatically at boot — just attach to it:

    docker exec -it re-diagnostic-relay bash

If running RE-02 standalone, outside the group script: 

    docker load -i debug_helper_image.tar.gz
    docker run --rm -it ctf-debug-helper

Inside the container: `whoami` starts as `player`, supplying the correct
token to `/usr/local/bin/debug_helper` prints the flag and drops a root shell.

## Notes for players
- RE-01 and RE-03 have no flag stored as plaintext anywhere in the binary 
  `strings` alone will not find them.
- RE-02's valid token is time-sensitive — a value computed once and reused
  later will not work. Your solve approach needs to account for this.
- None of these challenges require Ghidra/gdb specifically, but static
  disassembly (Ghidra) is the fastest path for RE-01 and RE-03.

No ports are exposed by any of these three challenges (all are local
binaries, not network services). Marker-only material (source code, solve
scripts) is in the`marker-only/` folder — do not ship it to other groups. 


# NEON//WIRE — Web Vulnerabilities

A single themed Flask web portal ("NEON//WIRE GRID PORTAL", node NW-042) containing three web vulnerabilities. Challenge 2 yields a cookie that unlocks the admin area needed for Challenge 3, so 2 → 3 is a chain; Challenge 1 is independent.

## Setup — Option A: Docker (recommended)
Brings up the portal and the on-call operator bot (needed for the XSS challenge).

```bash
docker compose up --build      # portal on http://<host>:8080
docker compose down            # stop + remove
```

## Setup — Option B: no Docker

```bash
./run.sh                       # portal on http://<host>:8080
```
Challenges 1 and 3 are fully solvable this way. Challenge 2 also needs the operator bot — run.sh prints the two commands to start it in a second shell.

## Notes for players
- No credentials to find up front — start at `/grid/records`.
- `sqlmap` is not required and (per the unit) not permitted; the SQLi is solvable by hand.
- The XSS "operator" reviews the feedback board every ~20s; be patient.

No ports are exposed beyond **8080**. Marker-only material (sample solutions, flag list) is under `marker-only/` — do not ship it to other groups.
