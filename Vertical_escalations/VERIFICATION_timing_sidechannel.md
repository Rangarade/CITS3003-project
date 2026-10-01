# Verification — Timing Side-Channel (enclave-enroll, Vertical Escalations)

**Tested by:** Chris Jose (23848254)
**Target:** `Vertical_escalations/enclave-enroll.sh`

## What was verified
Independently confirmed Nick's timing side-channel challenge is solvable by script,
not just by hand, using a black-box character-by-character timing attack.

- Built and ran the `Vertical_escalations` container fresh.
- Confirmed the real oracle: `sudo enclave-enroll <guess>` adds ~0.5s per correct
  leading hex digit before rejecting (verified manually with `time`).
- Wrote a reference solver (`solve_timing.py`) that samples each candidate
  character multiple times (min of N, to denoise), locks in the best-scoring
  digit at each position, and repeats for all 6 positions.
- Ran it against the live container via `docker exec`. It correctly recovered
  the key start-to-finish with no prior knowledge, confirming the challenge
  is genuinely scriptable.

## Bonus finding — unintended bypass
Running `enclave-enroll` directly as the low-privilege `hex` user (no `sudo`,
no guess argument) returns an **instant accept** and leaks the flag.

**Root cause:** `enroll.code` is root-only readable (`600`). When run without
`sudo`, the script's `cat "$CODE_FILE" 2>/dev/null` silently fails on
permission-denied, so `SECRET=""`. This makes `N=0`, so the loop never runs,
`matched` stays `0`, and the accept check (`matched -eq N` and
`${#CAND} -eq N`) passes trivially for any empty guess.

**Recommendation:** make the permission failure fail closed (non-zero length
sentinel, or explicit check that the read succeeded) rather than defaulting
to an empty string that satisfies the success condition.

## Conclusion
The intended timing side-channel is real, consistent, and scriptable as
designed. The unintended bypass above is a separate, minor issue worth a
one-line fix before the live demo.
