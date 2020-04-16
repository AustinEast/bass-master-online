package server;

import haxe.Timer;

class Room {

  public final max_clients = 6;

  public var count(default, null):Int;

  final max_fish:Int = 4;
  
  var id(default, null):String;
  var game(default, null):Game;
  var clients:Map<String, ClientSocket>;
  var state_timer:Timer;
  var fish_timer:Timer;
  var fish_count:Int = 0;


  public function new(?client:ClientSocket) {
    id = Util.uuid();
    clients = [];
    count = 0;

    trace('\t socket.io:: room $id was created by player ${client.uuid}');

    game = new Game();
    game.on_add = entity -> {
      for (client in clients) {
        client.emit(cast ClientMessage.AddEntity, { entity: entity });
      }
    };
    game.on_remove = entity -> {
      if (entity.type == cast EntityType.Fish) fish_count--;

      for (client in clients) {
        client.emit(cast ClientMessage.RemoveEntity, { entity: entity });
      }
    };

    if (client != null)
      add_client(client);

    // Send out the Game State to all clients every 45 milliseconds
    state_timer = new Timer(45);
    state_timer.run = () -> {
      for (client in clients) client.emit(cast ClientMessage.GameState, { game_state: game.save() });
    }

    // Check if we should spawn fish
    fish_timer = new Timer(3000);
    fish_timer.run = () -> {
      if (fish_count < max_fish) {
        fish_count++;
        game.add_entity({
          id: Util.uuid(),
          x: Math.random() * 200,
          y: Math.random() * 200,
          rotation: 0,
          type: cast Fish,
          state: cast Idle,
          timer: 0,
          weight: 1
        });
      }
    }
  }

  public function add_client(client:ClientSocket) {
    var match = clients.get(client.uuid);
    if (match == null) {
      clients.set(client.uuid, client);
      client.emit(cast ClientMessage.GameState, { game_state: game.save() });

      trace('\t socket.io:: player ${client.uuid} added to room $id');

      game.add_entity({
        id: client.uuid,
        x: Math.random() * 200,
        y: Math.random() * 200,
        rotation: 0,
        type: cast Player,
        state: cast Idle,
        weight: 0
      });

      count++;
    }
  }

  public function remove_client(uuid:String) {
    if (clients.remove(uuid)) {
      trace('\t socket.io:: player ${uuid} removed from room $id');
      game.remove_entity(uuid);

      count--;
    }
  }

  public function add_entity(data:Dynamic) {
    if (data.entity == null) return;
    if (data.entity.id == null) data.entity.id = Util.uuid();

    game.add_entity(data.entity);

    for (client in clients) 
      client.emit(cast ClientMessage.AddEntity, data);
  }

  public function update_entity(data:Dynamic) {
    game.update_entity(data);

    for (client in clients) 
      client.emit(cast ClientMessage.UpdateEntity, data);
  }

  public function remove_entity(data:Dynamic) {
    if (data.id == null) return;
    game.remove_entity(data.id);

    for (client in clients) 
      client.emit(cast ClientMessage.RemoveEntity, data);
  }

  public function dispose() {
    game.dispose();
    game = null;
    clients.clear();
    clients = null;
    state_timer.stop();
    state_timer = null;
    fish_timer.stop();
    fish_timer = null;
    fish_count = 0;
  }
}