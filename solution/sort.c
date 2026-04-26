#include "lines.h"
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    FILE    *in;
    lines_t lines;
    char    buf[4096];

    if (argc < 2) {
        fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return (1);
    }
    in = fopen(argv[1], "r");
    if (!in) {
        fprintf(stderr, "cannot open %s\n", argv[1]);
        return (1);
    }
    lines_init(&lines);
    while (fgets(buf, sizeof(buf), in)) {
        buf[strcspn(buf, "\n")] = '\0';
        if (lines_append(&lines, buf) != 0) {
            fprintf(stderr, "out of memory\n");
            fclose(in);
            lines_free(&lines);
            return (1);
        }
    }
    fclose(in);
    lines_sort(&lines);
    lines_print(&lines);
    lines_free(&lines);
    return (0);
}
