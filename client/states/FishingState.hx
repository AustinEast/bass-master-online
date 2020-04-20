package client.states;

import source.Util;
import source.Types.Entity;
import client.objects.*;
import zero.flixel.states.sub.SubState;
import source.Game;
import source.Types.ClientMessage;
import source.Types.EntityType;
import source.Types.EntityState;
import flixel.text.FlxText;
import js.node.socketio.Client;

class FishingState extends SubState
{
	var game:Game;
	var client:Client;
	var client_id:Null<String>;
	var sprites:Map<String,FlxSprite>;	
	var player_state_text:FlxText;
	var player_weight_text:FlxText;

	override public function create():Void
	{
		super.create();

		sprites = [];

		var display = new FlxGroup();
		var connected_text = new FlxText();
		player_state_text = new FlxText(0,16);
		player_weight_text = new FlxText(0,32);
		
		add(display);
		add(connected_text);
		add(player_state_text);
		add(player_weight_text);

		game = new Game();
		game.on_add = entity -> {
			var sprite:FlxSprite;

			switch ((cast entity.type:EntityType)) {
				case Player:
					sprite = new FlxSprite(entity.x, entity.y);
					sprite.makeGraphic(32, 32, client_id == entity.id ? FlxColor.LIME : FlxColor.GREEN);
					sprite.centerOrigin();
				case Fish:
					sprite = new FlxSprite(entity.x, entity.y);
					sprite.makeGraphic(24, 24, FlxColor.BLUE);
					sprite.centerOrigin();
				case Bobber:
					sprite = new Bobber(entity.x, entity.y);
			}

			if (sprite != null) {
				display.add(sprite);
				sprites.set(entity.id, sprite);
			}
		}
		game.on_remove = entity -> {
			var sprite = sprites.get(entity.id);
			if (sprite != null) {
				sprites.remove(entity.id);
				display.remove(sprite);
				sprite.destroy();
			}
		}

		client = new Client('fishing-alone-together.herokuapp.com'); //${Globals.url}:${Globals.port}
		client.on(cast ClientMessage.OnConnected, (data) -> {
			if (data.id != null) { 
				client_id = data.id;
				connected_text.text = 'Connected successfully to the socket.io server. My server side ID is $client_id';
			}
		});

		client.on(cast ClientMessage.GameState, (data) -> {
			if (client_id != null && data.game_state != null) {
				game.sync(data.game_state);
			}
		});

		client.on(cast ClientMessage.AddEntity, (data) -> {
			if (client_id != null && data.entity != null) {
				game.add_entity(data.entity);
			}
		});

		client.on(cast ClientMessage.UpdateEntity, (data) -> {
			if (client_id != null && data.id != null) {
				game.update_entity(data);
			}
		});

		client.on(cast ClientMessage.RemoveEntity, (data) -> {
			if (client_id != null && data.entity != null) {
				game.remove_entity(data.entity.id);
			}
		});
	}

	override public function update(elapsed:Float):Void
	{
		input(elapsed);

		super.update(elapsed);

		sync();

		var entity = game.entities.get(client_id);
		if (entity != null) {
			player_weight_text.text = entity.weight.string();
			player_state_text.text = switch (cast entity.state : EntityState) {
				case Idle:
					'Idle';
				case Aiming:
					'Aiming';
				case Casting:
					'Casting';
				case Fishing:
					'Fishing';
				case Reeling:
					'Reeling';
				case Interested:
					'Interested';
				case Nibbling:
					'Nibbling';
				case Caught:
					'Caught';
			}
		}
	}

	override function destroy() {
		super.destroy();

		// untyped due to outdated externs
		untyped client.close();
		client = null;
		game.dispose();
		game = null;
		sprites.clear();
		sprites = null;
	}

	function sync() {
		var point = FlxPoint.get();
		for (key => sprite in sprites) {
			if (sprite == null) continue;
			var entity = game.entities.get(key);
			if (entity != null) {
				point.set(entity.x, entity.y);
				sprite.set_midpoint_position(point);
				sprite.angle = entity.rotation;
			}
		}
		point.put();
	}

	function input(dt:Float) {
		var mouse = FlxG.mouse.getWorldPosition();
		var entity = game.entities.get(client_id);
		var sprite = sprites.get(client_id);
		
		// The left mouse button is currently pressed
		if (FlxG.mouse.pressed) {
			if (entity != null && entity.state != null) {
				// if (entity.state == (cast EntityState.Idle) && sprite != null) {
				// 	var mid = sprite.getMidpoint();
				// 	if (!mid.equals(mouse)) {
				// 		entity.target = { x: mouse.x, y: mouse.y }
				// 		client.emit(cast ClientMessage.UpdateEntity, { id: client_id, x: entity.x, y: entity.y, rotation: entity.rotation, target: { x: mouse.x, y: mouse.y } });
				// 	}
				// 	mid.put();
				// }
				/*else*/ if (entity.state == cast EntityState.Aiming) {
					var pos = FlxPoint.get(entity.x, entity.y);
					var angle = mouse.get_angle_between(pos);
					if (entity.rotation != angle)
					{
						entity.rotation = angle;
						client.emit(cast ClientMessage.UpdateEntity, { id: client_id, rotation: angle });
					}
					pos.put();
				}
			}
		}

		// The left mouse button has just been pressed
		if (FlxG.mouse.justPressed) {
			if (entity != null) {
				if (entity.state == (cast EntityState.Idle) && sprite != null && sprite.overlapsPoint(mouse)) {
					entity.state = cast EntityState.Aiming;
					client.emit(cast ClientMessage.UpdateEntity, { id: client_id, state: cast EntityState.Aiming });
				}
				else if (entity.state == (cast EntityState.Fishing) || entity.state == cast EntityState.Casting)
				{
					if (entity.child != null) {
						var bobber = game.entities.get(entity.child);
						if (bobber != null) {
							bobber.target = { x: entity.x, y: entity.y }
							client.emit(cast ClientMessage.UpdateEntity, { id: bobber.id, state: cast EntityState.Reeling, target: bobber.target });
							if (bobber.child != null) {
								var fish = game.entities.get(bobber.child);
								if (fish != null) {
									if (fish.state == cast EntityState.Nibbling) {
										fish.state = cast EntityState.Caught;
										fish.target = {x: entity.x, y: entity.y }
										fish.parent = entity.id;
										entity.state = cast EntityState.Caught;
										client.emit(cast ClientMessage.UpdateEntity, { id: fish.id, state: cast EntityState.Caught, target: fish.target, parent: entity.id });
										client.emit(cast ClientMessage.UpdateEntity, { id: client_id, state: cast EntityState.Caught });
									}
									else {
										game.remove_entity(fish.id);
										client.emit(cast ClientMessage.RemoveEntity, { id: fish.id });
									}
								}
							}
						}
					}
					if (entity.state != cast EntityState.Caught) {
						entity.state = cast EntityState.Reeling;
						client.emit(cast ClientMessage.UpdateEntity, { id: client_id, state: cast EntityState.Reeling });
					}
				}
			}
		}

		// The left mouse button has just been released
		if (FlxG.mouse.justReleased) {
			if (entity != null) {
				if (entity.state == cast EntityState.Idle) {
					entity.target = {x: mouse.x, y: mouse.y };
					client.emit(cast ClientMessage.UpdateEntity, { id: client_id, target: { x: mouse.x, y: mouse.y } });
				} 
				else if (entity.state == cast EntityState.Aiming)
				{
					var uuid = Util.uuid();
					entity.state = cast EntityState.Casting;
					entity.child = uuid;
					client.emit(cast ClientMessage.UpdateEntity, { id: client_id, state: cast EntityState.Casting, child: uuid });
					var bobber:Entity = {
						id: uuid,
						x: entity.x,
						y: entity.y,
						rotation: entity.rotation,
						state: cast EntityState.Idle,
						type: cast EntityType.Bobber,
						parent: entity.id,
						target: {
							x: mouse.x,
							y: mouse.y
						}
					}
					game.add_entity(bobber);
					client.emit(cast ClientMessage.AddEntity, { entity : bobber });
				}
			}
		}

		mouse.put();
	}
}
