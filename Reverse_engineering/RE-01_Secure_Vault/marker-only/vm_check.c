#include <stdio.h>
#include <string.h>
#include <stdint.h>

static const uint8_t keys[] = {0x37,0x12,0x8a,0x01,0x55,0x2f};
static const uint8_t offs[] = {0x05,0x11,0x03,0x22,0x09,0x14};
#define IV 0xA5

static const uint8_t expected[] = {
    0xf9, 0x98, 0x76, 0x32, 0x25, 0x90, 0xcb, 0xbd, 0x5e, 0x4d, 0x50, 0x30, 0x73, 0x22,
    0xc3, 0xc9, 0xf7, 0x9b, 0xd3, 0xc4, 0x24, 0x70, 0x49, 0x1c, 0x5b
};

static void banner(void) {
    printf(
        "\n"
        "+------------------------------------------+\n"
        "|          NEON//WIRE SECURE VAULT          |\n"
        "|          ACCESS KEY VALIDATION            |\n"
        "+------------------------------------------+\n"
        "NODE       : VAULT-07\n"
        "LINK       : LOCAL\n"
        "SECURITY   : ACTIVE\n"
        "\n"
    );
}

int main(int argc, char **argv) {
    banner();

    if (argc != 2) {
        printf("USAGE: %s <access_key>\n", argv[0]);
        return 1;
    }

    if (strlen(argv[1]) != sizeof(expected)) {
        printf("ACCESS DENIED: KEY LENGTH INVALID.\n");
        return 1;
    }

    uint8_t feedback = IV;
    for (size_t i = 0; i < sizeof(expected); i++) {
        uint8_t k = keys[i % (sizeof keys)];
        uint8_t o = offs[i % (sizeof offs)];
        uint8_t in = (uint8_t)argv[1][i];

        uint8_t val = in ^ k ^ feedback;
        val = (uint8_t)(val + o);

        if (val != expected[i]) {
            printf("ACCESS DENIED: KEY REJECTED.\n");
            return 1;
        }
        feedback = val;
    }

    printf("ACCESS GRANTED.\nVAULT UNLOCKED.\n");
    return 0;
}
