import 'package:polymer/polymer.dart';


class Config extends Observable{
    @observable num width; //x
    @observable num height; //y
    Config(width, height) : height = height, width = width;
}
