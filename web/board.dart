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
  @observable  Map<String, num> cursor = toObservable({
    "x": 3,
    "y": 3,
    "width": 2,
    "height": 1
  });
  @observable num totalScore = 0;
  num width = 6; //x
  num height = 12; //y
  @observable List<Column> columns =
      range(0, 6).map((i) => new Column.prefilled(12, 3));
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
      Map <String, num> t1 = {"x": cursor["x"], "y": cursor["y"]};
      Map <String, num> t2 = {"x": cursor["x"] +1, "y": cursor["y"]};
      swapTiles(t1, t2);
      resolveMatches([t1, t2]);
    }
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
        String pos = (axis == "x")? '[pos^="' + t[axis].toString() + ',"]' : '[pos\$=",' + t[axis].toString() + '"]';
        var candidates = this.shadowRoot.querySelectorAll('.board.ti ' + pos);
        String prevClass = "";
        var accum = [];
        for(var c in candidates){
          if (c.attributes["state"] == "full" && c.className == prevClass) {
            accum.add(c);
          } else {
            if (accum.length >= rules["min_matching_length"]) {
              matchedTiles.addAll(accum);
            }
            accum = [c];
            prevClass = c.className;
          }
        }
        if (accum.length >= rules["min_matching_length"]) {
          matchedTiles.addAll(accum);
        }
      }
    }
    return matchedTiles;
  }

  void clearEffects(Node effectTile) {
    if(effectTile != null){
      effectTile.innerHtml = "";
    }
  }

  Future showEffects(List <Map <String, num>> tiles, comboScore) {
    if(comboScore == 0){
      return new Future(() => null);
    }
    num maxX = 0, minX = 9999, maxY = 0, minY = 9999; //TODO: non-magic numbers
    var positions = tiles.map((t) => t.attributes["pos"]);
    for(var p in positions){
      var coordinates = p.split(",");
      maxX = max(maxX, int.parse(coordinates[0]));
      minX = min(minX, int.parse(coordinates[0]));
      maxY = max(maxY, int.parse(coordinates[1]));
      minY = min(minY, int.parse(coordinates[1]));
    }
    if ((maxY == minY) || (maxX == minX)) { //TODO: better "centering" algorithm
      minX = ((minX+maxX)/2).floor();
      minY = ((minY+maxY)/2).floor();
    }
    String pos = '[pos="' + minX.toString() + "," + minY.toString() + '"]';
    Node effectTile = this.shadowRoot.querySelector('.board.ef ' + pos);
    effectTile.innerHtml = '+' +comboScore.toString();
    return new Future.delayed(const Duration(seconds: 1), () => effectTile);
  }

  void clearMatches(List <Map <String, num>> tiles) {
    for(var t in tiles) {
      t.className = "tile type0";
      t.innerHtml = "";
      t.attributes["state"] = "empty";
    }
    return;
  }

  void swapTiles(Map <String, num> tile1, Map <String, num> tile2) {
    var t1 =  this.shadowRoot.querySelector('.board.ti [pos="' + tile1["x"].toString() + ',' + tile1["y"].toString() + '"]');
    var t2 =  this.shadowRoot.querySelector('.board.ti [pos="' + tile2["x"].toString() + ',' + tile2["y"].toString() + '"]');
    var aux1 = new DivElement() //TODO: find a better way to deep-copy
      ..appendHtml(t1.innerHtml)
      ..attributes = t1.attributes
      ..attributes["pos"] = t2.attributes["pos"]; //TODO: use XPath or :nth-child(n) instead of this hack?
    var aux2 = new DivElement()
      ..appendHtml(t2.innerHtml)
      ..attributes = t2.attributes
      ..attributes["pos"] = t1.attributes["pos"];

    t1.replaceWith(aux2);
    t2.replaceWith(aux1);
  }
}


class Column {
  static var rand = new Random();
  List<Tile> tiles;
  Column.prefilled(num total, num top_empty) {
    this.tiles = range(0, total).map(
            (i) => i < top_empty ? new Tile("0") : new Tile(rand.nextInt(6) + 1));}
  Column(List tiles) {
    this.tiles = tiles.map((t) => new Tile(t));
  }
}


class Tile {
  num type;
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

  Tile(letter) : type = letter;
}
