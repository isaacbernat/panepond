import 'package:polymer/polymer.dart';


class Config extends Observable{
    @observable num width; //x
    @observable num height; //y
    @observable num tileSize;
    Config(w, h, ts) : height = h, width = w, tileSize = ts;
}
