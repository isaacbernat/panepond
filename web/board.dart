import 'dart:html';
import 'dart:async';
import 'dart:math';
import 'package:polymer/polymer.dart';
import "package:range/range.dart";
import 'config.dart';
import 'package:color/color.dart';

main() {
  var rng = new Random();
  var col = updateBgColour((new Color.hsl(rng.nextInt(360), 50, 25)).toRgbColor().toHexColor());
  var colourSelector = document.querySelector('.bg');
  colourSelector.value = "#$col";
  colourSelector.onChange.listen((event) => updateBgHex(colourSelector.value));

  initPolymer().run(() {
    // Code that doesn't need to wait.
    Polymer.onReady.then((_) {
      // Code that executes after elements have been upgraded.
      var board1 = querySelector('.player1');
      window.onKeyDown.listen( (e) {
        board1.actOnKeyDown(new String.fromCharCodes([e.keyCode]));
      });
      window.onKeyUp.listen( (e) {
        board1.moveFreeze = -1; //FIXME: WIP multiple pressed keys
      });
      board1.init();
    });
  });
}

class States {
  static const still = const States._(0);
  static const fall = const States._(1);
  static const swap = const States._(2);
  static const dying = const States._(3);

  static get values => [still, fall, swap, dying];
  final int value;
  const States._(this.value);
}

void updateBgHex(hex) => updateBgColour(new Color.hex(hex));

Color updateBgColour(Color colour){
    CssStyleSheet sheet = document.styleSheets[3];  //We want to override existing defaults
    addAndReplaceCssRule(sheet, "header h1", "text-shadow: ${titleTextShadow(colour)};");
    addAndReplaceCssRule(sheet, "body", "background: #$colour;");
    return colour;
}

void addAndReplaceCssRule(sheet, selector, style) {  // Not efficient for batches
  for(num i = sheet.cssRules.length -1; i > 0; i--) {  // reversed loop since we append rules at the end
    if(sheet.rules[i].cssText.startsWith("$selector { ${style.split(':')[0]}")) {
      sheet.removeRule(i);
      break;  // assuming at most one instance of the same 'selector {attribute:'
    }
  }
  sheet.addRule(selector, style, sheet.cssRules.length);
}

String titleTextShadow(color) {
    HslColor colour = color.toHslColor();
    num h = colour.h.round();
    num s = (colour.s/3).round();
    num l = min(80, max(colour.l, 35)).round();
    return "hsl($h, $s%, $l%) 0px 1px 0px, "
           "hsl($h, $s%, $l%) 0px 1px 0px, "
           "hsl($h, $s%, $l%) 0px 2px 0px, "
           "hsl($h, $s%, $l%) 0px 3px 0px, "
           "hsl($h, $s%, $l%) 0px 4px 0px, "
           "rgba(0, 0, 0, 0.2) 0px 5px 1px, "
           "rgba(0, 0, 0, 0.3) 0px 0px 10px, "
           "rgba(0, 0, 0, 0.4) 0px 3px 5px, "
           "rgba(0, 0, 0, 0.5) 0px 6px 5px, "
           "rgba(0, 0, 0, 0.6) 0px 10px 10px";
}

@CustomTag('panepond-board')
class Board extends PolymerElement {
  static var rand = new Random(1234);
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
  void exportConfig() => config.jsonDump = config.export();
  void importConfig() {
    config.import(config.jsonDump);
    init();
  }

  void generateRandomSeed() => config.randomSeed = rand.nextInt(999999).toString();
  void updateRandomSeed() {
    rand = new Random(int.parse(config.randomSeed));
    init();
  }

  void updateKey(num control) {
    window.onKeyDown.first.then((e) {
      config.controls[control] = new String.fromCharCodes([e.keyCode]);
    });
  }
  void updateKeyUp() => updateKey(Controls.up);
  void updateKeyDown() => updateKey(Controls.down);
  void updateKeyRight() => updateKey(Controls.right);
  void updateKeyLeft() => updateKey(Controls.left);
  void updateKeyAction() => updateKey(Controls.action);

  void init() {
    if (Uri.base.queryParameters["mode"] == "normal"){
      config.tiles["mode"]["type"] = "normal";
      config.tiles["colour"]["alpha"] = 1;
    }
    config.loadCSS();
    totalScore = 0;
    var numSymbols = config.tiles["symbols"].length -1;
    columns = toObservable(range(0, config.width).map((i) => range(0, config.height).map((j) => j < 3 ? new Tile("0", i, j) : new Tile((rand.nextInt(numSymbols) +1).toString(), i, j))));
    columnEffects = toObservable(range(0, config.width).map((j) => range(0, config.height).map((i) => " ")));
    leftMarginOffset = config.width * -1;

    List <Map <String, num>> tiles = range(0, config.width*config.height).map((i) => {"x": (i/config.height).floor(), "y": i%config.height});
    var durations = config.delayDurations;
    config.delayDurations = {
      "resolve": new Duration(milliseconds: 0),
      "score_effects": new Duration(milliseconds: 0),
    };
    resolveMatches(tiles, 0, 0)
      .then((_) => restoreDelaysAndScore(durations));
  }

  void restoreDelaysAndScore(durations) {
    config.delayDurations = durations;
    totalScore = 0;
    return;
  }

//TODO: tl;dr Use keyCodes instead of their string conversion.
//For reasom there is `fromCharCodes` but couldn't find anything like `toCharCodes` which worked.
//Hastily tried `charCodeAt` and just `charCodes` much without success.
  void actOnKeyDown(char) {
    if (cursorLock || !config.controls.containsValue(char)) return;

    if (char == config.controls[Controls.up]) {
      moveCursor("y", max(0, cursor["y"] -1), Controls.up);
    } else if (char == config.controls[Controls.down]) {
      moveCursor("y", min(config.height -cursor["height"], cursor["y"] +1), Controls.down);
    } else if (char == config.controls[Controls.left]) {
      moveCursor("x", max(0, cursor["x"] -1), Controls.left);
    } else if (char == config.controls[Controls.right]) {
      moveCursor("x", min(config.width -cursor["width"], cursor["x"] +1), Controls.right);
    }
    else if (char == config.controls[Controls.action]) {
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
    if (t1.state != States.still || t2.state != States.still) return;

    String tmpType = t1.type;
    t1.type = t2.type;
    t1.state = States.swap;
    t2.type = tmpType;
    t2.state = States.swap;
    if(config.effects["swap_effects"]){
      this.columnEffects[t1.x][t1.y] = ">";
      this.columnEffects[t2.x][t2.y] = "<";
    }
  new Future.delayed(config.delayDurations["swap"], () => [[pos1["x"], pos1["y"]], [pos2["x"], pos2["y"]]])
      .then((coordinatesList) => clearEffects(coordinatesList));
    new Future.delayed(config.delayDurations["swap"], () => [t1, t2])
      .then((tiles) => changeState(tiles, States.still));
    new Future.delayed(config.delayDurations["swap"], () => [pos1, pos2])
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions, 1, 0));
    return;
  }

  void changeState(List <Tile> tiles, num state) {
    for(var t in tiles) {
      t.state = state;
    }
  }

  Future resolveMatches(List <Map <String, num>> candidatePositions, num multiplier, num accumScore) {
    List <List <Map <String, num>>> matches = getMatches(candidatePositions);
    if (matches.length == 0) {
      totalScore += accumScore * (multiplier -config.rules["multiplier_increment"]);
      return;
    }

    List <Map <String, num>> tilePositions = matches.expand((i) => i).toList(); // flatten
    if (multiplier == 1) { // the first match treats all tilePositions as the same "combo"
      accumScore = config.rules["scores"][tilePositions.length.toString()];  // TODO it'd be nicer with nums
      scoreEffects(tilePositions, accumScore, multiplier).then((tiles) => clearEffects(tiles));
      multiplier += config.rules["multiplier_increment"];
    } else { // in a cumulative combo, combinations score on their own (and add to the multiplier)
      for (var m in matches) {
        num comboScore = config.rules["scores"][m.length.toString()];
        accumScore += comboScore;
        scoreEffects(m, comboScore, multiplier).then((tiles) => clearEffects(tiles));
        multiplier += config.rules["multiplier_increment"];
      }
    }

    List <Tile> tiles = tilePositions.map((t) => this.columns[t["x"]][t["y"]]);
    changeState(tiles, States.dying);
    new Future.delayed(config.delayDurations["resolve"], () => tiles)
      .then((tiles) => changeState(tiles, States.still));

    return clearMatches(matches)
      .then((positions) => gravity(positions))
      .then((positions) => resolveMatches(positions, multiplier, accumScore));
  }

  List <List<Map <String, num>>> getMatches(List <Map <String, num>> tiles) { //TODO: scan only needed elements
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
        String prevType = "-1";
        List <Map <String, num>> accumTiles = [];
        for(var c in candidates){
          if (c.type == prevType && c.type != "0") { //TODO: use states
            accumTiles.add({"x": c.x, "y": c.y});
          } else {
            if (accumTiles.length >= config.rules["min_matching_length"]) {
              matchedTiles.add(accumTiles);
            }
            accumTiles = [{"x": c.x, "y": c.y}];
            prevType = c.type;
          }
        }
        if (accumTiles.length >= config.rules["min_matching_length"]) {
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
        this.columns[tile["x"]][tile["y"]].type = "0";
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
        if(this.columns[c][i].type == "0" && this.columns[c][i].state == States.still) {
          String highestType = "0";
          for (var j = i; j > 1; j--) {
            highestType = highestType != "0"? highestType : this.columns[c][j-1].type;
            this.columns[c][j].type = this.columns[c][j-1].type;
          }
          if(highestType != "0") {
            this.columns[c][0].type = "0";
            gravity([{"x": c}]); //TODO: non-instant gravity?
            gravityPositions.add({"x": c, "y": i});
          }
          break;
        }
      }
    }
    return positions..addAll(gravityPositions);
  }

  Future scoreEffects(List <Map <String, num>> tiles, num comboScore, num multiplier) {
    if(!config.effects["score_effects"] || (comboScore == 0 && multiplier == 1)){
      return new Future(() => [[-1, -1]]);
    }
    List<List<num>> coordinatesToClean = [];
    var centerTile = tiles[(tiles.length/2).floor()]; // TODO: use a centering algorithm
    String effect;
    if (multiplier > 1){
      effect = "x$multiplier";
    } else {
      effect = "+$comboScore";
    }
    for(var t in tiles){
      this.columnEffects[t["x"]][t["y"]] = "*";
      coordinatesToClean.add([t["x"], t["y"]]);
    }
    this.columnEffects[centerTile["x"]][centerTile["y"]] = effect;
    return new Future.delayed(config.delayDurations["score_effects"], () => coordinatesToClean);
  }

  void clearEffects(List<List<num>> coordinatesList) {
    for (var coordinates in coordinatesList) {
       if (coordinates[0] > -1) {
         this.columnEffects[coordinates[0]][coordinates[1]] = " ";
       }
    }
  }
}

class Tile extends Observable {
  @observable String type;
  @observable num x;
  @observable num y;
  num state = States.still;
  Tile(index, x, y) : type = index, x = x, y = y;
}
