flag = "flag{diagnostic_backdoor_abused}"
key = [0x9a, 0x21, 0x5c, 0x40]
enc = [ord(c) ^ key[i % len(key)] for i, c in enumerate(flag)]
print("flag length:", len(flag))
print("enc_flag[] =", ", ".join(f"0x{b:02x}" for b in enc))

