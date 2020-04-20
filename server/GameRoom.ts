import { Room, Client } from "colyseus";
import { GameState } from './Schema';
import { Game } from './game';

export class GameRoom extends Room {

  maxClients = 6;
  game = new Game();

  onCreate (options:any) {
    this.setState(new GameState());
    this.setSimulationInterval((dt) => this.update(dt));
    this.clock.setInterval(() => {
      this.game.check_fish(this.state);
    }, 3000);
  }

  onJoin (client:Client, options:any) {
    this.state.createEntity(client.id, 0);
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
