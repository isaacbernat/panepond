import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';
import "package:range/range.dart";


main() {
  initPolymer().run(() {
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
    Controls.action: KeyCode.CTRL,
  };
  @observable Map<String, num> cursor = {
    "x": 3,
    "y": 3,
    "width": 2,
    "height": 1
  };
  num width = 6; //x
  num height = 12; //y
  @observable List<Column> columns =
      range(0, 6).map((i) => new Column.prefilled(12, 3));
  Board.created() : super.created();
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
