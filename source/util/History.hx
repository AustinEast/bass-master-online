package util;

@:structInit
class GState {
  public var entities:Map<String, EntityState>;
  public var time:Float;
}

@:structInit
class EntityState  {
  public var id:String;
  public var x:Float;
  public var y:Float;
  public var rotation:Float;
}
