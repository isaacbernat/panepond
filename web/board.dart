import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';
import "package:range/range.dart";


main() {
  initPolymer().run(() {
    // Code that doesn't need to wait.
    Polymer.onReady.then((_) {
      // Code that executes after elements have been upgraded.
      var board1 = querySelector('.player1');
      window.onKeyDown.listen( (e) {
        board1.actOnKeyDown(e.keyCode);
      });
      window.onKeyUp.listen( (e) {
        board1.moveFreeze = -1; //FIXME: WIP multiple pressed keys
      });
      board1.init();
    });
  });
}


// enum Controls { //TODO use enums: new in dart 1.8.0. Got some issues :-/
//     up, down, left ,right, action
// }
class Controls {
  static const up = const Controls._(0);
  static const down = const Controls._(1);
  static const left = const Controls._(2);
  static const right = const Controls._(3);
  static const action = const Controls._(4);

  static get values => [up, down, left, right, action];
  final int value;
  const Controls._(this.value);
}


class States {
  static const still = const Controls._(0);
  static const fall = const Controls._(1);
  static const swap = const Controls._(2);

  static get values => [still, fall, swap];
  final int value;
  const States._(this.value);
}


@CustomTag('panepond-board')
class Board extends PolymerElement {
  Map<num, num> controls = { // all caps!
    Controls.up: KeyCode.I,
    Controls.down: KeyCode.K,
    Controls.left: KeyCode.J,
    Controls.right: KeyCode.L,
    Controls.action: KeyCode.Q,
  };
  Map rules = {
    "min_matching_length": 3,
  };
  static var rand = new Random(); //Random(1234); //a fixed seed for debugging purposes
  @observable Map<String, num> cursor = toObservable({
    "x": 3,
    "y": 3,
    "width": 2,
    "height": 1
  });
  bool cursorLock = false;
  num moveFreeze = -1;
  @observable num totalScore = 0;
  num width = 6; //x
  num height = 12; //y
  @observable List<List<Tile>> columns;
  @observable List<List<String>> columnEffects;
  Board.created() : super.created();

  void init() {
    columns = toObservable(range(0, width).map((i) => range(0, height).map((j) => j < 3 ? new Tile(0, i, j) : new Tile(rand.nextInt(6) + 1, i, j))));
    columnEffects = toObservable(range(0, 6).map((j) => range(0, 12).map((i) => " ")));
    resolveMatchesInit();
  }

  void actOnKeyDown(keyCode) {
    if (cursorLock || !controls.containsValue(keyCode)) return;

    if (keyCode == controls[Controls.up]) {
      moveCursor("y", max(0, cursor["y"] -1), Controls.up);
    } else if (keyCode == controls[Controls.down]) {
      moveCursor("y", min(height -cursor["height"], cursor["y"] +1), Controls.down);
    } else if (keyCode == controls[Controls.left]) {
      moveCursor("x", max(0, cursor["x"] -1), Controls.left);
    } else if (keyCode == controls[Controls.right]) {
      moveCursor("x", min(width -cursor["width"], cursor["x"] +1), Controls.right);
    }
    else if (keyCode == controls[Controls.action]) {
      Map <String, num> pos1, pos2;
      pos1 = {"x": cursor["x"], "y": cursor["y"]};
      pos2 = {"x": cursor["x"]+1, "y": cursor["y"]};
      swapTiles(pos1, pos2);
    }
  }

  void moveCursor(String axis, num value, num move) {
    if(moveFreeze == move) return;

    moveFreeze = move;
    cursor[axis] = value;
    return;
  }

  void setCursorLock(bool state) {
    cursorLock = state;
  }

  void swapTiles(Map <String, num> pos1, Map <String, num> pos2) {
    Tile t1 = this.columns[pos1["x"]][pos1["y"]];
    Tile t2 = this.columns[pos2["x"]][pos2["y"]];
    if (t1.state != States.still && t2.state != States.still) return;

    num tmpType = t1.type;
    t1.type = t2.type;
    t1.state = States.swap;
    t2.type = tmpType;
    t2.state = States.swap;
    new Future.delayed(const Duration(seconds: 1), () => [pos1, pos2])
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions));
    new Future.delayed(const Duration(seconds: 1), () => [t1, t2])
      .then((tiles) => changeState(tiles, States.still));
    return;
  }

  void changeState(List <Tile> tiles, num state) {
    for(var t in tiles) {
      t.state = state;
    }
  }

  void resolveMatchesInit() { //FIXME: this is very naive -- but it is only run at init
    List <Map <String, num>> tiles = range(0, width*height).map((i) => {"x": (i/height).floor(), "y": i%height});
    var matches = getMatches(tiles, rules);
    if (matches.length == 0) return;

    for(var m in matches) {
      this.columns[m["x"]][m["y"]].type = 0;
    }
    gravity(matches);
    resolveMatchesInit();
  }

  void resolveMatches(List <Map <String, num>> tiles) {
    var matches = getMatches(tiles, rules);
    if (matches.length == 0) return;

    num comboScore = max(0, (matches.length - rules["min_matching_length"]) +1);
    totalScore += comboScore;
    showEffects(matches, comboScore).then((tile) => clearEffects(tile));
    clearMatches(matches)
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions));
  }

  List getMatches(List <Map <String, num>> tiles, rules) { //TODO: scan only needed elements
    Map <String, bool> scanned = {};
    var matchedTiles = new Set();
    for(var t in tiles) {
      for(var axis in t.keys) {
        if (scanned.containsKey(axis + t[axis].toString())) {
          continue; //optimisation, don't scan more than once the same line
        }
        scanned[axis + t[axis].toString()] = true;
        List <Tile> candidates;
        if (axis == "x") {
          candidates = this.columns[t["x"]];
        } else /* if (axis == "y") */{
          candidates = this.columns.map((col) => col[t["y"]]);
        }
        num prevType = -1;
        List <Map <String, num>> accumTiles = [];
        for(var c in candidates){
          if (c.type == prevType && c.type > 0) { //TODO: use states
            accumTiles.add({"x": c.x, "y": c.y});
          } else {
            if (accumTiles.length >= rules["min_matching_length"]) {
              matchedTiles.addAll(accumTiles);
            }
            accumTiles = [{"x": c.x, "y": c.y}];
            prevType = c.type;
          }
        }
        if (accumTiles.length >= rules["min_matching_length"]) {
          matchedTiles.addAll(accumTiles);
        }
      }
    }
    return matchedTiles;
  }

  Future clearMatches(List <Map <String, num>> tiles) {
    for(var t in tiles) {
      this.columns[t["x"]][t["y"]].type = 0;
    }
    return new Future.delayed(const Duration(seconds: 1), () => tiles);
  }

  List <Map <String, num>> gravity(List <Map <String, num>> positions) {
    List <num> columns = positions.map((pos) => pos["x"]);
    num len = this.columns[0].length; //TODO: use a constant
    List <Map <String, num>> gravityPositions = [];
    for(var c in columns) {
      for (var i = len -1; i > 0; i--) {
        if(this.columns[c][i].type == 0) {
          num highestType = 0;
          for (var j = i; j > 1; j--) {
            highestType = max(highestType, this.columns[c][j-1].type);
            this.columns[c][j].type = this.columns[c][j-1].type;
          }
          if(highestType > 0) {
            this.columns[c][0].type = 0;
            gravity([{"x": c}]); //TODO: non-instant gravity?
            gravityPositions.add({"x": c, "y": i});
          }
          break;
        }
      }
    }
    return positions..addAll(gravityPositions);
  }

  Future showEffects(List <Map <String, num>> tiles, comboScore) {
    if(comboScore == 0){
      return new Future(() => [-1, -1]);
    }
    num maxX = 0, minX = 9999, maxY = 0, minY = 9999; //TODO: non-magic numbers
    for(var t in tiles){
      maxX = max(maxX, t["x"]);
      minX = min(minX, t["x"]);
      maxY = max(maxY, t["y"]);
      minY = min(minY, t["y"]);
    }
    if ((maxY == minY) || (maxX == minX)) { //TODO: better "centering" algorithm
      minX = ((minX+maxX)/2).floor();
      minY = ((minY+maxY)/2).floor();
    }
    this.columnEffects[minX][minY] = '+' + comboScore.toString();
    return new Future.delayed(const Duration(seconds: 1), () => [minX, minY]);
  }

  void clearEffects(List<num> coordinates) {
    if (coordinates[0] > -1) {
      this.columnEffects[coordinates[0]][coordinates[1]] = " ";
    }
  }
}

class Tile extends Observable {
  @observable num type;
  @observable num x;
  @observable num y;
  String effect = " ";
  num state = States.still;
  Map<int, String> symbols = {
    0: " ",
    1: "♠",
    2: "♥",
    3: "♦",
    4: "♣",
    5: "★",
    6: "■"
  };

  Tile(number, x, y) : type = number, x = x, y = y;
}
