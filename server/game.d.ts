import { Entity } from './Schema';

export class Game {
  constructor();

  process_message(message:any, entity:Entity, state:any):void;

  update(dt:number, state:any):void;

  check_fish(state:any):void;

  generate_map(width:number, height:number, tile_width:number, tile_height:number):Array<number>;

  place_entity(entity:Entity):void;
}