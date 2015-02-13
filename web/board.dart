import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';
import "package:range/range.dart";
import 'config.dart';


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
  static const up = 0;
  static const down = 1;
  static const left = 2;
  static const right = 3;
  static const action = 4;

  static get values => [up, down, left, right, action];
  final int value;
  const Controls._(this.value);
}


class States {
  static const still = const States._(0);
  static const fall = const States._(1);
  static const swap = const States._(2);

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
  @observable Map<num, String> controlsChars = toObservable( {
    Controls.up: "I",
    Controls.down: "K",
    Controls.left: "J",
    Controls.right: "L",
    Controls.action: "Q",
  });
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
  @observable Config config = new Config(6, 12, "40");

  @observable List<List<Tile>> columns;
  @observable List<List<String>> columnEffects;
  Board.created() : super.created();
  @observable num leftMarginOffset;

  void toggleConfig() => config.display == "none" ? config.display = "block" : config.display = "none";
  void updateDelays() {
    config.delays.forEach((k, v) => config.delayDurations[k] = new Duration(seconds: int.parse(v)));
    init();
  }

  void updateConfig() {
    config.height = int.parse(config.inputHeight);
    config.width = int.parse(config.inputWidth);
    init();
  }

  void updateKey(num control) {
    window.onKeyDown.first.then((e) {
      controls[control] = e.keyCode;
      controlsChars[control] = new String.fromCharCodes([e.keyCode]);
    });
  }

  void updateKeyUp() => updateKey(Controls.up);
  void updateKeyDown() => updateKey(Controls.down);
  void updateKeyRight() => updateKey(Controls.right);
  void updateKeyLeft() => updateKey(Controls.left);
  void updateKeyAction() => updateKey(Controls.action);

  void init() {
    totalScore = 0;
    columns = toObservable(range(0, config.width).map((i) => range(0, config.height).map((j) => j < 3 ? new Tile(0, i, j) : new Tile(rand.nextInt(6) + 1, i, j))));
    columnEffects = toObservable(range(0, config.width).map((j) => range(0, config.height).map((i) => " ")));
    leftMarginOffset = config.width * -1;
    resolveMatchesInit();
  }

  void actOnKeyDown(keyCode) {
    if (cursorLock || !controls.containsValue(keyCode)) return;

    if (keyCode == controls[Controls.up]) {
      moveCursor("y", max(0, cursor["y"] -1), Controls.up);
    } else if (keyCode == controls[Controls.down]) {
      moveCursor("y", min(config.height -cursor["height"], cursor["y"] +1), Controls.down);
    } else if (keyCode == controls[Controls.left]) {
      moveCursor("x", max(0, cursor["x"] -1), Controls.left);
    } else if (keyCode == controls[Controls.right]) {
      moveCursor("x", min(config.width -cursor["width"], cursor["x"] +1), Controls.right);
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
    new Future.delayed(config.delayDurations["swap"], () => [pos1, pos2])
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions, 1, 0));
    new Future.delayed(config.delayDurations["resolve"], () => [t1, t2])
      .then((tiles) => changeState(tiles, States.still));
    return;
  }

  void changeState(List <Tile> tiles, num state) {
    for(var t in tiles) {
      t.state = state;
    }
  }

  void resolveMatchesInit() { //FIXME: this is very naive -- but it is only run at init
    List <Map <String, num>> tiles = range(0, config.width*config.height).map((i) => {"x": (i/config.height).floor(), "y": i%config.height});
    var matches = getMatches(tiles, rules);
    if (matches.length == 0) return;

    for(var m in matches) {
      for(var tile in m) {
        this.columns[tile["x"]][tile["y"]].type = 0;
      }
      gravity(m);
    }
    resolveMatchesInit();
  }

  void resolveMatches(List <Map <String, num>> tiles, num multiplier, num accumScore) {
    var matches = getMatches(tiles, rules);
    if (matches.length == 0) {
      totalScore += accumScore * (multiplier -1);
      return;
    }

    if (multiplier == 1) { // the first match treats all tiles as the same "combo"
      tiles = matches.expand((i) => i).toList(); // flatten
      accumScore = tiles.length == rules["min_matching_length"]? 2:tiles.length;
      showEffects(tiles, accumScore, multiplier++).then((tile) => clearEffects(tile));
    } else { // in a cumulative combo, combinations score on their own (and add to the multiplier)
      for (var m in matches) {
        num comboScore = m.length == rules["min_matching_length"]? 2:m.length;
        accumScore += comboScore;
        showEffects(m, comboScore, multiplier++).then((tile) => clearEffects(tile));
      }
    }

    clearMatches(matches)
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions, multiplier, accumScore));
  }

  List <List<Map <String, num>>> getMatches(List <Map <String, num>> tiles, rules) { //TODO: scan only needed elements
    Map <String, bool> scanned = {};
    var matchedTiles = [];
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
              matchedTiles.add(accumTiles);
            }
            accumTiles = [{"x": c.x, "y": c.y}];
            prevType = c.type;
          }
        }
        if (accumTiles.length >= rules["min_matching_length"]) {
          matchedTiles.add(accumTiles);
        }
      }
    }
    return matchedTiles;
  }

  Future clearMatches(List <List <Map <String, num>>> matches) {
    List <Map <String, num>> tiles = [];
    for (var m in matches) {
      for(var tile in m) {
        this.columns[tile["x"]][tile["y"]].type = 0;
      }
      tiles.addAll(m);
    }
    return new Future.delayed(config.delayDurations["resolve"], () => tiles);
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

  Future showEffects(List <Map <String, num>> tiles, num comboScore, num multiplier) {
    if(comboScore == 0 && multiplier == 1){
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
    String effect;
    if (multiplier > 1){
      effect = "x" + multiplier.toString();
    } else {
      effect = "+" + comboScore.toString();
    }
    this.columnEffects[minX][minY] = effect;
    return new Future.delayed(config.delayDurations["effects"], () => [minX, minY]);
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
