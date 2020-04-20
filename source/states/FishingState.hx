package states;

import objects.*;
import schema.GameState;
import zero.flixel.states.sub.SubState;
import flixel.text.FlxText;

import io.colyseus.Client;
import io.colyseus.Room;

using flixel.util.FlxSpriteUtil;

/**
 * Client interpolation ported from: https://victorzhou.com/blog/build-an-io-game-part-1/#4-client-networking
 */
class FishingState extends SubState
{

	final render_delay:Int = 100;
	final game_states:Array<GState> = [];

	var client:Client;
	var room:Room<GameState>;
	var interpolate:Bool = true;

	var first_timestamp:Float = 0;
	var first_server_timestamp:Float = 0;

	var input_buffer:Array<InputMessage> = [];

	var entities:Map<String,FlxSprite> = [];

	var players:FlxTypedGroup<Player>;
	var fish:FlxTypedGroup<Fish>;
	var bobbers:FlxTypedGroup<Bobber>;
	var canvas:FlxSprite;

	var player_state_text:FlxText;
	var player_weight_text:FlxText;

	override public function create():Void
	{
		super.create();

		players = new FlxTypedGroup();
		fish = new FlxTypedGroup();
		bobbers = new FlxTypedGroup();

		canvas = new FlxSprite();
		canvas.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);

		player_state_text = new FlxText(0,16);
		player_weight_text = new FlxText(0,32);
		
		add(canvas);
		add(bobbers);
		add(players);
		add(fish);
		add(player_state_text);
		add(player_weight_text);

		init_client();
	}

	override public function update(elapsed:Float)
	{
		canvas.fill(FlxColor.TRANSPARENT);

		input(elapsed);

		super.update(elapsed);

		sync();

		canvas.endDraw();

		// TEMP UI
		if (room == null) return;

		var player = room.state.entities.get(room.sessionId);
		if (player != null) {
			player_weight_text.text = player.weight.string();
			player_state_text.text = switch (cast player.state : PlayerState) {
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
				case Caught:
					'Caught';
			}
		}
	}

	override function destroy() {
		super.destroy();

		client = null;
		// game.dispose();
		// game = null;
		entities.clear();
	}

	function init_client() {
		#if debug
		client = new Client('ws://localhost:2567');
		#else
		client = new Client('fishing-alone-together.herokuapp.com');
		#end

		client.joinOrCreate("game_room", [], GameState, function(err, room) {
			if (err != null) {
					trace("JOIN ERROR: " + err);
					return;
			}
	
			room.state.entities.onAdd = (entity, key) -> {
					trace("entity added at " + key + " => " + entity);
					var pos = FlxPoint.get(entity.x, entity.y);

					switch ((cast entity.type:EntityType)) {
						case Player:
							var player = players.recycle(objects.Player);
							player.set_midpoint_position(pos);
							player.color = key == room.sessionId ? FlxColor.LIME : FlxColor.GREEN;
							entities.set(entity.id, player);
						case Fish:
							var fish = fish.recycle(objects.Fish);
							fish.set_midpoint_position(pos);
							entities.set(entity.id, fish);
						case Bobber:
							var bobber = bobbers.recycle(objects.Bobber);
							bobber.set_midpoint_position(pos);
							entities.set(entity.id, bobber);
					}

					pos.put();
	
					entity.onChange = (changes) -> {
							// trace("entity changes => " + changes);
					}
			}
	
			room.state.entities.onChange = (entity, key) -> {
					// trace("entity changed at " + key + " => " + entity);
			}

			room.onStateChange += process_state_change;
	
			room.state.entities.onRemove = (entity, key) -> {
					trace("entity removed at " + key + " => " + entity);
					var sprite = entities.get(key);
					if (sprite != null) {
						entities.remove(key);
						sprite.kill();
					}
			}

			this.room = room;
		});
	}

	function sync() {		
		var state = get_current_state();

		if (state == null) return;

		var point = FlxPoint.get();
		for (key => sprite in entities) {
			if (sprite == null) continue;
			var player = state.entities.get(key);
			if (player != null) {
				point.set(player.x, player.y);
				sprite.set_midpoint_position(point);
				sprite.angle = player.rotation;
			}
		}
		point.put();
	}

	function input(dt:Float) {
		if (room == null) return;

		var mouse = FlxG.mouse.getWorldPosition();
		
		// The left mouse button is currently pressed
		if (FlxG.mouse.pressed) {
			room.send({ mouse: cast Pressed, x: mouse.x, y: mouse.y });

			var player = room.state.entities.get(room.sessionId);
			if (player != null && player.state == cast PlayerState.Aiming) {
				var pos = FlxPoint.get(player.x, player.y);
				var angle = pos.get_angle_between(mouse);
				var distance = pos.distance(mouse).min(72);
				var aim_back = (angle).vector_from_angle(distance).to_flxpoint().addPoint(pos);
				var aim_pos = (angle - 180).vector_from_angle(distance * 2).to_flxpoint().addPoint(pos);
				draw_line(pos, aim_back, FlxColor.RED);
				draw_line(pos, aim_pos);
				pos.put();
				aim_pos.put();
				aim_back.put();
			}
		}

		// The left mouse button has just been pressed
		if (FlxG.mouse.justPressed) {
			room.send({ mouse: cast JustPressed, x: mouse.x, y: mouse.y });
		}

		// The left mouse button has just been released
		if (FlxG.mouse.justReleased) {
			room.send({ mouse: cast JustReleased, x: mouse.x, y: mouse.y });
		}

		mouse.put();

		#if debug
		if (FlxG.keys.justPressed.I) {
			interpolate = !interpolate;
		}
		#end
	}

	function process_state_change(state:GameState) {
		if (first_server_timestamp == 0) {
			first_server_timestamp = room.state.time;
			first_timestamp = Date.now().getTime();
		}
		
		var gstate:GState = {
			entities: [],
			time: state.time
		}

		for (player in state.entities) gstate.entities.set(player.id, {
				id: player.id,
				x: player.x,
				y: player.y,
				rotation: player.rotation
			}
		);

		game_states.push(gstate);

		// Keep only one game update before the current server time
		var base = get_base_update();
		if (base > 0) game_states.splice(0, base);
	}

	function current_server_time() {
		return first_server_timestamp + (Date.now().getTime() - first_timestamp) - render_delay;
	}

	/**
	 * Returns the index of the base update - the first game update before current server time, or -1 if N/A.
	 */
	function get_base_update() {
		var server_time = current_server_time();
		var i = game_states.length - 1;
		while (i >= 0) {
			if (game_states[i].time <= server_time) {
				return i;
			}
			i--;
		}
		return -1;
	}

	function get_current_state() {
		if (first_server_timestamp == 0) return null;
	
		var base = get_base_update();
		var server_time = current_server_time();
	
		// If base is the most recent update we have, use its state.
		// Else, interpolate between its state and the state of (base + 1).
		if (base < 0 || !interpolate) {
			return game_states[game_states.length - 1];
		} else if (base == game_states.length - 1) {
			return game_states[base];
		} else {
			var base_update = game_states[base];
			var next = game_states[base + 1];
			var r = (server_time - base_update.time) / (next.time - base_update.time);
			var state:GState = {
				entities: base_update.entities.copy(),
				time: base_update.time
			}

			for (player in state.entities) {
				var n = next.entities.get(player.id);
				if (n != null) {
					player.x = r.lerp(player.x, n.x);
					player.y = r.lerp(player.y, n.y);
					player.rotation = r.lerp(FloatExt.translate_to_nearest_angle(player.rotation, n.rotation), n.rotation);
				}
			}

			return state;
		}
	}

	public function draw_line(v1:FlxPoint, v2:FlxPoint, ?color:FlxColor) {
    canvas.drawCircle(v1.x, v1.y, 4);
    canvas.drawCircle(v2.x, v2.y, 4);
		canvas.draw_dashed_line(v1, v2, (v1.distance(v2).abs()/6).int(), color);
	}
	
	// public function draw_line(o1:FlxObject, o2:FlxObject) {
  //   var mid1 = o1.getMidpoint();
  //   var mid2 = o2.getMidpoint();
  //   canvas.drawCircle(mid1.x, mid1.y, 4);
  //   canvas.drawCircle(mid2.x, mid2.y, 4);
  //   canvas.draw_dashed_line(mid1, mid2, (mid1.distance(mid2).abs()/6).int());
  //   mid1.put();
  //   mid2.put();
  // }
}
