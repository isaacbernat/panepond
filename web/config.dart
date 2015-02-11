import 'package:polymer/polymer.dart';


class Config extends Observable{
    @observable num width; //x
    @observable num height; //y
    @observable num tileSize;
    @observable String display = "block";
    Config(w, h, ts) : height = h, width = w, tileSize = ts;
}
