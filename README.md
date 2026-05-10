# Conway's Game of Life

## Purpose

I made this nano-project mainly to learn Zig.

I have thoughts on expanding it to be something actually usable, like a screen saver, but I'm not sure when it is gonna see the light of the day.

## Usage

1. Download a binary from release (or compile from source code),
2. Run it in terminal!

The general syntax is: `<executable> <mode> [options]`

Currently the only available mode is: `run`.

Currently the field is hardcoded.

## Options

- `--help`
    - prints usage message
    - can be specified without mode
- `--steps N`
    - amount of steps that simulation will last for
    - use `-1` for simulation to be endless
    - defaults to `-1`
- `--delay MS`
    - amount of time (in ms) that simulation will wait before evaluating next simulation step
    - this delay is added after rendering and evaluating each generation
    - defaults to `40`
- `--alive-cell TEXT`
    - sets the string used to render an alive cell
    - strings longer than 8192 are not supported. I hope it is not a big problem
    - defaults to `██` (unicode `U+2588`)
- `--dead-cell TEXT`
    - sets the string used to render an dead cell
    - strings longer than 8192 are not supported. I hope it is not a big problem
    - defaults to `  ` (space character)

## Examples

```sh
./life run
./life run --steps -1
./life run --steps 1000 --delay 40
./life run --alive-cell "##" --dead-cell ".."
```
