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