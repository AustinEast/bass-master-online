// 
// THIS FILE HAS BEEN GENERATED AUTOMATICALLY
// DO NOT CHANGE IT MANUALLY UNLESS YOU KNOW WHAT YOU'RE DOING
// 
// GENERATED USING @colyseus/schema 0.5.36
// 

package schema;
import io.colyseus.serializer.schema.Schema;

class Entity extends Schema {
	@:type("string")
	public var id: String = "";

	@:type("number")
	public var x: Dynamic = 0;

	@:type("number")
	public var y: Dynamic = 0;

	@:type("number")
	public var rotation: Dynamic = 0;

	@:type("number")
	public var target_x: Dynamic = 0;

	@:type("number")
	public var target_y: Dynamic = 0;

	@:type("array", Point)
	public var targets: ArraySchema<Point> = new ArraySchema<Point>();

	@:type("number")
	public var weight: Dynamic = 0;

	@:type("uint8")
	public var type: UInt = 0;

	@:type("uint8")
	public var state: UInt = 0;

	@:type("string")
	public var parent: String = "";

	@:type("string")
	public var child: String = "";

	@:type("number")
	public var timer: Dynamic = 0;

}
