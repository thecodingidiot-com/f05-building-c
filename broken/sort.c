#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int cmp_strings(const void *a, const void *b)
{
    const char *const *sa = a;
    const char *const *sb = b;
    return (strcmp(*sa, *sb));
}

int main(int argc, char **argv)
{
    FILE    *in;
    char    **lines;
    char    *copy;
    size_t  count;
    size_t  capacity;
    size_t  new_capacity;
    size_t  i;
    char    buf[4096];

    if (argc < 2) {
        fprintf(stderr, "usage: %s <file>\n", argv[0]);
        return (1);
    }
    in = fopen(argv[1], "r");
    lines = NULL;
    count = 0;
    capacity = 0;
    while (fgets(buf, sizeof(buf), in)) {
        buf[strcspn(buf, "\n")] = '\0';
        if (count == capacity) {
            if (capacity == 0)
                new_capacity = 16;
            else
                new_capacity = capacity * 2;
            lines = realloc(lines, new_capacity * sizeof(char *));
            capacity = new_capacity;
        }
        copy = malloc(strlen(buf));
        strcpy(copy, buf);
        lines[count++] = copy;
    }
    fclose(in);
    qsort(lines, count, sizeof(char *), cmp_strings);
    for (i = 0; i < count; i++)
        printf("%s\n", lines[i]);
    free(lines);
    return (0);
}
