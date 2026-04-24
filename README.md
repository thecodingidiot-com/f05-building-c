# f05 — Building C

Companion repository for the **[f05 — Building C](https://thecodingidiot.com/chapters/f05-building-c)** chapter on [thecodingidiot.com](https://thecodingidiot.com).

---

## Follow my journey

You are working through the implementation pages. The chapter walks you
through writing a small `sort` utility in a single file, then debugging
and refactoring it into a multi-file project with a Makefile.

By the end you should have these files in your `f05-practice`
directory:

```bash
Makefile  sort.c  lines.c  lines.h
```

Copy the tester in and run it:

```bash
git clone https://github.com/thecodingidiot-com/f05-building-c.git
cp f05-building-c/test.sh ~/f05-practice/
cd ~/f05-practice
bash test.sh
```

Use `bash test.sh --help` to see what each check verifies.

---

## Follow your journey

You are building it independently. The starting point is a single-file
buggy `sort.c` with three planted bugs (one segfault, one memory leak,
one off-by-one buffer overflow). Your task is to fix them, split the
code into headers and multiple `.c` files, and write a Makefile to
build the project.

```bash
git clone https://github.com/thecodingidiot-com/f05-building-c.git
mkdir ~/f05-practice
cp f05-building-c/broken/sort.c ~/f05-practice/
cp f05-building-c/test.sh ~/f05-practice/
cd ~/f05-practice
```

Use `gcc`, `gdb`, `valgrind`, and `gcc -fsanitize=address
-fsanitize=undefined` to find and fix the bugs. Then refactor into
`sort.c` + `lines.c` + `lines.h` and write a `Makefile`. Run the
tester to verify.

The reference solution lives in `solution/` if you want to compare
once you are done.

---

## What the tester checks

1. `make` builds the project cleanly with no warnings.
2. `./sort` produces correctly sorted output for a sample input.
3. `./sort` runs clean under `valgrind --leak-check=full`.
4. A rebuild with `-fsanitize=address -fsanitize=undefined` runs
   clean on the same input.

The tester does not check that you found the bugs in any particular
order, or that you used any specific tool — only that the final
project is clean.

---

## License

[GPLv2](LICENSE) — the tester code and reference solution are free to
read, modify, and redistribute under the same terms.
