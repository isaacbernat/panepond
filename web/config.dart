import 'package:polymer/polymer.dart';
import 'dart:async';


class Config extends Observable{
    @observable String inputWidth; //x
    @observable String inputHeight; //y
    @observable String tileSize;
    @observable String display = "block";
    @observable Map <String, num> delays = toObservable({
      "swap": "1",
      "resolve": "1",
      "effects": "1",
    });
    num height;
    num width;
    Map <String, Duration> delayDurations = {
      "swap": new Duration(seconds: 1),
      "resolve": new Duration(seconds: 1),
      "effects": new Duration(seconds: 1),
    };
    Config(w, h, ts) : width = w, height = h, tileSize = ts, inputWidth=h.toString(), inputHeight=h.toString();
}
