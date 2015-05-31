import 'package:polymer/polymer.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';


class Config extends Observable {
    @observable String tileSize;
    @observable String display = "none";
    @observable Map <String, num> delays = toObservable({
      "swap": "120",
      "resolve": "1800",
      "score_effects": "1800",
    });
    @observable String randomSeed = "1234";
    num height;
    num width;
    Map <String, Duration> delayDurations = {
      "swap": new Duration(milliseconds: 120),
      "resolve": new Duration(milliseconds: 1800),
      "score_effects": new Duration(milliseconds: 1800),
    };
    @observable String jsonDump = "";
    Map rules = {
      "min_matching_length": 3,
      "scores": {
        "3": 2, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
        "11": 11, "12": 12, "13": 13, "14": 14,
      },
      "multiplier_increment": 1,
    };
    Map tiles = {
      "symbols": {"0": " ", "1": "♠", "2": "♥", "3": "♦", "4": "♣", "5": "★", "6": "■"},
      "colour": {
        "hue": {"0": 0, "1": 0, "2": 60, "3": 120, "4": 180, "5": 240, "6": 300},
        "saturation": 50,
        "lightness": 50,
        "alpha": 0.75,
        "randomise-hue": true,
      },
      "mode": {
        "type": "tetris",
        "variant": 3,
        "override_colour": false,
      },
      "font": {
        "hue": 0,
        "saturation": 0,
        "lightness": 100,
        "alpha": 0.35,
        "family": "Kalocsai",
        "randomise-symbols": "abcdefghijklmnopqrstuvwxyz0123456789",
        "force-symbols": {"0": " "}
      },
      "cursor": {
        "background-color": "hsla(0, 0%, 100%, 0.5)",
        "outline": "0.2em dashed lightgray",
        "outline-offset": "-0.1em"
      }
    };
    Map effects = {
      "score_effects": true,
      "resolve_effects": true, //TODO this is going to be updated with more complex/custom stuff
      "swap_effects": true, //TODO this is going to be updated with more complex/custom stuff
    };

    @observable Map<num, String> controls = toObservable( {
      Controls.up: "I",
      Controls.down: "K",
      Controls.left: "J",
      Controls.right: "L",
      Controls.action: "Q",
    });

    Config(w, h, ts) : width = w, height = h, tileSize = ts;

    void randomiseSymbols(bool noSymbols){
      if(tiles['font']["randomise-symbols"] == null) {
        return;
      }
      var rng = new Random();
      List<String> symbolPool = tiles['font']["randomise-symbols"].split(''); //must be at least as long as symbols
      if (noSymbols) {
        symbolPool = [];
      }
      Map <String, String> newSymbols = {};
      tiles["symbols"].forEach((k,v){
        newSymbols[k] = symbolPool.length >0?symbolPool.removeAt(rng.nextInt(symbolPool.length)):" ";
        });
      if(tiles['font'].containsKey("force-symbols")){
        tiles['font']["force-symbols"].forEach((k, v) {
          newSymbols[k] = v;
          });
      }
      tiles["symbols"] = newSymbols;
    }

    void loadCSS() {
        StyleElement styleElement = new StyleElement();
        document.querySelector('panepond-board.player1').shadowRoot.append(styleElement);
        CssStyleSheet sheet = styleElement.sheet;
        List <String> cssRules = [];
        tiles['cursor'].forEach((k, v) {
            cssRules.add("$k: $v;");
        });
        sheet.insertRule('.tile.cursor {${cssRules.join('\n')}}', sheet.cssRules.length);

        var symbolRules = {};
        tiles['symbols'].forEach((k, v) {
          symbolRules[k] = {"colour": {}, "font": {}};
        });
        tiles['colour'].forEach((k, v) {
          if(v is Map<String, num>){
            v.forEach((symbol, value) {
              symbolRules[symbol]['colour'][k] = value;
            });
          } else {
            for(var symbol in tiles['symbols'].keys) {
              symbolRules[symbol]['colour'][k] = v;
            }
          }
        });

        tiles['font'].forEach((k, v) {
          if(v is Map<String, num>){
            v.forEach((symbol, value) {
              symbolRules[symbol]['font'][k] = value;
            });
          } else {
            for(var symbol in tiles['symbols'].keys) {
              symbolRules[symbol]['font'][k] = v;
            }
          }
        });

        if(tiles['colour'].containsKey("randomise-hue")) {
          var rng = new Random();
          num currentHue = rng.nextInt(360);
          num increment = (360 / (symbolRules.length -1)).round();  //ignore the empty tile
          symbolRules.forEach((k, v) {
            symbolRules[k]["colour"]["hue"] = currentHue%360;
            currentHue += increment;
          });
        }

        bool noSymbols = false;
        symbolRules.forEach((k, v) {
          var h = v["colour"]["hue"];
          var s = k=='0'?0:v["colour"]["saturation"];
          var l = v["colour"]["lightness"];
          var a = k=='0'?0.5:v["colour"]["alpha"];
          var fh = v["font"]["hue"];
          var fs = v["font"]["saturation"];
          var fl = v["font"]["lightness"];
          var fa = v["font"]["alpha"];

          String cssRule = ".tile.symbol.s$k {";
          if (tiles['mode']["type"] == "gameboy" || tiles['mode']["type"] == "tetris") {
            noSymbols = true;  // this shouldn't be inside a loop... I know
            num variant = tiles['mode']["variant"];
            a = tiles['mode']["override_colour"]?0:a;
            cssRule += ""
                "background:"
                  "linear-gradient(to right, hsla($h,$s%,$l%,$a), hsla($h,$s%,$l%,$a)),"
                  "url('./img/tetris_tiles.png') ${int.parse(k) * -1.25}em ${variant * -1.25}em;"
                "image-rendering: pixelated;"
                "background-size: 5125%;}";
          } else {
            cssRule += ""
              "background: linear-gradient("
                 "135deg,"
                 "hsla($h,$s%,${(k=='0')?l-10:l+10}%,$a) 0%,"
                 "hsla($h,$s%,${(k=='0')?l-10:l}%,$a) 50%,"
                 "hsla($h,$s%,${(k=='0')?l-10:l-10}%,$a) 51%,"
                 "hsla($h,$s%,${(k=='0')?l-10:l-2}%,$a) 100%);"
                 "color: hsla($fh, $fs%, $fl%, $fa);}";
          }
          sheet.insertRule(cssRule, sheet.cssRules.length);
        });

        var ff = tiles['font']["family"];
        String fontFamily = (ff != null)?"font-family:'$ff';": "";
        sheet.insertRule(".tile.symbol {$fontFamily}", sheet.cssRules.length);
        randomiseSymbols(noSymbols);
    }

    String export() {
      return getPrettyJSONString({
        "width": width,
        "height": height,
        "tile-size": tileSize,
        "delays": delays,
        "random-seed": randomSeed,
        "controls": controls,
        "rules": rules,
        "tiles": tiles,
        "effects": effects,
      });
    }

    void import(String dump) {
      var tmp = JSON.decode(dump);
      width = tmp["width"] != null?tmp["width"]:width;
      height = tmp["height"] != null?tmp["height"]:height;
      tileSize = tmp["tile-size"] != null?tmp["tile-size"]:tileSize;
      randomSeed = tmp["random-seed"] != null?tmp["random-seed"]:randomSeed;
      delays = tmp["delays"] != null?toObservable(tmp["delays"]):delays;
      delays.forEach((k, v) => delayDurations[k] = new Duration(milliseconds: int.parse(v)));
      controls = tmp["controls"] != null?toObservable(tmp["controls"]):controls;
      rules = tmp["rules"] != null?toObservable(tmp["rules"]):rules;
      tiles = tmp["tiles"] != null?toObservable(tmp["tiles"]):tiles;
      effects = tmp["effects"] != null?toObservable(tmp["effects"]):effects;
    }
}

String getPrettyJSONString(jsonObject){
   var encoder = new JsonEncoder.withIndent("     ");
   return encoder.convert(jsonObject);
}

//TODO check out enums? (new in dart 1.8.0.)
class Controls { // can't use nums because otherwise the JSON encoder breaks :(
  static const up = "0";
  static const down = "1";
  static const left = "2";
  static const right = "3";
  static const action = "4";

  static get values => [up, down, left, right, action];
  final int value;
  const Controls._(this.value);
}
