import { Entity } from './Schema';

export class Game {
  constructor();

  process_message(message:any, entity:Entity, state:any):void;

  update(dt:number, state:any):void;

  check_fish(state:any):void;
}