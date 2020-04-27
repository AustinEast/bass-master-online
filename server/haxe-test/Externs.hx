package;

@:jsRequire('express')
extern class Express {
  @:selfCall static function create():Express;
  function use(?path:String, what:Dynamic):Void;
}

@:jsRequire('@colyseus/monitor','monitor')
extern class Monitor {
  @:selfCall static function create():Monitor;
}