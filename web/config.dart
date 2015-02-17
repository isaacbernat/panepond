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
      "effects": "1800",
    });
    @observable String randomSeed = "1234";
    num height;
    num width;
    Map <String, Duration> delayDurations = {
      "swap": new Duration(milliseconds: 120),
      "resolve": new Duration(milliseconds: 1800),
      "effects": new Duration(milliseconds: 1800),
    };
    @observable String jsonDump = "";
    Config(w, h, ts) : width = w, height = h, tileSize = ts, inputWidth=w.toString(), inputHeight=h.toString();

    Config longConstructor(w, h, ts, r, d) {
      width = w;
      height = h;
      inputWidth=w.toString();
      inputHeight=h.toString();
      tileSize = ts;
      randomSeed = r;
      delays = toObservable(d);
    }

    String export() {
      return JSON.encode({
        "input-width": inputWidth,
        "input-height": inputHeight,
        "tile-size": tileSize,
        "delays": delays,
        "random-seed": randomSeed,
      });
    }
}
