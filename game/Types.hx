package;

typedef InputMessage = {
  time:Float,
  ?mouse:MouseInput,
  ?x:Float,
  ?Y:Float
}

enum abstract MouseInput(String) {
  var Pressed = 'p';
  var JustPressed = 'jp';
  var JustReleased = 'jr';
}

@:structInit
class GState {
  public var entities:Map<String,EntityState>;
  public var time:Float;
}

@:structInit
class EntityState  {
  public var id:String;
  public var x:Float;
  public var y:Float;
  public var rotation:Float;
}

enum abstract EntityType(Int) {
  var Player;
  var Fish;
  var Bobber;
}

enum abstract PlayerState(Int) {
  var Idle;
  var Aiming;
  var Casting;
  var Fishing;
  var Reeling;
  var Caught;
}

enum abstract FishState(Int) {
  var Idle;
  var Interested;
  var Nibbling;
  var Caught;
}

enum abstract BobberState(Int) {
  var Idle;
  var Floating;
  var Nibbled;
  var Reeling;
}
