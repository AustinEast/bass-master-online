"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
const schema_1 = require("@colyseus/schema");
class Point extends schema_1.Schema {
}
__decorate([
    schema_1.type("number")
], Point.prototype, "x", void 0);
__decorate([
    schema_1.type("number")
], Point.prototype, "y", void 0);
exports.Point = Point;
class World extends schema_1.Schema {
    constructor() {
        super(...arguments);
        this.width = 800;
        this.height = 800;
        this.tile_width = 16;
        this.tile_height = 16;
        this.map = new schema_1.ArraySchema();
    }
}
__decorate([
    schema_1.type("number")
], World.prototype, "width", void 0);
__decorate([
    schema_1.type("number")
], World.prototype, "height", void 0);
__decorate([
    schema_1.type("number")
], World.prototype, "tile_width", void 0);
__decorate([
    schema_1.type("number")
], World.prototype, "tile_height", void 0);
__decorate([
    schema_1.type(["uint8"])
], World.prototype, "map", void 0);
exports.World = World;
class Entity extends schema_1.Schema {
    constructor() {
        super(...arguments);
        this.targets = new schema_1.ArraySchema();
    }
}
__decorate([
    schema_1.type("string")
], Entity.prototype, "id", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "x", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "y", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "rotation", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "target_x", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "target_y", void 0);
__decorate([
    schema_1.type([Point])
], Entity.prototype, "targets", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "weight", void 0);
__decorate([
    schema_1.type("uint8")
], Entity.prototype, "type", void 0);
__decorate([
    schema_1.type("uint8")
], Entity.prototype, "state", void 0);
__decorate([
    schema_1.type("string")
], Entity.prototype, "parent", void 0);
__decorate([
    schema_1.type("string")
], Entity.prototype, "child", void 0);
__decorate([
    schema_1.type("number")
], Entity.prototype, "timer", void 0);
exports.Entity = Entity;
class GameState extends schema_1.Schema {
    constructor() {
        super(...arguments);
        this.world = new World();
        this.entities = new schema_1.MapSchema();
        this.time = Date.now();
    }
    createEntity(id, type) {
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
    removeEntity(id) {
        delete this.entities[id];
    }
    forEachEntity(callback) {
        for (let id in this.entities) {
            const entity = this.entities[id];
            if (entity != null)
                callback(entity);
        }
    }
    createPoint(x, y) {
        var point = new Point();
        point.x = x;
        point.y = y;
        return point;
    }
}
__decorate([
    schema_1.type(World)
], GameState.prototype, "world", void 0);
__decorate([
    schema_1.type({ map: Entity })
], GameState.prototype, "entities", void 0);
__decorate([
    schema_1.type("number")
], GameState.prototype, "time", void 0);
exports.GameState = GameState;
