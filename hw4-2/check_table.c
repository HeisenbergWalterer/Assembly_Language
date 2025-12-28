#include <stdio.h>
#include <stdint.h>

static uint8_t table[9][9] = {
    {7, 2, 3, 4, 5, 6, 7, 8, 9},
    {4, 7, 8, 10, 12, 14, 16, 18, 0},
    {3, 6, 9, 12, 15, 18, 21, 24, 27},
    {4, 8, 12, 16, 7, 24, 28, 32, 36},
    {10, 15, 20, 25, 30, 35, 40, 45, 0},
    {6, 12, 18, 24, 30, 7, 42, 48, 54},
    {7, 14, 21, 28, 35, 42, 49, 56, 63},
    {8, 16, 24, 32, 40, 36, 7, 72, 0},
    {9, 18, 27, 36, 45, 54, 63, 72, 81},
};

int main(void) {
    int errors = 0;
    puts("The 9x9 table check:");
    for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
            int actual = table[i][j];
            int expected = (i + 1) * (j + 1);
            if (actual != expected) {
                printf("r=%d c=%d v=%d exp=%d\n", i + 1, j + 1, actual, expected);
                errors++;
            }
        }
    }
    if (errors == 0) {
        puts("\naccomplish!");
    }
    return 0;
}
