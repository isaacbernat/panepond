import 'package:polymer/polymer.dart';
import 'dart:async';


class Config extends Observable{
    @observable String inputWidth; //x
    @observable String inputHeight; //y
    @observable String tileSize;
    @observable String display = "block";
    @observable Map <String, num> delays = toObservable({
      "swap": "120",
      "resolve": "1800",
      "effects": "1800",
    });
    num height;
    num width;
    Map <String, Duration> delayDurations = {
      "swap": new Duration(milliseconds: 120),
      "resolve": new Duration(milliseconds: 1800),
      "effects": new Duration(milliseconds: 1800),
    };
    Config(w, h, ts) : width = w, height = h, tileSize = ts, inputWidth=h.toString(), inputHeight=h.toString();
}
