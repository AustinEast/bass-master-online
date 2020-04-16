package source;

extern class ClientSocket extends js.node.socketio.Socket {
  public var uuid:String;
}

enum abstract ClientMessage(String) {
  var OnConnected;
  var Disconnected;
  var GameState;
  var AddEntity;
  var UpdateEntity;
  var RemoveEntity;
  // var SetEntityTransform;
  // var SetEntityTarget;
  // var SetEntityState;
}

typedef GameState = {
  entities:Array<Entity>,
  time:Float
}

typedef Player = {
  id:String,
  inputs:Array<String>
}

typedef Entity = {
  x:Float,
  y:Float,
  rotation:Float,
  type:Int,
  state:Int,
  ?id:String,
  ?weight:Float,
  ?child:String,
  ?parent:String,
  ?timer:Float,
  ?target: {
    x:Float,
    y:Float
  }
}

enum abstract EntityType(Int) {
  var Player;
  var Fish;
  var Bobber;
}

enum abstract EntityState(Int) {
  var Idle;
  var Aiming;
  var Casting;
  var Fishing;
  var Reeling;
  var Interested;
  var Nibbling;
  var Caught;
}