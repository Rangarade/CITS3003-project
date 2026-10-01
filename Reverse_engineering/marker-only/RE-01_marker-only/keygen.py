flag = "flag{vault_cipher_broken}"
keys = [0x37, 0x12, 0x8a, 0x01, 0x55, 0x2f]
offs = [0x05, 0x11, 0x03, 0x22, 0x09, 0x14]
IV = 0xA5  # initial feedback byte, chains the whole sequence together

expected = []
feedback = IV
for i, c in enumerate(flag):
    k = keys[i % len(keys)]
    o = offs[i % len(offs)]
    val = ord(c) ^ k ^ feedback     # XOR with key AND previous output byte
    val = (val + o) & 0xFF
    expected.append(val)
    feedback = val                 # this byte's output feeds the next

print("flag length:", len(flag))
print("expected[] =", ", ".join(f"0x{b:02x}" for b in expected))
