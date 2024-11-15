package;

import openfl.geom.ColorTransform;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import flixel.math.FlxVelocity;
import flixel.math.FlxVector;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.FlxG;

class DepthSprite extends FlxSprite 
{
  /**
	 * All DepthSprites in this list.
	 */
  public var slices:Array<DepthSprite> = [];
	public var rotation(default, set):Float;
	/**
   * The Entity's Rotation relative to the camera.
   */
	 public var relative_rotation(get, set):Float;
  /**
   *  The Entity's depth in relation to the camera angle
   */
  public var depth(get, never):Float;
  /**
   * Simulated position of the sprite on the Z axis.
   */
	public var z:Float;

	public var local_x:Float;

	public var local_y:Float;
	/**
   * Simulated position of the sprite on the Z axis, relative to the sprite's parent
   */
	public var local_z:Float;

	public var local_angle:Float;

	public var velocity_z:Float;
  /**
   * Used to set whether the Sprite "billboards",
   * or that the Sprite's angle will always remain opposite of the Camera's
   */
  public var billboard(default, set):Bool;
  /**
   * Offset of each 3D "Slice"
   */
  public var slice_offset:Float = 1;
  /**
	 * Amount of Graphics in this list.
	 */
	public var count(get, never):Int;
	
	var _parentRed:Float = 1;
	var _parentGreen:Float = 1;
	var _parentBlue:Float = 1;

  public function new(x:Float = 0, y:Float = 0) {
    super(x, y);
    z = 0;
		rotation = 0;
		velocity_z = 0;
  }
  /**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();

    slices = FlxDestroyUtil.destroyArray(slices);
	}

	/**
	 * Adds the DepthSprite to the slices list.
	 * 
	 * @param	slice	The DepthSprite to add.
	 * @return	The added DepthSprite.
	 */
	 public function add_slice(slice:DepthSprite):DepthSprite {
    if (slices.contains(slice)) return slice;
		
		slices.push(slice);
		slice.velocity.set(0, 0);
		slice.acceleration.set(0, 0);
		slice.scrollFactor.copyFrom(scrollFactor);
		
		slice.alpha = alpha;
		slice._parentRed = color.redFloat;
		slice._parentGreen = color.greenFloat;
		slice._parentBlue = color.blueFloat;
		slice.color = slice.color;

    return slice;
  }

  /**
	 * Removes the DepthSprite from the slices list.
	 * 
	 * @param	slice	The DepthSprite to remove.
	 * @return	The removed DepthSprite.
	 */
	public function remove_slice(slice:DepthSprite):DepthSprite
	{
		var index:Int = slices.indexOf(slice);
		if (index >= 0) slices.splice(index, 1);
		index = slices.indexOf(slice);
		if (index >= 0) slices.splice(index, 1);
		
		return slice;
	}
	
	/**
	 * Removes the DepthSprite from the position in the slices list.
	 * 
	 * @param	Index	Index to remove.
	 */
	public function removeAt(Index:Int = 0):DepthSprite
	{
		if (slices.length < Index || Index < 0) return null;
		
		return remove_slice(slices[Index]);
	}
	
	/**
	 * Removes all slices sprites from this sprite.
	 */
	public function removeAll():Void
	{
		for (slice in slices) remove_slice(slice);
	}

	public function sync() {
		for (slice in slices) if (slice.active && slice.exists) {
			slice.x = slice.local_x + x;
			slice.y = slice.local_y + y;
			slice.z = slice.local_z * slice_offset + z;
			slice.angle = slice.local_angle + angle;
			slice.scale.copyFrom(scale);

			slice.sync();
		}
	}

  override public function update(elapsed:Float) 
  {
		super.update(elapsed);

		z += velocity_z * elapsed;
		
		for (slice in slices) if (slice.active && slice.exists) slice.update(elapsed);

		sync();
		    
    // if billboarded, angle is opposite of camera's
    if (billboard) angle = -FlxG.camera.angle;
	}
	
  /**
   * Extending `getScreenPosition` to set the sprite's z-offset based on the camera angle.
   * We do this here so as to not offset the sprite's actual world space, but just it's visuals.
   */
  override public function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
  {
    if (point == null) point = FlxPoint.get();
    if (Camera == null) Camera = FlxG.camera;

    // This is where the offset is created, then added to the sprite's screen position.
    var _offset = FlxVelocity.velocityFromAngle((Camera.angle + 90) * -1, -z);
    point.set(x + _offset.x, y + _offset.y);
    _offset.put();

    if (pixelPerfectPosition) point.floor();
    
    return point.subtract(Camera.scroll.x * scrollFactor.x, Camera.scroll.y * scrollFactor.y);
  }

  override public function draw():Void 
	{
		super.draw();
		
		for (slice in slices) if (slice.exists && slice.visible) slice.draw();
	}
	
	#if FLX_DEBUG
	override public function drawDebug():Void 
	{
		super.drawDebug();
		
		for (slice in slices) if (slice.exists && slice.visible) slice.drawDebug();
	}
	#end

	override function kill() {
		super.kill();
		for (slice in slices) slice.kill();
	}

	override function revive() {
		super.revive();
		for (slice in slices) slice.revive();
	}


  override function set_color(Color:FlxColor):FlxColor {
    for (slice in slices) slice.color = Color;
    if (color == Color) return Color;
    color = Color;
    updateColorTransform();
    return color;
	}
	
	public function set_slice_offsets(x:Float, y:Float) {
		for (slice in slices) slice.offset.set(x, y);
	}

  /**
   * Loads a 3D Sprite from a Sprite sheet
   * @param img 
	 * @param width 
   * @param height 
   * @param slices 
   */
  public function loadSlices(img:FlxGraphicAsset, width:Int, height:Int, slices:Int):DepthSprite {
    this.slices.resize(0);
    // loadGraphic(img, true, slice_width, slice_height);
    makeGraphic(width, height, FlxColor.TRANSPARENT);
    for (i in 0...slices) loadSlice(img, width, height, i, i);

    return this;
  }
  /**
   * Loads a 3D Sprite from a FlxColor
   * @param color 
	 * @param width 
   * @param height 
   * @param slices 
   */
  public function makeSlices(width:Int, height:Int, slices:Int, color:FlxColor = FlxColor.WHITE):DepthSprite {    
    this.slices.resize(0);
    // makeGraphic(slice_width, slice_height, color);
    makeGraphic(width, height, FlxColor.TRANSPARENT);
    for (i in 0...slices + 1) makeSlice(width, height, i, color);

    return this;
  }

  inline function loadSlice(img:FlxGraphicAsset, width:Int, height:Int, z:Int, frame:Int = 0) {
    var s = getSlice(z);
    s.loadGraphic(img, true, width, height);
    s.animation.frameIndex = frame;
  }

  inline function makeSlice(width:Int, height:Int, z:Int, color:FlxColor = FlxColor.WHITE) {
    var s = getSlice(z);
    s.makeGraphic(width, height, color);
  }

  inline function getSlice(z:Int):DepthSprite {
    var s = new DepthSprite(x, y);
    s.local_z = -z;
    s.z = this.z + s.local_z;
    s.solid = false;
    s.camera = camera;
    #if FLX_DEBUG
    s.ignoreDrawDebug = true;
    #end
    add_slice(s);
    return s;
  }

  public inline function anchor_origin():Void {
		origin.set(frameWidth * 0.5, frameHeight);
	}

  inline function get_relative_rotation() return ((-rotation - FlxG.camera.angle + 180) % 360);

  inline function set_relative_rotation(value:Float) return rotation = ((value - FlxG.camera.angle) % 360);

	var depth_pos:FlxPoint = new FlxPoint();
  /**
   *  Function inspired by @01010111
   */
  function get_depth():Float {
    depth_pos.set(x, y);
    var d = FlxVelocity.velocityFromAngle(depth_pos.degrees + FlxG.camera.angle, depth_pos.lengthSquared);
    var d_y = d.y;
    d.put();

    return d_y;
  }

  inline function set_billboard(value:Bool):Bool {
    if (value) anchor_origin();
		else {
			centerOrigin();
			angle = rotation;
		}
    return billboard = value;
  }

  override function set_width(value:Float) {
    for (slice in slices) slice.width = value;
    return super.set_width(value);
  }

  override function set_height(value:Float) {
    for (slice in slices) slice.height = value;
    return super.set_height(value);
  }

	override function set_visible(Value:Bool):Bool {
		for (slice in slices) slice.visible = Value;
		return super.set_visible(Value);
	}

  override function set_alpha(Alpha:Float):Float
	{
		Alpha = FlxMath.bound(Alpha, 0, 1);
		if (Alpha == alpha)
			return alpha;
				
		if ((alpha != 1) || (color != 0x00ffffff))
		{
			var red:Float = (color >> 16) * _parentRed / 255;
			var green:Float = (color >> 8 & 0xff) * _parentGreen / 255;
			var blue:Float = (color & 0xff) * _parentBlue / 255;
			
			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(red, green, blue, alpha);
			}
			else
			{
				colorTransform.redMultiplier = red;
				colorTransform.greenMultiplier = green;
				colorTransform.blueMultiplier = blue;
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.redMultiplier = 1;
				colorTransform.greenMultiplier = 1;
				colorTransform.blueMultiplier = 1;
				colorTransform.alphaMultiplier = 1;
			}
			useColorTransform = false;
		}
		dirty = true;
		
		if (slices != null)
		{
			for (slice in slices)
				slice.alpha = alpha;
		}
		
		return alpha;
	}

	override function set_flipX(v:Bool) {
		if (slices != null) for (slice in slices) if (slice.exists && slice.active) slice.flipX = v;
		return super.set_flipX(v);
	}
	
	override function set_facing(Direction:Int):Int
	{
		super.set_facing(Direction);
		if (slices != null) for (slice in slices)	{
			if (slice.exists && slice.active) slice.facing = Direction;
		}
		
		return Direction;
	}

	inline function set_rotation(value:Float) {
		if (!billboard) angle = value;
		return rotation = value;
	}
	
	inline function get_count():Int 
	{ 
		return slices.length; 
	}
}