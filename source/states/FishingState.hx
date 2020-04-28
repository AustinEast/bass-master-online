package states;

import flixel.input.mouse.FlxMouseEventManager;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import zero.flixel.states.sub.FadeIn;
import openfl.filters.ShaderFilter;
import util.MosaicEffect;
import zero.utilities.Vec2;
import objects.*;
import schema.GameState;
import zero.flixel.states.sub.SubState;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;

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

	var ui:FlxGroup;
	var ui_cam:FlxCamera;
	var ui_weight_text:FlxText;

	var ubble:FlxBitmapFont;
	var byond:FlxBitmapFont;
	var connecting:FlxBitmapText;

	var client:Client;
	var room:Room<GameState>;
	var interpolate:Bool = true;

	var first_timestamp:Float = 0;
	var first_server_timestamp:Float = 0;

	var input_buffer:Array<InputMessage> = [];

	var entities:Map<String,FlxSprite> = [];

	var trees:Array<Tree> = [];
	var rocks:Array<Rock> = [];

	var shadows:FlxGroup;
	var sorted:FlxTypedGroup<DepthSprite>;
	var players:FlxTypedGroup<Player>;
	var fish:FlxTypedGroup<Fish>;
	var fish_on_top:FlxTypedGroup<Fish>;
	var bobbers:FlxTypedGroup<Bobber>;
	var canvas:FlxSprite;
	var tilemap:DepthTilemap;
	var aim_timer:FlxTimer;

	var cursor:DepthSprite;
	
	// camera stuff
	var angle:Float;
	var last_mouse_x:Float;
	var lerp:Float = 0.0015;

	override public function create():Void
	{
		super.create();

		FlxG.mouse.visible = false;

		openSubState(new FadeIn());

		shadows = new FlxGroup();
		sorted = new FlxTypedGroup();
		players = new FlxTypedGroup();
		fish = new FlxTypedGroup();
		fish_on_top = new FlxTypedGroup();
		bobbers = new FlxTypedGroup();

		ui = new FlxGroup();

		canvas = new FlxSprite();
		canvas.makeGraphic(1,1);

		tilemap = new DepthTilemap();
		tilemap.slice_offset = 5;
		tilemap.camera = camera;

		cursor = new DepthSprite();
		cursor.loadSlices(Images.cursor__png, 13, 13, 7);
		
		add(tilemap);
		add(shadows);
		add(canvas);
		add(sorted);
		// add(fish);
		// add(bobbers);
		// add(players);
		add(ui);
		add(cursor);

		// camera.bgColor = 0xff45283c;
		camera.bgColor = 0xfffeb58b;

		ubble = FlxBitmapFont.fromAngelCode(Fonts.ubble__png, Fonts.ubble__fnt);
		byond = FlxBitmapFont.fromAngelCode(Fonts.byond__png, Fonts.byond__fnt);

		connecting = new FlxBitmapText(byond);
		connecting.text = 'connecting...';
		connecting.scale.set(0.5,0.5);
		connecting.screenCenter();

		add(connecting);

		FlxG.plugins.add(new FlxMouseEventManager());

		new FlxTimer().start(1, (timer -> {
			init_client();
		}));
	}

	override public function update(elapsed:Float)
	{
		canvas.fill(FlxColor.WHITE);
		canvas.fill(FlxColor.TRANSPARENT);

		input(elapsed);

		super.update(elapsed);

		sync();

		sorted.sort(sort_by_depth);

		

		if (room == null) {
			canvas.endDraw();
			return;
		}

		var player = room.state.entities.get(room.sessionId);
		if (player != null) {
			if (!FlxG.mouse.pressed) camera.angle += ((-player.rotation - 90).translate_to_nearest_angle(camera.angle) - camera.angle) * lerp;

			if (ui_weight_text != null) ui_weight_text.text = 'Total Caught: ${player.weight == null ? 0 : player.weight} Bass';
		}

		canvas.endDraw();
		// camera.angle += 20 * elapsed;
	}

	override function destroy() {
		super.destroy();

		FlxG.mouse.visible = true;

		if (room != null) {
			room.leave();
		}
		client = null;
		// game.dispose();
		// game = null;
		entities.clear();
	}

	function init_client() {
		#if debug
		client = new Client('ws://localhost:2567');
		#else
		client = new Client('wss://fishing-alone-together.herokuapp.com');
		#end

		client.joinOrCreate("game_room", [], GameState, function(err, room) {
			if (err != null) {
					trace("JOIN ERROR: " + err);
					FlxG.switchState(new MenuState());
			}

			init_ui();

			camera.setSize(FlxG.width * 2, FlxG.height * 2);
			camera.setPosition(-FlxG.width.half(), -FlxG.height.half());
			connecting.kill();

			var effect = new MosaicEffect();
			camera.setFilters([new ShaderFilter(cast effect.shader)]);

			var effect_tween = FlxTween.num(15, 1, 1, null, (v) -> {
				effect.setStrength(v, v);
			});
			effect_tween.onComplete = (tween) -> {
				camera.setFilters([]);
			}

			var world = room.state.world;

			FlxG.sound.play(Music.sea__wav, 0.1, true);
			FlxG.sound.play(Music.forest__wav, 0.4, true);

			room.state.entities.onAdd = (entity, key) -> {
				trace("entity added at " + key + " => " + entity);
				var pos = FlxPoint.get(entity.x, entity.y);

				switch ((cast entity.type:EntityType)) {
					case Player:
						var player = players.recycle(objects.Player);
						player.set_midpoint_position(pos);
						player.angle = entity.rotation;
						// player.color = key == room.sessionId ? FlxColor.LIME : FlxColor.GREEN;
						player.camera = camera;
						sorted.add(player);
						entities.set(entity.id, player);

						if (key == room.sessionId) {
							camera.follow(player, TOPDOWN_TIGHT, 0.015);
						}
					case Fish:
						var fish = fish.recycle(objects.Fish);
						fish.set_midpoint_position(pos);
						fish.angle = entity.rotation;
						fish.camera = camera;
						sorted.add(fish);
						entities.set(entity.id, fish);
					case Bobber:
						var bobber = bobbers.recycle(objects.Bobber);
						bobber.set_midpoint_position(pos);
						bobber.angle = entity.rotation;
						bobber.camera = camera;
						sorted.add(bobber);
						entities.set(entity.id, bobber);
				}

				pos.put();

				entity.onChange = (changes) -> {
					// trace("entity changes => " + changes);
					var is_player = entity.id == key;
					switch (cast entity.type : EntityType) {
						case Player:
						for (change in changes) {
							if (change.field == 'state') {
								switch (cast change.value : PlayerState) {
									case Casting:
										FlxG.sound.play(Sounds.cast__wav, is_player ? 1 : .7); 
									case Caught:
										FlxG.sound.play(Sounds.collected__wav, is_player ? 1 : .7); 
									default:
								}
							}
						}
						case Fish:
							for (change in changes) {
								if (change.field == 'state') {
									switch (cast change.value : FishState) {
										case Nibbling:
											FlxG.sound.play(Sounds.hooked__wav, 1.get_random(0.6)); 
										default:
									}
								}
							}
						case Bobber:
							for (change in changes) {
								if (change.field == 'state') {
									switch (cast change.value : BobberState) {
										case Floating:
											FlxG.sound.play(Sounds.splash__wav, 1.get_random(0.6)); 
										default:
									}
								}
							}
					}
				}
			}
	
			room.state.entities.onChange = (entity, key) -> {
					// trace("entity changed at " + key + " => " + entity);
			}

			room.onStateChange += process_state_change;
	
			room.state.entities.onRemove = (entity, key) -> {
					trace("entity removed at " + key + " => " + entity);
						new FlxTimer().start(render_delay / 1000, (timer) -> {
						var sprite = entities.get(key);
						if (sprite != null) {
							entities.remove(key);
							sprite.kill();
						}
					});
			}

			room.state.world.onChange = (changes) -> {
				for (change in changes) {
					if (change.field == 'map') {
						tilemap.loadDepthMapFromArray((untyped change.value.items), (world.width/world.tile_width).to_int(), (world.height/world.tile_height).to_int(), [
							{ graphic: Images.grass_tiles__png, slices: 1, auto_tile: AUTO },
							{ graphic: Images.grass_2_tiles__png, slices: 2, auto_tile: AUTO },
							{ graphic: Images.dirt_tiles__png, slices: 2, auto_tile: AUTO },
							{ graphic: Images.dirt_2_tiles__png, slices: 2, auto_tile: AUTO },
							{ graphic: Images.foam_tiles__png, slices: 1, auto_tile: AUTO },
							{ graphic: Images.water_tiles__png, slices: 1, auto_tile: OFF, alpha: 0.4, draw_index: 0, use_scale_hack: false },
							{ graphic: Images.dirt_2_tiles__png, slices: 2, auto_tile: AUTO }
						], 16, 16);

						canvas.makeGraphic(tilemap.width.to_int(), tilemap.height.to_int(), FlxColor.TRANSPARENT);

						var tiles:Array<Int> = untyped change.value.items;

						for (tree in trees) {
							if (tree != null) {
								sorted.remove(tree);
								if (tree.shadow != null) shadows.remove(tree.shadow);
								tree.destroy();
							}
						}

						for (rock in rocks) {
							if (rock != null) {
								sorted.remove(rock);
								rock.destroy();
							}
						}

						trees.resize(0);
						rocks.resize(0);

						// Add trees and rocks
						for (i in 0...tiles.length) {
							var tile = tiles[i];
							if (tile == 2) {
								var coords = tilemap.getTileCoordsByIndex(i, false);
								var tree:Tree = cast tilemap.tileToSprite((coords.x / tilemap.get_tile_width()).to_int(), (coords.y / tilemap.get_tile_height()).to_int(), 0, (props) ->  new Tree(coords.x, coords.y));
								sorted.add(tree);
								shadows.add(tree.shadow);
								trees.push(tree);
							}
							else if (tile == 3) {
								var coords = tilemap.getTileCoordsByIndex(i, false);
								var rock:Rock = cast tilemap.tileToSprite((coords.x / tilemap.get_tile_width()).to_int(), (coords.y / tilemap.get_tile_height()).to_int(), 0, (props) ->  new Rock(coords.x + tilemap.get_tile_width().half(), coords.y + tilemap.get_tile_height().half()));
								sorted.add(rock);
								rocks.push(rock);
							}
						}
					}
				}
			}

			room.onLeave += () -> {
				FlxG.switchState(new MenuState());
			}

			this.room = room;
		});
	}

	function init_ui() {
		// Add UI
		
		ui_cam = new FlxCamera();
		ui_cam.bgColor = FlxColor.TRANSPARENT;
		ui.camera = ui_cam;
		FlxCamera.defaultCameras = [FlxG.camera];
		FlxG.cameras.add(ui_cam);

		var back_button = new FlxSprite(10, 15).loadGraphic(Images.back_button__png);
		FlxMouseEventManager.add(back_button, null, (sprite) -> FlxG.switchState(new MenuState()));
		back_button.camera = ui_cam;

		// var shirt_button = new FlxSprite(30, 15).loadGraphic(Images.shirt_button__png);
		// FlxMouseEventManager.add(shirt_button, null, (sprite) -> {
		// 	if (room != null) {
		// 		sprite = entities.get(room.sessionId);
		// 		if (sprite != null) {

		// 		}
		// 	}
		// });
		// shirt_button.camera = ui_cam;

		ui_weight_text = new FlxText();
		ui_weight_text.text = 'Total Caught: 0 Bass';
		ui_weight_text.size = ui_weight_text.size * 2;
		ui_weight_text.setBorderStyle(SHADOW, FlxColor.BLACK);
		// ui_weight_text.centerOffsets(true);
		ui_weight_text.setPosition(30, 10);
		ui_weight_text.camera = ui_cam;
		
		ui.add(back_button);
		// ui.add(shirt_button);
		ui.add(ui_weight_text);
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

		var mouse = FlxG.mouse.getWorldPosition();
		var p = FlxPoint.get(camera.scroll.x + camera.width.half(), camera.scroll.y + camera.height.half());
		mouse.rotate(p, -camera.angle);
		p.put();

		cursor.set_midpoint_position(mouse);

		if (room == null) {
			if (FlxG.mouse.pressed) {
				if (cursor.slice_offset > 0.6) cursor.slice_offset -= 20 * dt;
				else if (cursor.slice_offset < 1.3)	cursor.slice_offset += 20 * dt;
			}

			if (FlxG.mouse.justPressed) FlxG.sound.play(Sounds.click_down__wav);
			if (FlxG.mouse.justReleased) FlxG.sound.play(Sounds.click_up__wav);
			return;
		}

		var player = room.state.entities.get(room.sessionId);

		

		var mouse_in_bounds = tilemap.overlapsPoint(mouse);
		var mouse_index = 0;

		if (mouse_in_bounds) {
			mouse_index = tilemap.get_index_from_point(mouse);
		}

		var mouse_active = mouse_index != 0;
		var mouse_on_player = false;
		if ( player != null) {
			var pos = Vec2.get(player.x, player.y);
			var mouse_vec = mouse.to_vector();
			if (Util.in_circle(pos, mouse_vec, 16)) mouse_on_player = true;
			pos.put();
			mouse_vec.put();
		}

		if (mouse_on_player || (player != null && player.state == cast PlayerState.Fishing)) cursor.color = 0xff57c52b;
		else if (mouse_active) cursor.color = FlxColor.WHITE;
		else cursor.color = 0xffef1b3b;
		
		// The left mouse button is currently pressed
		if (FlxG.mouse.pressed) {
			room.send({ mouse: cast Pressed, x: mouse.x, y: mouse.y });

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

			if (cursor.slice_offset > 0.6) cursor.slice_offset -= 20 * dt;
		}
		else if (cursor.slice_offset < 1.3) {
			cursor.slice_offset += 20 * dt;
		}

		// The left mouse button has just been pressed
		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Sounds.click_down__wav);
			room.send({ mouse: cast JustPressed, x: mouse.x, y: mouse.y });
			
			if (aim_timer != null) aim_timer.cancel();
			aim_timer = new FlxTimer().start(0.1, (timer) -> {});
		}

		// The left mouse button has just been released
		if (FlxG.mouse.justReleased) {
			FlxG.sound.play(Sounds.click_up__wav);
			if (player != null && player.state == cast PlayerState.Idle) {
				if (mouse_active)
					room.send({ mouse: cast JustReleased, x: mouse.x, y: mouse.y });
			}
			else {
				room.send({ mouse: cast JustReleased, x: mouse.x, y: mouse.y });
			}
			
			if (aim_timer != null) aim_timer.cancel();
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

	/**
	 * Sorting function that compares the depth of each sprite.
	 * Check out the `get_depth` function in `DepthSprite` to see how it works.
	 */
	function sort_by_depth(o:Int, s1:DepthSprite, s2:DepthSprite):Int 
    {	
      var s1d = s1.depth;
      var s2d = s2.depth;
      if (FlxMath.equal(s1d, s2d)) return s1.z < s2.z ? 1 : -1;
      return s1d > s2d ? 1 : -1;
    }

	function draw_line(v1:FlxPoint, v2:FlxPoint, ?color:FlxColor) {
    canvas.drawCircle(v1.x, v1.y, 4);
    canvas.drawCircle(v2.x, v2.y, 4);
		canvas.draw_dashed_line(v1, v2, (v1.distance(v2).abs()/6).int(), color);
	}
}
