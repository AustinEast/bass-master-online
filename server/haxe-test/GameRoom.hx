package;

import js.lib.Promise;
import haxe.extern.EitherType;
import schema.GameState;
import colyseus.server.Room;
import colyseus.server.Client;

class GameRoom extends Room {

	var game:Game;
	var game_state:GameState;

	override function onCreate(options:Dynamic) {

		game = new Game();
		game_state = new GameState();

		maxClients = 6;

		setState(game_state);
		

		var world = state.world;
    var map = game.generate_map(world.width, world.height, world.tile_width, world.tile_height);
    for (i in 0...map.length) world.map.push(map[i]);

    setSimulationInterval((dt) -> update(dt));
    
    clock.setInterval(() -> {
      game.check_fish(game_state);
		}, 3000);
		
		onMessage('type', (client, message) -> {
			var entity = game_state.entities.get(client.id);
    	game.process_message(message, entity, game_state);
		});
	}

	override function onJoin(client:Client, ?options:Map<String, Dynamic>, ?auth:Dynamic):EitherType<Void, Promise<Dynamic>> {
		return super.onJoin(client, options, auth);

		game_state.create_entity(client.id, 0);
	}

  override function onLeave(client:Client, ?consented:Bool):EitherType<Void, Promise<Dynamic>> {
		return super.onLeave(client, consented);
		state.entities.remove(client.id);
	}

	override function onDispose() {
		trace("Disposing room");
		return null;
	}

	override function broadcastPatch() {
    state.time = Date.now();
    return super.broadcastPatch();
  }

	function update(elapsed:Float) {
    var dt = elapsed/1000;
    game.update(dt, state);
  }
}
