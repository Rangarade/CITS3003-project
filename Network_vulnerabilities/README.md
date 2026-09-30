# NEON//WIRE — Network Challenges

**================================**

Part of the group CTF box. Four network-based challenges distributed across the

NEON//WIRE network, each requiring enumeration and exploitation of an exposed

network service to recover its flag. Same universe as the reverse engineering

and web nodes.

Challenges (4 flags)

**---------------------**

| # | Node   | Name                              | Vulnerability                    | Flag      |
| - | ------ | --------------------------------- | -------------------------------- | --------- |
| 1 | NW-042 | NEON//WIRE Backup Node            | Path traversal                   | flag{...} |
| 2 | NW-042 | NEON//WIRE Authentication Service | Predictable authentication token | flag{...} |
| 3 | NW-042 | NEON//WIRE Session Service        | Leaked active session credential | flag{...} |

Challenge 2 is required before Challenge 3 can be completed.

Setup

**--------------------------------**

All network challenges are contained within the supplied

`Network/` directory and are started together using:

```text
chmod +x run.sh
./run.sh
```

The launcher starts the required network services and displays their

connection information.

No Docker setup is required unless otherwise stated by the challenge

environment.

Notes for players

**--------------------**

* These challenges are intended to be solved through the exposed network
  services and information provided by them.

* Enumeration of the supplied services is expected.

* Relevant logs, configuration files and service responses may contain
  information required to progress.

* Do not inspect or modify the challenge source code to obtain the flags.

* Do not brute-force credentials or passwords.

* Do not attack the underlying operating system or attempt to gain root
  access unless explicitly required by a challenge.

* Do not attack services or systems outside the supplied CTF environment.

* Large-scale scanning, fuzzing or unrelated attacks are not required.

* The intended solutions do not require searching the internet for flags
  or challenge-specific solutions.

Integration (for the group VM/init-script)

**---------------------------------------------**

Self-contained under `Network/`.

The complete network challenge environment can be started using the supplied

`run.sh` launcher.

Challenge files, service configuration and supporting data are contained

within their respective challenge directories.

Marker-only material is kept separately and should not be included in the

player-facing challenge package.

See `Network_Challenges_Setup_Instructions.pdf` in this folder for the full

setup and per-challenge instructions.
