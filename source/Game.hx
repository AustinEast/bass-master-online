package source;

import haxe.Timer;
import zero.utilities.Vec2;
import source.Types;

using Std;
using zero.extensions.FloatExt;

class Game {

  public var on_add:Null<Entity->Void>;
  public var on_remove:Null<Entity->Void>;
  public var entities:Map<String,Entity>;

  final player_speed:Float = 200;
  final bobber_speed:Float = 400;
  final server_latency:Float = 200;

  var client_id:String;
  var timer:Timer;
  var last_sync:Null<GameState>;
  var last_sync_time:Float = 0;

  public function new(?client_id:String) {
    this.client_id = client_id;
    entities = [];

    start();
  }

  public function start() {
     // Set up a Timer to act as an update loop
     timer = new Timer(16);
     timer.run = () -> {
      update(16 / 1000);
    }
  }
  
  public function stop() {
    timer.stop();
  }

  public function dispose() {
    stop();
    timer = null;
    entities.clear();
    entities = null;
    on_add = null;
    on_remove = null;
  }

  public function add_entity(entity:Entity) {
    if (!entities.exists(entity.id)) {
      entities.set(entity.id, entity);
      if (on_add != null) on_add(entity);
    }
  }

  public function update_entity(data:Dynamic) {
    if (data.id == null) return;

    var entity = entities.get(data.id);
    if (entity == null) return;

    // required fields
    if (data.x != null) entity.x = data.x;
    if (data.y != null) entity.y = data.y;
    if (data.rotation != null) entity.rotation = data.rotation;
    if (data.type != null) entity.type = data.type;

    // optional fields
    if (data.state != null) entity.state = data.state;
    if (data.weight != null) entity.weight = data.weight;
    if (data.child != null) entity.child = data.child;
    if (data.parent != null) entity.parent = data.parent;
    if (data.timer != null) entity.timer = data.timer;
    if (data.target != null) entity.target = data.target;
  }

  public function remove_entity(uuid:String) {
    var match = entities.get(uuid);
    if (match != null) {
      entities.remove(uuid);
      if (on_remove != null) on_remove(match);
    }
  }

  public function save():GameState return {
    entities: [for (e in entities) e],
    time: Date.now().getTime()
  }

  public function sync(state:GameState) {
    last_sync = state;
    last_sync_time = 0;
  
    for (entity in state.entities) {
      var match = null;
      var client = false;
      for (e in entities) {
        if (entity.id == e.id) {
          if (client_id != null && entity.id == client_id) client = true;
          match = e;
          break;
        }
      }

      if (match == null) add_entity(entity);
      else {
        // Dont sync these if the entity is the client
        // if (!client) match.x = entity.x;
        // if (!client) match.y = entity.y;
        // if (!client) match.rotation = entity.rotation;
        // if (!client) match.target = entity.target;

        match.type = entity.type;
        match.state = entity.state;
        match.weight = entity.weight;
        match.child = entity.child;
        match.parent = entity.parent;
        match.timer = entity.timer;
      }
    }
  }

  function update(dt:Float) {
    last_sync_time += dt;
    var interp = last_sync_time.norm(0, server_latency);
    for (entity in entities) {
      update_timers(dt, entity);

      // if this is the server or the client's entity, update it now
      if (client_id == null || client_id == entity.id) {
        move_entity_towards_target(dt, entity);
      }
      // otherwise interpolate it
      else if (last_sync != null) {
        var match = null;
        for (e in last_sync.entities) {
          if (entity.id == e.id) {
            match = e;
            break;
          }
        }

        if (match != null) {
          entity.x = interp.lerp(entity.x, match.x);
          entity.y = interp.lerp(entity.y, match.y);
          entity.rotation = interp.lerp(entity.rotation, match.rotation);
        }
      }
    }

    if (last_sync != null && last_sync_time > server_latency) last_sync = null;
  }

  function update_timers(dt:Float, entity:Entity) {
    if (entity.timer != null) {
      entity.timer -= dt;
      if (entity.timer <= 0) {
        entity.timer = null;
        if (entity.type == cast EntityType.Fish) {
          if (entity.state == (cast EntityState.Idle) && client_id == null) {
            var vec2 = (Math.random() * 360).vector_from_angle(25);
            vec2.x += entity.x;
            vec2.y += entity.y;
            
            entity.target = { x: vec2.x, y: vec2.y }
            vec2.put();
          }
          else if (entity.state == cast EntityState.Nibbling) {
            remove_entity(entity.id);
          }
        }
      }
    }
  }

  function move_entity_towards_target(dt:Float, entity:Entity) {
    if (entity.target == null) return;

    var entity_pos = Vec2.get(entity.x, entity.y);
    var target_pos = Vec2.get(entity.target.x, entity.target.y);
    var distance = entity_pos.distance(target_pos);
      
    if (distance < 6) {
      entity.target = null;

      // If the entity is a bobber and its reached its destination, handle it
      if (entity.type == (cast EntityType.Bobber) && entity.state == (cast EntityState.Reeling) && entity.parent != null) {
        var parent = entities.get(entity.parent);
        if (parent != null) {
          if (parent.state == cast EntityState.Casting)
            entity.state = parent.state = cast EntityState.Fishing;
          else if (parent.state == cast EntityState.Reeling) {
            parent.state = cast EntityState.Idle;
            parent.child = null;
          }
          remove_entity(entity.id);
        }
      }
      else if (entity.type == cast EntityType.Fish) {
        if (entity.state == cast EntityState.Idle) {
          // check if a bobber is in radius
          var found = false;

          for (bobber in entities) {
            if (bobber.type != (cast EntityType.Bobber) || bobber.child != null ) continue;

            var bobber_pos = Vec2.get(bobber.x, bobber.y);

            if (entity_pos.distance(bobber_pos) < 40) {

              entity.state = cast EntityState.Interested;
              entity.target = { x: bobber.x, y: bobber.y }
              entity.parent = bobber.id;
              bobber.child = entity.id;

              found = true;

              bobber_pos.put();

              break;
            }
            bobber_pos.put();
          }

          if (!found) {
            entity.timer = Math.random() * 2 + 3;
          }
        }
        else if (entity.state == (cast EntityState.Interested) && entity.parent != null) {
          var bobber = entities.get(entity.parent);
          if (bobber != null) {
            entity.timer = 1;
            entity.state = cast EntityState.Nibbling;
          }
        }
        else if (entity.state == cast EntityState.Caught) {
          if (entity.parent != null) {
            var player = entities.get(entity.parent);
            if (player != null) {
              player.weight += entity.weight;
              player.state = cast EntityState.Idle;
              player.child = null;
            }
          }
          remove_entity(entity.id);
        }
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
          entity.state == (cast EntityState.Caught) ? bobber_speed : player_speed;
      };

      entity.x += velocity.x;
      entity.y += velocity.y;
      entity.rotation = velocity.angle;

      velocity.put();
    }

    entity_pos.put();
    target_pos.put();
  }
}