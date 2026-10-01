#include <stdio.h>
#include <string.h>
#include <stdint.h>

static const uint8_t enc_flag[] = {
    0x24, 0xf0, 0x70, 0x10, 0x50, 0xeb, 0x6e, 0x39, 0x2a, 0xf9, 0x4e, 0x07,
    0x4a, 0xf1, 0x63, 0x35, 0x23, 0xf8, 0x4e, 0x05, 0x4e, 0xeb, 0x60, 0x2c,
    0x27, 0xee, 0x74, 0x13, 0x56
};

static const uint8_t key[] = {0x42, 0x9c, 0x11, 0x77, 0x2b, 0x88, 0x0f, 0x5a};

static void banner(void) {
    printf(
        "\n"
        "+------------------------------------------+\n"
        "|       NEON//WIRE ENCRYPTED CACHE          |\n"
        "|       DATA RECOVERY INTERFACE             |\n"
        "+------------------------------------------+\n"
        "NODE       : CACHE-23\n"
        "PAYLOAD    : SEALED\n"
        "SECURITY   : ACTIVE\n"
        "\n"
    );
}

int main(int argc, char **argv) {
    banner();

    uint8_t buf[sizeof(enc_flag) + 1];
    size_t n = sizeof(enc_flag);

    for (size_t i = 0; i < n; i++)
        buf[i] = enc_flag[i] ^ key[i % sizeof(key)];
    buf[n] = '\0';

    if (argc == 2 && strcmp(argv[1], "unlock") == 0) {
        printf("PAYLOAD DECRYPTED:\n%s\n", buf);
    } else {
        printf("PAYLOAD SEALED. RECOVERY COMMAND REJECTED.\n");
    }
    return 0;
}

