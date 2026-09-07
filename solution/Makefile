NAME    = sort
CC      = gcc
CFLAGS  = -Wall -Wextra -Werror -std=c99
BUILD   = -g -O0
RELEASE = -O2
SRCS    = sort.c lines.c
OBJS    = $(SRCS:.c=.o)

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(BUILD) -o $(NAME) $(OBJS)

%.o: %.c lines.h
	$(CC) $(CFLAGS) $(BUILD) -c $< -o $@

release:
	@$(MAKE) --no-print-directory fclean
	@$(MAKE) --no-print-directory BUILD="$(RELEASE)"
	strip $(NAME)

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all release clean fclean re
