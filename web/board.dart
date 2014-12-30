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
      window.onKeyPress.listen( (e) {
        board1.actOnKeyPress(e.keyCode);
      });
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
  static var rand = new Random();
  @observable Map<String, num> cursor = toObservable({
    "x": 3,
    "y": 3,
    "width": 2,
    "height": 1
  });
  @observable num totalScore = 0;
  num width = 6; //x
  num height = 12; //y
  @observable List<List<Tile>> columns = toObservable(range(0, 6).map((i) => range(0, 12).map((j) => j < 3 ? new Tile(0, i, j) : new Tile(rand.nextInt(6) + 1, i, j))));
  @observable List<List<String>> columnEffects = toObservable(range(0, 6).map((j) => range(0, 12).map((i) => " ")));
  Board.created() : super.created();

  void actOnKeyPress(keyCode) {
    if (!controls.containsValue(keyCode)){
      return;
    }
    if (keyCode ==  controls[Controls.up]) {
      cursor["y"] = max(0, cursor["y"] -1);
    } else if (keyCode == controls[Controls.down]) {
      cursor["y"] = min(height -cursor["height"], cursor["y"] +1);
    } else if (keyCode == controls[Controls.left]) {
      cursor["x"] = max(0, cursor["x"] -1);
    } else if (keyCode == controls[Controls.right]) {
      cursor["x"] = min(width -cursor["width"], cursor["x"] +1);
    }
    else if (keyCode == controls[Controls.action]) {
      Map <String, num> pos1, pos2;
      pos1 = {"x": cursor["x"], "y": cursor["y"]};
      pos2 = {"x": cursor["x"]+1, "y": cursor["y"]};
      swapTiles(pos1, pos2);
      resolveMatches([pos1, pos2]);
    }
  }

  void swapTiles(Map <String, num> pos1, Map <String, num> pos2) {
    num type1 = this.columns[pos1["x"]][pos1["y"]].type;
    num type2 = this.columns[pos2["x"]][pos2["y"]].type;
    this.columns[pos2["x"]][pos2["y"]].type = type1;
    this.columns[pos1["x"]][pos1["y"]].type = type2;
  }

  void resolveMatches(List <Map <String, num>> tiles) {
    var matches = getMatches(tiles, rules);
    num comboScore = max(0, (matches.length - rules["min_matching_length"]) +1);
    totalScore += comboScore;
    showEffects(matches, comboScore).then((tile) => clearEffects(tile));
    clearMatches(matches);
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

  void clearMatches(List <Map <String, num>> tiles) {
    for(var t in tiles) {
      this.columns[t["x"]][t["y"]].type = 0;
    }
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
