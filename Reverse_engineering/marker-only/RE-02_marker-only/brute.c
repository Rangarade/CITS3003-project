#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
    time_t now = time(NULL);
    unsigned int now_hour = (unsigned int)(now / 3600);
    for (int delta = -2; delta <= 2; delta++) {
        unsigned int seed = now_hour + delta;
        srand(seed);
        int expected = rand() % 1000000;
        printf("hour=%u (delta %d) -> token=%d\n", seed, delta, expected);
    }
    return 0;
}
