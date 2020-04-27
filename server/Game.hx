package;

import zero.utilities.IntPoint;
import zero.utilities.Vec2;
import Types;

using Util;
using Math;
using zero.extensions.FloatExt;
using zero.extensions.ArrayExt;
using zero.utilities.AStar;

@:expose
class Game {

  final player_speed:Float = 200;
  final bobber_speed:Float = 400;
  final max_fish:Int = 4;

  var map:Array<Array<Int>>;
  var fish_count:Int = 0;
  var fish_positions:Array<Vec2>;
  var player_positions:Array<Vec2>;

  public function new() { }

  public function process_message(message:Dynamic, entity:Dynamic, state:Dynamic) {
    if (entity == null) return;

    if (message.mouse != null) {
      var mouse = Vec2.get(message.x, message.y);
      var pos = Vec2.get(entity.x, entity.y);
      switch (cast message.mouse : MouseInput) {
        case Pressed:
          if (entity.state == cast PlayerState.Aiming) {
            var angle = mouse.rad_between(pos).rad_to_deg().to_int();
            if (entity.rotation != angle) entity.rotation = angle;
          }
        case JustPressed:
          if (entity.state == cast PlayerState.Idle) {
            if (mouse.in_circle(pos, 16)) {
              entity.state = cast PlayerState.Aiming;
              var angle = mouse.rad_between(pos).rad_to_deg().to_int() - 180;
					    entity.rotation = angle;
            }
            else {
              entity.targets.length = 0;
              var start = IntPoint.get((pos.x / state.world.tile_width).to_int(), (pos.y / state.world.tile_height).to_int());
              var end = IntPoint.get((mouse.x / state.world.tile_width).to_int(), (mouse.y / state.world.tile_height).to_int());
              var path = map.get_path({
                start: start,
                end: end,
                passable: [1],
                mode: DIAGONAL,
                // simplify: LINE_OF_SIGHT_NO_DIAGONAL
              });
              if (path.length > 0) {
                for (node in path) {
                  var point = state.createPoint(node.x * state.world.tile_width + state.world.tile_width * 0.5, node.y * state.world.tile_height + state.world.tile_height * 0.5);
                  entity.targets.push(point);
                }

                var node = entity.targets.shift();
                entity.target_x = node.x;
                entity.target_y = node.y;
              }
              else {
                entity.target_x = mouse.x;
                entity.target_y = mouse.y;
              }
            }
          }
          if (entity.state == (cast PlayerState.Fishing) || entity.state == cast PlayerState.Casting) {
            var bobber = state.entities[entity.child];
            if (bobber != null) {
              entity.state = cast PlayerState.Reeling;
              bobber.target_x = entity.x;
              bobber.target_y = entity.y;
              bobber.state = cast BobberState.Reeling;
              var fish = state.entities[bobber.child];
              if (fish != null) {
                if (fish.state == cast FishState.Nibbling) {
                  entity.state = cast PlayerState.Caught;
                  fish.state = cast FishState.Caught;
                  fish.target_x = entity.x;
                  fish.target_y = entity.y;
                  fish.parent = entity.id;
                }
                else {}
              }
            }
          }
        case JustReleased:
          if (entity.state == cast PlayerState.Aiming) {
            entity.rotation = mouse.rad_between(pos).rad_to_deg().to_int();
            var bobber = state.createEntity(Util.uuid(), cast EntityType.Bobber);
            bobber.x = entity.x;
            bobber.y = entity.y;
            var pos = Vec2.get(entity.x, entity.y);
            var angle = pos.rad_between(mouse).rad_to_deg();
            var distance = pos.distance(mouse).min(72) * 2;
            var aim_pos = (angle - 180).vector_from_angle(distance) + pos;
            bobber.target_x = aim_pos.x;
            bobber.target_y = aim_pos.y;
            bobber.parent = entity.id;
            entity.state = cast PlayerState.Casting;
            entity.child = bobber.id;
          }
      }
      mouse.put();
      pos.put();
    }
    
  }

  public function update(dt:Float, state:Dynamic) {
    state.forEachEntity((entity) -> {
      if (entity.timer > 0.) entity.timer -= dt;

      var entity_pos = Vec2.get(entity.x, entity.y);

      switch (cast entity.type: EntityType) {
        case Player:
          if (entity.state == cast PlayerState.Idle)
            move_entity_to_target(dt, entity, state);
        case Fish:
          switch (cast entity.state : FishState) {
            case Idle:
              if (move_entity_to_target(dt, entity, state) && entity.timer < 0) {
                var found = false;

                state.forEachEntity((bobber) -> {
                  if (found || bobber.type != (cast EntityType.Bobber) || bobber.child != null ) return;

                  var bobber_pos = Vec2.get(bobber.x, bobber.y);

                  if (entity_pos.distance(bobber_pos) < 40) {

                    entity.state = cast FishState.Interested;
                    entity.target_x = bobber.x;
                    entity.target_y = bobber.y;
                    entity.parent = bobber.id;
                    bobber.child = entity.id;

                    found = true;
                  }
                  bobber_pos.put();
                });

                if (!found) {
                  var i_x = (entity_pos.x / state.world.tile_width).to_int();
                  var i_y = (entity_pos.y / state.world.tile_height).to_int();
                  Util.directions.shuffle();      
                  for (direction in Util.directions) {
                    if (map.get_xy(i_x + direction.x, i_y + direction.y) == 0) {
                      entity.target_x = (i_x + direction.x) * state.world.tile_width + state.world.tile_width * 0.5;
                      entity.target_y = (i_y + direction.y) * state.world.tile_height + state.world.tile_height * 0.5;
                      break;
                    }
                  }

                  // var pos = fish_positions[(fish_positions.length - 1).get_random().to_int()];
                  // entity.target_x = 

                  entity.timer = 3 + Math.random() * 5;
                }
              }
            case Interested:
              if (move_entity_to_target(dt, entity, state)) {
                var bobber = state.entities[entity.parent];
                if (bobber != null) {
                  entity.timer = 1;
                  entity.state = cast FishState.Nibbling;
                }
              }
            case Nibbling:
              if (move_entity_to_target(dt, entity, state) && entity.timer < 0) {
                state.removeEntity(entity.id);
                fish_count--;
              }
            case Caught:
              if (move_entity_to_target(dt, entity, state)) {
                state.removeEntity(entity.id);
                fish_count--;
                var parent = state.entities[entity.parent];
                if (parent != null) {
                  parent.weight += entity.weight;
                  parent.state = cast PlayerState.Idle;
                }
              }
          }
        case Bobber:
          var parent = state.entities[entity.parent];
          if (parent == null) {
            state.removeEntity(entity.id);
            return;
          }

          if (entity.state == cast BobberState.Idle) {
            if (move_entity_to_target(dt, entity, state)) {
              entity.state = cast BobberState.Floating;
              parent.state = cast PlayerState.Fishing;
            }
          }

          else if (entity.state == cast BobberState.Reeling) {
            if (move_entity_to_target(dt, entity, state)) {
              state.removeEntity(entity.id);
              if (parent.state == cast PlayerState.Reeling)
                parent.state = cast PlayerState.Idle;
            }
          }
        }
    });
  }

  public function check_fish(state:Dynamic) {
    // Check if we should spawn fish
    if (fish_count < max_fish) {
      
      var pos = fish_positions[(fish_positions.length - 1).get_random().to_int()];

      fish_count++;
      var fish = state.createEntity(Util.uuid(), cast EntityType.Fish);
      fish.x = pos.x;
      fish.y = pos.y;
      fish.rotation = Math.random() * 360;
      fish.target_x = fish.x;
      fish.target_y = fish.y;
      fish.timer = 3 + Math.random() * 3;
      fish.weight = 1 + (Math.random() * 4).to_int();
    }
  }

  public function generate_map(width:Float, height:Float, tile_width:Float, tile_height:Float):Array<Int> {
    map = Util.generate_map(width, height, tile_width, tile_height);
    
    // Generate cached positions
    fish_positions = [];
    player_positions = [];

    for (y in 0...map.length) for (x in 0...map[y].length) {
      var index = map.get_xy(x, y);
      // Cache possible fish spawn positions
      if (index == 0 && map.surrounding_tiles_match(index, x, y)) {
        fish_positions.push(Vec2.get(x * tile_width + tile_width.half(), y * tile_height + tile_height.half()));
      }
      // Cache possible player spawn positions
      else if (index == 1 && map.surrounding_tiles_match(index, x, y)) {
        player_positions.push(Vec2.get(x * tile_width + tile_width.half(), y * tile_height + tile_height.half()));
      }
    } 
    
    return map.flatten();
  }

  public function place_entity(entity:Dynamic) {
    var pos = player_positions[(player_positions.length - 1).get_random().to_int()];
    entity.target_x = entity.x = pos.x;
    entity.target_y = entity.y = pos.y;
  }

  function move_entity_to_target(dt:Float, entity:Dynamic, state:Dynamic):Bool {
    if (entity == null) return false;

    var entity_pos = Vec2.get(entity.x, entity.y);
    var target_pos = Vec2.get(entity.target_x, entity.target_y);
    
    if (entity_pos.equals(target_pos) && entity.targets.length == 0) {
      entity_pos.put();
      target_pos.put();
      return true;
    }

    var distance = entity_pos.distance(target_pos);
    if (distance < 4) {
      entity_pos.put();
      target_pos.put();

      if (entity.targets.length > 0) {
        var target = entity.targets.shift();
        entity.target_x = target.x;
        entity.target_y = target.y;
        return false;
      }
      else {
        entity.target_x = entity.x;
        entity.target_y = entity.y;
        return true;
      }
    } 
    else {
      var velocity = Vec2.get(0,1);

      velocity.radians = Math.atan2(target_pos.y - entity_pos.y, target_pos.x - entity_pos.x);
      velocity.length = dt * switch(cast entity.type : EntityType) {
        case Player:
          player_speed;
        case Bobber:
          bobber_speed;
        case Fish:
          entity.state == (cast FishState.Caught) ? bobber_speed : player_speed;
      };

      entity.x += velocity.x;
      entity.y += velocity.y;
      entity.rotation = velocity.angle;

      entity_pos.put();
      target_pos.put();
      velocity.put();
      return false;
    }
  }

  // if (map.get_xy(x + 1, y) != index) return false;
    // if (map.get_xy(x + 1, y + 1) != index) return false;
    // if (map.get_xy(x, y + 1) != index) return false;
    // if (map.get_xy(x - 1, y + 1) != index) return false;
    // if (map.get_xy(x - 1, y) != index) return false;
    // if (map.get_xy(x - 1, y - 1) != index) return false;
    // if (map.get_xy(x, y - 1) != index) return false;
    // if (map.get_xy(x + 1, y - 1) != index) return false;

}