#include "lines.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void lines_init(lines_t *lines)
{
    lines->data = NULL;
    lines->count = 0;
    lines->capacity = 0;
}

int lines_append(lines_t *lines, const char *line)
{
    char    **grown;
    size_t  new_capacity;
    char    *copy;

    if (lines->count == lines->capacity) {
        new_capacity = lines->capacity == 0 ? 16 : lines->capacity * 2;
        grown = realloc(lines->data, new_capacity * sizeof(char *));
        if (!grown)
            return (-1);
        lines->data = grown;
        lines->capacity = new_capacity;
    }
    copy = malloc(strlen(line) + 1);
    if (!copy)
        return (-1);
    strcpy(copy, line);
    lines->data[lines->count++] = copy;
    return (0);
}

static int cmp_strings(const void *a, const void *b)
{
    const char *const *sa = a;
    const char *const *sb = b;
    return (strcmp(*sa, *sb));
}

void lines_sort(lines_t *lines)
{
    qsort(lines->data, lines->count, sizeof(char *), cmp_strings);
}

void lines_print(const lines_t *lines)
{
    size_t i;

    for (i = 0; i < lines->count; i++)
        printf("%s\n", lines->data[i]);
}

void lines_free(lines_t *lines)
{
    size_t i;

    for (i = 0; i < lines->count; i++)
        free(lines->data[i]);
    free(lines->data);
    lines->data = NULL;
    lines->count = 0;
    lines->capacity = 0;
}
