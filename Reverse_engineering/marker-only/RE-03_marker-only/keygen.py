flag = "flag{cache_payload_recovered}"
key = [0x42, 0x9c, 0x11, 0x77, 0x2b, 0x88, 0x0f, 0x5a]
enc = [ord(c) ^ key[i % len(key)] for i, c in enumerate(flag)]
print("flag length:", len(flag))
print("enc_flag[] =", ", ".join(f"0x{b:02x}" for b in enc))
