# Nim

Misère Nim built in Godot 4. The player forced to take the last pearl loses.

## Rules

- Four rows of pearls: 2, 3, 5, 7
- On your turn, click any number of pearls in a single row, then confirm
- The player who takes the last pearl **loses**

## Difficulty

| Level | Behaviour |
|---|---|
| Easy | 25% optimal play, 75% random |
| Medium | 60% optimal play, 40% random |
| Hard | Always plays optimally — good luck |

Difficulty can only be changed before the first move of each game.

## Building

Requires [Godot 4.4+](https://godotengine.org/) with export templates installed.

Export presets are included for macOS (universal), Windows (x86_64), and Web (WASM).
