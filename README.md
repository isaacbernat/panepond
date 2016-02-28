panepond: Panel de Pon with D(art)
==================================
panepond aim is to become a *[panepon](http://en.wikipedia.org/wiki/Yoshi%27s_Panepon)/[panel de pon](http://en.wikipedia.org/wiki/Tetris_Attack#Panel_de_Pon)/[tetris attack](http://en.wikipedia.org/wiki/Tetris_Attack)/[crack attack](http://www.aluminumangel.org/attack/)* clone with major improvements. The development is stalled ATM, but there is a [WIP version live](http://isaacbernat.github.io/panepond/) you may try. It supports [different flavoured themes](http://isaacbernat.github.io/panepond/?mode=normal).

<div style="text-align:center">
<a href="http://isaacbernat.github.io/panepond/">
<img src="https://github.com/isaacbernat/panepond/blob/master/docs/8-bit-theme.png?raw=true" alt="Gameplay screenshot showcasing 8-bit theme" width="411px" height="671px">
</a>
<a href="http://isaacbernat.github.io/panepond/?mode=normal">
<img src="https://github.com/isaacbernat/panepond/blob/master/docs/flower-theme.png?raw=true" alt="Gameplay screenshot showcasing flower theme" width="452px" height="692px"></a>
</div>

For a semi-detailed list of features check [version section](#versions)

Run this
--------
1. Compile Sass into CSS `sass --update web --stop-on-error --no-cache --style compressed`
2. Compile Jade into HTML `jade web`
3. Run it! `pub serve`
4. Browse it `http://localhost:8080/` on your favourite web browser

Why?
----
Despite preferring backend stuff I wanted to try out modern alternatives to JavaScript, CSS and HTML to build a webapp.
After looking around I decided on [Dart](https://www.dartlang.org/) (+ [Polymer](https://www.dartlang.org/polymer/)), [Sass](http://sass-lang.com/) and [Jade](http://jade-lang.com/).

**Note:** Since I am a n00b at this I may not be using them at full power, or even making silly mistakes (e.g. why would I ever use the DOM instead of the canvas?). Suggestions are welcome :)

TODOs (in no specific order)
-----
- tests
- versus mode on one window (N players)
- versus mode on different machines (N players)
- time attack mode
- Artifical Intelligences (pluggable)
- save replay
- etc.

Versions
--------
I'll try to keep some "noteworhty" versions listed here. I'll try to produce incremental updates, so you can check out how the code base (and panepond) looked at some point in time. This way, anybody can see the evolution or try to learn some of the technologies used by looking at the project at earlier smaller/simpler stages.

The format will be: version number, github hash, small description of main features

- 0.2.0: [e92ccb0b61812c7469007626782eae2a4c71f630](https://github.com/isaacbernat/panepond/tree/e92ccb0b61812c7469007626782eae2a4c71f630)
  - bug fixes
  - configurable UI (tile symbols, colours, size, etc.)
  - configurable controls (direction and action keys)
  - configurable gameplay mechanics (cursor move time, delay to resolve matches, etc.)
  - configurable game board (dimensions, number of tiles, etc.)
  - configurable scoring (combo values, multiplier increase rate, etc.)
  - import and export configurations in JSON

- 0.1.0: [0927349c87c9bc96fdcd2a02c6c9c6cdcd98cd10](https://github.com/isaacbernat/panepond/tree/0927349c87c9bc96fdcd2a02c6c9c6cdcd98cd10)
  - single player
  - classic fixed layout(12x6 tiles board, 6 different kinds of tiles, 2-length cursor, etc.)
  - cumulative multipliers and "bonus" for >3-length combos
  - 'instant' gravity
  - fixed basic controls (movement + action)
