import 'package:polymer/polymer.dart';
import 'dart:async';


class Config extends Observable{
    @observable num width; //x
    @observable num height; //y
    @observable num tileSize;
    @observable String display = "block";
    @observable Map <String, num> delays = toObservable({
      "swap": 1,
      "resolve": 1,
      "effects": 1,
    });
    Map <String, Duration> delayDurations = {
      "swap": new Duration(seconds: 1),
      "resolve": new Duration(seconds: 1),
      "effects": new Duration(seconds: 1),
    };
    Config(w, h, ts) : height = h, width = w, tileSize = ts;
}
