# IRONVEIL — Horizontal Escalation Challenges

**================================**

Part of the group CTF box. Three different vulnerabilities that must be chained

together to reach the final flag.

3 flags.

Setup

**--------------------------------**

All challenges are contained within the supplied

`/Horizontal_escalations/` directory and are started using the ```run.sh``` command in the main directory.

Then, launch a different shell and enter

```bash
docker exec -it ironveil-horizontal su - vance
```

Notes for players

**--------------------**

* These challenges are intended to be solved through the vulnerabilities
  provided.

* Relevant logs, configuration files and service responses may contain
  information required to progress.

* Do not inspect or modify the challenge source code to obtain the flags.

* Do not attempt to gain root access on this image.

* Do not attack services or systems outside the supplied CTF environment.

* Flag 3's solution may seem to fail silently with no reason or warning.
  Double check permissions carefully.
