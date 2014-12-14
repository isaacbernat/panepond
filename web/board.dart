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

// enum Controls { //TODO use enums: experimental in dart 1.8.0
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
    Controls.action: KeyCode.P,
  };
  @observable  Map<String, num> cursor = toObservable({
    "x": 3,
    "y": 3,
    "width": 2,
    "height": 1
  });
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
      String x1 = cursor["x"].toString();
      String x2 = (cursor["x"] +1).toString();
      String y = cursor["y"].toString();
      swapTiles(x1, y, x2, y);
    }
  }

  void swapTiles(String x1, String y1, String x2, String y2) {
    var tile1 =  this.shadowRoot.querySelector('.board.ti [pos="' + x1 + ',' + y1 + '"]');
    var tile2 =  this.shadowRoot.querySelector('.board.ti [pos="' + x2 + ',' + y2 + '"]');
    var aux1 = new DivElement(); //TODO: find a better way to deep-copy
    aux1.appendHtml(tile1.innerHtml);
    aux1.attributes = tile1.attributes;
    aux1.attributes["pos"] = tile2.attributes["pos"]; //TODO: use XPath instead of this hack
    var aux2 = new DivElement();
    aux2.appendHtml(tile2.innerHtml);
    aux2.attributes = tile2.attributes;
    aux2.attributes["pos"] = tile1.attributes["pos"];

    tile1.replaceWith(aux2);
    tile2.replaceWith(aux1);
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
