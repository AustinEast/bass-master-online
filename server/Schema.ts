import { Schema, ArraySchema, MapSchema, type } from "@colyseus/schema";

export class World extends Schema {
  @type("number")
  width: number = 640;

  @type("number")
  height: number = 480;
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

  @type("number")
  next_target_x: number;

  @type("number")
  next_target_y: number;

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
    entity.x = Math.random() * this.world.width;
    entity.y = Math.random() * this.world.height;
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

  entityArray() {
    const arr = [];
    for (let id in this.entities) {
      const entity: Entity = this.entities[id];
      if (entity != null)
        arr.push(entity);
    }
    return arr;
  }
}