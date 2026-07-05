# Puppyflat

Build instructions
---

* [Download and install Love2D](https://love2d.org/)
* Alias or symlink the `love` command to `/Applications/love.app/Contents/MacOS/love`
* Run `love .` on this directory

Automated playtest
---

Run `love . --playtest` (or `--playtest=SECONDS`) to have the game play
itself with audio muted: it starts the game, hops on a timer, logs position
and score to stdout, and saves periodic screenshots to the Love2D save
directory (printed at startup).
