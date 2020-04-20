package;

import haxe.Timer;
import Types;
import zero.utilities.Vec2;
import schema.GameState;
import schema.Entity;
import schema.Player;

using Util;
using Math;
using zero.extensions.FloatExt;

@:expose
class Game {

  final player_speed:Float = 200;
  final bobber_speed:Float = 400;
  final max_fish:Int = 4;

  var fish_timer:Timer;
  var fish_count:Int = 0;

  public function new() { }

  public function process_message(message:Dynamic, entity:Entity, state:Dynamic) {
    if (entity == null) return;

    if (message.mouse != null) {
      var mouse = Vec2.get(message.x, message.y);
      var pos = Vec2.get(entity.x, entity.y);
      switch (cast message.mouse : MouseInput) {
        case Pressed:
          if (entity.state == cast PlayerState.Aiming) {
            var angle = mouse.rad_between(pos).rad_to_deg().to_int() - 180;
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
              entity.target_x = mouse.x;
              entity.target_y = mouse.y;
            }
          }
          if (entity.state == (cast PlayerState.Fishing) || entity.state == cast PlayerState.Casting) {
            untyped var bobber = state.entities[entity.child];
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
            entity.rotation = mouse.rad_between(pos).rad_to_deg().to_int() - 180;
            var bobber:Entity = state.createEntity(Util.uuid(), cast EntityType.Bobber);
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
    var arr:Array<Entity> = state.entityArray();
    for (entity in arr) {
      if (entity.timer > 0) entity.timer -= dt;

      var entity_pos = Vec2.get(entity.x, entity.y);

      switch (cast entity.type: EntityType) {
        case Player:
          if (entity.state == cast PlayerState.Idle)
            move_entity_to_target(dt, entity);
        case Fish:
          switch (cast entity.state : FishState) {
            case Idle:
              if (move_entity_to_target(dt, entity) && entity.timer < 0) {
                var found = false;

                var arr:Array<Entity> = state.entityArray();
                for (bobber in arr) {
                  if (bobber.type != (cast EntityType.Bobber) || bobber.child != null ) continue;

                  var bobber_pos = Vec2.get(bobber.x, bobber.y);

                  if (entity_pos.distance(bobber_pos) < 40) {

                    entity.state = cast FishState.Interested;
                    entity.target_x = bobber.x;
                    entity.target_y = bobber.y;
                    entity.parent = bobber.id;
                    bobber.child = entity.id;

                    found = true;

                    bobber_pos.put();

                    break;
                  }
                  bobber_pos.put();
                }

                if (found) {

                }
                else {
                  entity.target_x = entity.next_target_x;
                  entity.target_y = entity.next_target_y;
                  
                  var vec2 = (Math.random() * 360).vector_from_angle(25);
                  vec2.x += entity.x;
                  vec2.y += entity.y;
                  entity.next_target_x = vec2.x;
                  entity.next_target_y = vec2.y;
                  vec2.put();

                  entity.timer = 3 + Math.random() * 5;
                }
              }
            case Interested:
              if (move_entity_to_target(dt, entity)) {
                untyped var bobber = state.entities[entity.parent];
                if (bobber != null) {
                  entity.timer = 1;
                  entity.state = cast FishState.Nibbling;
                }
              }
            case Nibbling:
              if (move_entity_to_target(dt, entity) && entity.timer < 0) {
                state.removeEntity(entity.id);
                fish_count--;
              }
            case Caught:
              if (move_entity_to_target(dt, entity)) {
                state.removeEntity(entity.id);
                fish_count--;
                untyped var parent = state.entities[entity.parent];
                if (parent != null) {
                  parent.weight += entity.weight;
                  parent.state = cast PlayerState.Idle;
                }
              }
          }
        case Bobber:
          untyped var parent = state.entities[entity.parent];
          if (parent == null) {
            state.removeEntity(entity.id);
            return;
          }

          if (entity.state == cast BobberState.Idle) {
            if (move_entity_to_target(dt, entity)) {
              entity.state = cast BobberState.Floating;
              parent.state = cast PlayerState.Fishing;
            }
          }

          else if (entity.state == cast BobberState.Reeling) {
            if (move_entity_to_target(dt, entity)) {
              state.removeEntity(entity.id);
              if (parent.state == cast PlayerState.Reeling)
                parent.state = cast PlayerState.Idle;
            }
          }
        }
    }
  }

  public function check_fish(state:Dynamic) {
    // Check if we should spawn fish
    if (fish_count < max_fish) {
      fish_count++;
      var fish = state.createEntity(Util.uuid(), cast EntityType.Fish);
      fish.x = Math.random() * state.world.width;
      fish.y = Math.random() * state.world.height;
      fish.target_x = fish.x;
      fish.target_y = fish.y;
      fish.timer = 3 + Math.random() * 3;
      fish.weight = 1 + (Math.random() * 4).to_int();
      
      var vec2 = (Math.random() * 360).vector_from_angle(25);
      vec2.x += fish.x;
      vec2.y += fish.y;
      fish.next_target_x = vec2.x;
      fish.next_target_y = vec2.y;
      vec2.put();
    }
  }

  function move_entity_to_target(dt:Float, entity:Entity):Bool {
    if (entity == null) return false;

    var entity_pos = Vec2.get(entity.x, entity.y);
    var target_pos = Vec2.get(entity.target_x, entity.target_y);
    
    if (entity_pos.equals(target_pos)) {
      entity_pos.put();
      target_pos.put();
      return true;
    }

    var distance = entity_pos.distance(target_pos);
    if (distance < 4) {
      entity.target_x = entity.x;
      entity.target_y = entity.y;
      entity_pos.put();
      target_pos.put();
      return true;
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
}