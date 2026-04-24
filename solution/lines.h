#ifndef LINES_H
#define LINES_H

#include <stddef.h>

typedef struct {
    char    **data;
    size_t  count;
    size_t  capacity;
}   lines_t;

void    lines_init(lines_t *lines);
int     lines_append(lines_t *lines, const char *line);
void    lines_sort(lines_t *lines);
void    lines_print(const lines_t *lines);
void    lines_free(lines_t *lines);

#endif
