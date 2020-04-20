"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const colyseus_1 = require("colyseus");
const Schema_1 = require("./Schema");
const game_1 = require("./game");
class GameRoom extends colyseus_1.Room {
    constructor() {
        super(...arguments);
        this.maxClients = 6;
        this.game = new game_1.Game();
    }
    onCreate(options) {
        this.setState(new Schema_1.GameState());
        this.setSimulationInterval((dt) => this.update(dt));
        this.clock.setInterval(() => {
            this.game.check_fish(this.state);
        }, 3000);
    }
    onJoin(client, options) {
        this.state.createEntity(client.id, 0);
    }
    onMessage(client, message) {
        const entity = this.state.entities[client.id];
        this.game.process_message(message, entity, this.state);
    }
    onLeave(client, consented) {
        this.state.removeEntity(client.id);
    }
    onDispose() {
    }
    update(elapsed) {
        let dt = elapsed / 1000;
        this.game.update(dt, this.state);
    }
    broadcastPatch() {
        this.state.time = Date.now();
        return super.broadcastPatch();
    }
}
exports.GameRoom = GameRoom;
