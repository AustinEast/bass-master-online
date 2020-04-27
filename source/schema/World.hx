// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;

class World extends Schema {
	@:type("number")
	public var width: Dynamic = 0;

	@:type("number")
	public var height: Dynamic = 0;

	@:type("number")
	public var tile_width: Dynamic = 0;

	@:type("number")
	public var tile_height: Dynamic = 0;

	@:type("array", "uint8")
	public var map: ArraySchema<UInt> = new ArraySchema<UInt>();

}
