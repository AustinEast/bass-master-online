// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;

class GameState extends Schema {
	@:type("ref", World)
	public var world: World = new World();

	@:type("map", Entity)
	public var entities: MapSchema<Entity> = new MapSchema<Entity>();

	@:type("number")
	public var time: Dynamic = 0;

}
