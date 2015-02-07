panepond: Panel de Pon with D(art)
==================================
Features
--------
ATM this is very WIP. Just displaying a grid randomly filled with tiles and a moveable cursor where you can make combos and get points.

Run this
--------
1. Compile Sass into CSS `sass --update web --stop-on-error --no-cache --style compressed`
2. Compile Jade into HTML `jade web`
3. Run it! `pub serve`
4. Browse it `http://localhost:8080/` on your favourite web browser

Why?
----
Despite preferring backend stuff I wanted to try out modern alternatives to JavaScript, CSS and HTML to build a webapp.
After looking around I decided on [Dart](https://www.dartlang.org/) (+ [Polymer](https://www.dartlang.org/polymer/)), [Sass](http://sass-lang.com/) and [Jade](http://jade-lang.com/). I thought a *panepon/panel de pon/tetris attack/crack attack* inspired game could be fun.

**Note:** Since I am a n00b at this I may not be using them at full power, or even making silly mistakes (e.g. why would I ever use the DOM instead of the canvas?). Suggestions are welcome :)

TODOs
-----
- tests
- versus mode on one window (N players)
- versus mode on different machines (N players)
- time attack mode
- AIs (pluggable)
- save replay
- configurability (user keys, random seed, grid size, scoring system, etc.)
- etc.

Versions
--------
I'll try to keep some "noteworhty" versions listed here. I'll try to produce incremental updates, so you can check out how the code base (and panepond) looked at some point in time. This way, anybody can see the evolution or try to learn some of the technologies used by looking at the project at earlier smaller/simpler stages.

The format will be: version number, github hash, small description of main features

- 0.1.0: [9b9d3254b8ed98ec9c2d5a7227ce66078c1c11b4](https://github.com/isaacbernat/panepond/tree/9b9d3254b8ed98ec9c2d5a7227ce66078c1c11b4)
  - single player
  - classic fixed layout(12x6 tiles board, 6 different kinds of tiles, 2-length cursor, etc.)
  - cumulative multipliers and "bonus" for >3-length combos
  - 'instant' gravity
  - fixed basic controls (movement + action)
