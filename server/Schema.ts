import { Schema, ArraySchema, MapSchema, type } from "@colyseus/schema";

export class Point extends Schema {
  @type("number")
  x: number;

  @type("number")
  y: number;
}

export class World extends Schema {
  @type("number")
  width: number = 800;

  @type("number")
  height: number = 800;

  @type("number")
  tile_width: number = 16;

  @type("number")
  tile_height: number = 16;

  @type(["uint8"])
  map: ArraySchema<number> = new ArraySchema<number>();
}

export class Entity extends Schema {
  @type("string")
  id: string;

  @type("number")
  x: number;

  @type("number")
  y: number;

  @type("number")
  rotation: number;

  @type("number")
  target_x: number;

  @type("number")
  target_y: number;

  @type([Point])
  targets: ArraySchema<Point> = new ArraySchema<Point>();

  @type("number")
  weight: number;

  @type("uint8")
  type: number;

  @type("uint8")
  state: number;

  @type("string")
  parent: string;

  @type("string")
  child: string;

  @type("number")
  timer: number;
}

export class GameState extends Schema {
  @type(World)
  world: World = new World();

  @type({ map: Entity })
  entities = new MapSchema<Entity>();

  @type("number")
  time:number = Date.now();

  createEntity (id: string, type: number) {
    let entity = new Entity();
    entity.id = id;
    entity.x = 0;
    entity.y = 0;
    entity.rotation = 0;
    entity.target_x = entity.x;
    entity.target_y = entity.y;
    entity.state = 0;
    entity.weight = 0;
    entity.type = type;
    this.entities[id] = entity;

    return entity;
  }

  removeEntity (id: string) {
    delete this.entities[id];
  }

  forEachEntity(callback:(entity:Entity) => any) {
    for (let id in this.entities) {
      const entity: Entity = this.entities[id];
      if (entity != null)
        callback(entity);
    }
  }

  createPoint(x: number, y: number) {
    var point = new Point();
    point.x = x;
    point.y = y;
    return point;
  }
}