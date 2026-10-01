#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <stdint.h>

static const uint8_t enc_flag[] = {
    0xfc, 0x4d, 0x3d, 0x27, 0xe1, 0x45, 0x35, 0x21, 0xfd, 0x4f, 0x33, 0x33,
    0xee, 0x48, 0x3f, 0x1f, 0xf8, 0x40, 0x3f, 0x2b, 0xfe, 0x4e, 0x33, 0x32,
    0xc5, 0x40, 0x3e, 0x35, 0xe9, 0x44, 0x38, 0x3d
};
static const uint8_t flag_key[] = {0x9a, 0x21, 0x5c, 0x40};

static void print_flag(void) {
    char buf[sizeof(enc_flag) + 1];
    for (size_t i = 0; i < sizeof(enc_flag); i++)
        buf[i] = enc_flag[i] ^ flag_key[i % sizeof(flag_key)];
    buf[sizeof(enc_flag)] = '\0';
    printf("%s\n", buf);
}

static unsigned int weak_seed(void) {
    time_t t = time(NULL);
    return (unsigned int)(t / 3600);
}

static void banner(void) {
    printf(
        "\n"
        "+------------------------------------------+\n"
        "|       NEON//WIRE DIAGNOSTIC RELAY         |\n"
        "|       ENGINEERING ACCESS INTERFACE        |\n"
        "+------------------------------------------+\n"
        "NODE       : RELAY-11\n"
        "CLEARANCE  : FIELD ENGINEER\n"
        "SECURITY   : ACTIVE\n"
        "\n"
    );
}

int main(int argc, char **argv) {
    banner();

    if (argc != 2) {
        fprintf(stderr, "USAGE: %s <diagnostic_token>\n", argv[0]);
        return 1;
    }

    srand(weak_seed());
    int expected = rand() % 1000000;

    if (atoi(argv[1]) == expected) {
        printf("DIAGNOSTIC TOKEN ACCEPTED.\n");
	print_flag();
	printf("ESCALATING TO ROOT MAINTENANCE SHELL...\n");
        fflush(stdout);
        if (setuid(0) != 0) { perror("setuid failed"); return 1; }
        if (setgid(0) != 0) { perror("setgid failed"); return 1; }
        execl("/bin/sh", "sh", (char *)NULL);
        perror("execl failed");
        return 1;
    }

    printf("DIAGNOSTIC TOKEN REJECTED.\n");
    return 1;
}
