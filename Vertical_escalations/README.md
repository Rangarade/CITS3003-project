# IRONVEIL — Vertical Escalation Challenges

**================================**

Part of the group CTF box. Three different vulnerabilities that all allow root

escalation. Acquiring root by any means grants access to the root flag, the cryptography

and side channel attacks each grant their own flags.

Challenges (3 flags)

**---------------------**

| # | Name                              | Vulnerability                    | Flag      |
| - | --------------------------------- | -------------------------------- | --------- |
| 0 | Acquire root by any means         | Any of the below                 | FLAG{...} |
| 1 | IRONVEIL Sealing service          | Re-used AES-CTR number once      | FLAG{...} |
| 2 | IRONVEIL Enrollment               | Timing-based side channel attack | FLAG{...} |
| 3 | IRONVEIL Recovery Tool            | SUID Root-find                   | None      |

All 3 root access challenges are completely independent, and can be completed in any order.

Setup

**--------------------------------**

All challenges are contained within the supplied

`Vertical_escalations/` directory and are started using the ```run.sh``` command in the main directory.

Then, launch a different shell and enter

```bash
docker exec -it ironveil-vertical su - hex
```

Notes for players

**--------------------**

* These challenges are intended to be solved through the vulnerabilities
  provided.

* While you may choose to write a script, it is never strictly mandatory.

* Relevant logs, configuration files and service responses may contain
  information required to progress.

* Do not inspect or modify the challenge source code to obtain the flags.

* Once root access has been gained via one method, do not use root to
  decrypt or view the flags of other methods.

* Do not attack services or systems outside the supplied CTF environment.

* Flag 2's timing side-channel may behave unpredictably due to hardware speed, CPU scheduling,
  and other causes not fixable within the docker container.
