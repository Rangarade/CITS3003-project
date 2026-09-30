Notes: python, vim, nano, and many other commonly used tools aren't installed as this uses debian:bookworm-slim, an exceptionally light distro to keep the docker image as small as possible. All flags can be reached with bash and shell commands.
## Boot and Orient
With the folder open in a CMD window, enter ```docker build -t ironveil-root .```
To run it, enter ```docker run --rm -it --hostname blacknode7 ironveil-root```
motd prints, reveals root flag location, expected to enter ```whoami``` ```id``` and ```sudo -l``` to start
```sudo -l``` reveals 
```
User hex may run the following commands on blacknode7:
    (root) NOPASSWD: /usr/local/bin/enclave-seal
    (root) NOPASSWD: /usr/local/bin/enclave-enroll
```

## Recon
motd specifies files laying around, cd to ```/srv/enclave/``` and cat audit.txt
audit.txt reveals the three vulnerabilities:
	F-001 is a cryptography vulnerability
	F-002 is a timing side-chain vulnerability
	F-003 is an SUID vulnerability

## Route A - Cryptography
```ls -al /etc/enclave/``` reveals
```
-rw-r--r-- 1 root root  admin.sealed # world-readable ciphertext
-rw-r--r-- 1 root root  seal.conf # world readable parameters
-rw------- 1 root root  seal.key # locked secret
-rw------- 1 root root  enroll.code # route b secret
```
Expected reaction is to then cat admin.sealed and seal.conf
admin.sealed produces garbage, while seal.conf reveals pinned IV
This means same keystream is reused for every message, collapses cipher into a two-time pad.
Next step is to remember commands from step 0, specifically enclave-seal
Should notice that ```source "$CONF"``` and ```openssl enc -aes-256-ctr -K "$KEY" -iv "$IV"``` means same pinned IV used every run
Therefore can manufacture own keystream. i.e. feed it all-zero bytes and ciphertext is keystream.
```
# 1. match the sealed blob's length
SZ=$(stat -c%s /etc/enclave/admin.sealed)

# 2. build an all-zero plaintext of that length
head -c "$SZ" /dev/zero > /tmp/zero.bin

# 3. seal it under the same pinned IV -> ciphertext == keystream
sudo /usr/local/bin/enclave-seal /tmp/zero.bin > /tmp/ks.bin

# 4. two-time pad: XOR the target ciphertext with the keystream
perl -e 'local $/; open(A,"<",$ARGV[0]); open(B,"<",$ARGV[1]);
         binmode A; binmode B; my $a=<A>; my $b=<B>; print $a ^ $b;' \
     /etc/enclave/admin.sealed /tmp/ks.bin
```
Student's are not expected to figure out the specific commands by yourself. I assume the average student will be using an AI agent to help.
This prints the root password and a flag for route A, root flag can be found in /root/flag.txt

## Route B - Side Chain
Inspect ```cat /usr/local/bin/enclave-enroll```
Average student should note the ```sleep "$DELAY"``` in the check. An obvious and naively implemented timing vulnerability, but still a side chain timing vulnerability.
Confirm by hand, try ```time sudo /usr/local/bin/enclave-enroll```
Using the wrong first char will instantly reject, using the correct one will delay for .5s (correct first char is 'a')
Student either writes a script or manually checks each char, key is only 6 hexadecimal chars so fully possible.
Note that there is a bug that occasionally causes a check time to spike significantly (up to 5 seconds in my testing), meaning a script that checks every combination every time will usually output a garbage response past the first 3 chars. Cause of the bug is unknown, currently I assume it's some system overhead or hardware I/O hang.
Once the correct key is found (a4f19c) the system automatically grants root access and prints the side chain token.

## Route C - SUID-root find vulnerability (from GTFOBins)
Inspect ```ls -al /usr/local/sbin/blacknode-recover```presents ```-rwsr-xr-x``` perms.
Rename is obfuscation, functions identically to standard find.
Drop root shell with ```/usr/local/sbin/blacknode-recover . -exec /bin/sh -p \; -quit```
Instead of a clean `hex@blacknode7:` you'll likely see `\[\e]0;\u@\h: \w\a\]\u@\h:\w$` or something similar
Normal result, indicates a fragile root shell was found.
Then grab payoff through `cat /root/flag.txt`
