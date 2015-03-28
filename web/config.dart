import 'package:polymer/polymer.dart';
import 'dart:async';
import 'dart:convert';


class Config extends Observable {
    @observable String inputWidth; //x
    @observable String inputHeight; //y
    @observable String tileSize;
    @observable String display = "block";
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
      "colours": {"0": "black", "1": "red", "2": "green", "3": "blue", "4": "cyan", "5": "magenta", "6": "yellow"}
    };
    Map effects = {
      "score_effects": true,
      "resolve_effects": true, //TODO this is going to be updated with more complex/custom stuff
    };

    @observable Map<num, String> controls = toObservable( {
      Controls.up: "I",
      Controls.down: "K",
      Controls.left: "J",
      Controls.right: "L",
      Controls.action: "Q",
    });

    Config(w, h, ts) : width = w, height = h, tileSize = ts, inputWidth=w.toString(), inputHeight=h.toString();

    String export() {
      return JSON.encode({
        "input-width": inputWidth,
        "input-height": inputHeight,
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
      inputWidth = tmp["input-width"] != null?tmp["input-width"]:inputWidth;
      inputHeight = tmp["input-height"] != null?tmp["input-height"]:inputHeight;
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
