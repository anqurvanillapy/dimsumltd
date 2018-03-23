# Monash

Write Shell the monadic way.

* *Bind* operator `>>=` maps to `|`
* *Then* operator `>>` maps to `;`
* Lambda expression like `\x y -> y x` and `\x y -> x y` supported

## Example

### Basic

```bash
$ ./monash "fortune >> echo Meh >>= cowsay"
Don't Worry, Be Happy.
		-- Meher Baba
 _____
< Meh >
 -----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

### Using lambda

```bash
# Swap 2 values.
$ ./monash "echo 1 2 >>= \x y -> y x"
2 1

# Calculation.
$ ./monash "echo 1 2 >>= \x y -> x + y"
3
```

- Notes:
    + Unbound variables are checked in compile-time
    + If arithmetic operators (`+`/`-`/`*`/`/`) are found in lambda expression
    body, evaluation is done in runtime by `$(())` in shell

## Thanks

This project is inspired by
[this blog post](http://okmij.org/ftp/Computation/monadic-shell.html) from
Oleg Kiselyov, who is definitely one of the Agents irl. :)

Some keywords like `done`/`return` are not considered to free the use of some
common commands, e.g. `echo`, `cat`.
