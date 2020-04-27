import { Room, Client } from "colyseus";

import { GameState } from './Schema';
import { Game } from './game';

export class GameRoom extends Room {

  maxClients = 6;
  game = new Game();

  onCreate (options:any) {
    this.setState(new GameState());

    const w = this.state.world;
    const map = this.game.generate_map(w.width, w.height, w.tile_width, w.tile_height);
    for (let i = 0 ; i < map.length; i++) w.map.push(map[i]);

    this.setSimulationInterval((dt) => this.update(dt));
    
    this.clock.setInterval(() => {
      this.game.check_fish(this.state);
    }, 3000);
  }

  onJoin (client:Client, options:any) {
    var entity = this.state.createEntity(client.id, 0);
    this.game.place_entity(entity);
  }

  onMessage (client:Client, message:any) {
    const entity = this.state.entities[client.id];
    this.game.process_message(message, entity, this.state);
  }

  onLeave (client:Client, consented:boolean) {
    this.state.removeEntity(client.id);
  }

  onDispose() {
    
  }

  update(elapsed:number) {
    let dt = elapsed/1000;
    this.game.update(dt, this.state);
  }

  broadcastPatch() {
    this.state.time = Date.now();
    return super.broadcastPatch();
  }
}
