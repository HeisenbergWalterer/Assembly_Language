#include <stdio.h>

int main(void) {
    printf("9x9 Multiplication Table\n");
    printf("========================================\n");

    for (int i = 1; i <= 9; i++) {
        for (int j = 1; j <= i; j++) {
            printf("%d x %d = %2d  ", j, i, j * i);
        }
        printf("\n");
    }

    printf("========================================\n");
    return 0;
}
