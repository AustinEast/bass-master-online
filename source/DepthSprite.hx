package util;

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
	public var children(default, null):Array<DepthSprite> = [];
  public var slices:Array<DepthSprite> = [];
  public var rotation(default, set):Float;
  /**
   *  The Entity's depth in relation to the camera angle
   */
  public var depth(get, never):Float;
  /**
   * Simulated position of the sprite on the Z axis.
   */
  public var z:Float;
	public var velocityZ:Float;
  /**
   * Used to set whether the Sprite "billboards",
   * or that the Sprite's angle will always remain opposite of the Camera's
   */
  public var billboard(default, set):Bool;
  /**
   * A `relative_` var for this sprite's children's z.
   */
  public var relativeZ:Float;
  /**
   * The Entity's Rotation relative to the camera.
   */
  public var relative_rotation(get, set):Float;
  /**
	 * X position of this sprite relative to parent, 0 by default
	 */
	public var relativeX:Float = 0;
	/**
	 * Y position of this sprite relative to parent, 0 by default
	 */
	public var relativeY:Float = 0;
	/**
	 * Angle of this sprite relative to parent
	 */
	public var relativeAngle:Float = 0;
	/**
	 * Angular velocity relative to parent sprite
	 */
	public var relativeAngularVelocity:Float = 0;
	/**
	 * Angular acceleration relative to parent sprite
	 */
	public var relativeAngularAcceleration:Float = 0;
	
	public var relativeAlpha:Float = 1;
	/**
	 * Scale of this sprite relative to parent
	 */
	public var relativeScale(default, null):FlxPoint = FlxPoint.get(1, 1);
	/**
	 * Velocity relative to parent sprite
	 */
	public var relativeVelocity(default, null):FlxPoint = FlxPoint.get();
	/**
	 * Acceleration relative to parent sprite
	 */
	public var relativeAcceleration(default, null):FlxPoint = FlxPoint.get();
  /**
   * Offset of each 3D "Slice"
   */
  public var slice_offset:Int = 1;
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
  }
  /**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		relativeScale = FlxDestroyUtil.put(relativeScale);
		relativeVelocity = FlxDestroyUtil.put(relativeVelocity);
		relativeAcceleration = FlxDestroyUtil.put(relativeAcceleration);
		children = FlxDestroyUtil.destroyArray(children);
    slices = FlxDestroyUtil.destroyArray(slices);
	}
  /**
	 * Adds the DepthSprite to the children list.
	 * 
	 * @param	child	The DepthSprite to add.
	 * @return	The added DepthSprite.
	 */
  public function add(child:DepthSprite):DepthSprite {
    if (children.contains(child)) return child;
		
		children.push(child);
		child.velocity.set(0, 0);
		child.acceleration.set(0, 0);
		child.scrollFactor.copyFrom(scrollFactor);
		
		child.alpha = child.relativeAlpha * alpha;
		child._parentRed = color.redFloat;
		child._parentGreen = color.greenFloat;
		child._parentBlue = color.blueFloat;
		child.color = child.color;

    return child;
  }

  /**
	 * Removes the DepthSprite from the children list.
	 * 
	 * @param	child	The DepthSprite to remove.
	 * @return	The removed DepthSprite.
	 */
	public function remove(child:DepthSprite):DepthSprite
	{
		var index:Int = children.indexOf(child);
		if (index >= 0) children.splice(index, 1);
		index = slices.indexOf(child);
		if (index >= 0) slices.splice(index, 1);
		
		return child;
	}
	
	/**
	 * Removes the DepthSprite from the position in the children list.
	 * 
	 * @param	Index	Index to remove.
	 */
	public function removeAt(Index:Int = 0):DepthSprite
	{
		if (children.length < Index || Index < 0) return null;
		
		return remove(children[Index]);
	}
	
	/**
	 * Removes all children sprites from this sprite.
	 */
	public function removeAll():Void
	{
		for (child in children) remove(child);
	}
	
	inline function preUpdate(elapsed:Float):Void 
	{
		#if FLX_DEBUG
		FlxBasic.activeCount++;
		#end
		
		last.set(x, y);
		
		for (child in children) if (child.active && child.exists) child.preUpdate(elapsed);
	}

  override public function update(elapsed:Float) 
  {
    preUpdate(elapsed);
		
		for (child in children) if (child.active && child.exists) child.update(elapsed);
		
		postUpdate(elapsed);
    
    // if billboarded, angle is opposite of camera's
    if (billboard) angle = -FlxG.camera.angle;
  }
  /**
   * Overriding this function provided by FlxNestedSprite to set this sprite's children's z variable
   * @param elapsed 
   */
  public function postUpdate(elapsed:Float) {
    if (moves)
			updateMotion(elapsed);
		
		wasTouching = touching;
		touching = FlxObject.NONE;
		animation.update(elapsed);
		
		var delta:Float;
		var velocityDelta:Float;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeAngularVelocity, relativeAngularAcceleration, angularDrag, maxAngular, elapsed) - relativeAngularVelocity);
		relativeAngularVelocity += velocityDelta; 
		relativeAngle += relativeAngularVelocity * elapsed;
		relativeAngularVelocity += velocityDelta;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.x, relativeAcceleration.x, drag.x, maxVelocity.x, elapsed) - relativeVelocity.x);
		relativeVelocity.x += velocityDelta;
		delta = relativeVelocity.x * elapsed;
		relativeVelocity.x += velocityDelta;
		relativeX += delta;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.y, relativeAcceleration.y, drag.y, maxVelocity.y, elapsed) - relativeVelocity.y);
		relativeVelocity.y += velocityDelta;
		delta = relativeVelocity.y * elapsed;
		relativeVelocity.y += velocityDelta;
		relativeY += delta;
		
		for (child in children)
		{
			if (child.active && child.exists)
			{
				child.velocity.x = child.velocity.y = 0;
				child.acceleration.x = child.acceleration.y = 0;
				child.angularVelocity = child.angularAcceleration = 0;
				child.postUpdate(elapsed);
				
				if (isSimpleRender(camera))
				{
					child.x = x + child.relativeX - offset.x;
					child.y = y + child.relativeY - offset.y;
				}
				else
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					var cos:Float = Math.cos(radians);
					var sin:Float = Math.sin(radians);
					
					var dx = width / 2 - child.width / 2 - offset.x;
					dx += scale.x * cos * (child.relativeX - width / 2 + child.width / 2) ;
					dx -= scale.y * sin * (child.relativeY - height / 2 + child.height / 2) ;
					
					var dy = height / 2 - child.height / 2 - offset.y;
					dy += scale.y * cos * (child.relativeY - height / 2 + child.height / 2);
					dy += scale.x * sin * (child.relativeX - width / 2 + child.width / 2) ;					
					
					child.x = x +  dx;
					child.y = y +  dy;
				}
				
        child.z = z + child.relativeZ;
				child.angle = angle + child.relativeAngle;
				child.scale.x = scale.x * child.relativeScale.x;
				child.scale.y = scale.y * child.relativeScale.y;
				
				child.velocity.x = velocity.x;
				child.velocity.y = velocity.y;
				child.acceleration.x = acceleration.x;
				child.acceleration.y = acceleration.y;
			}
		}
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
		
		for (child in children)
		{
			if (child.exists && child.visible) child.draw();
		}
	}
	
	#if FLX_DEBUG
	override public function drawDebug():Void 
	{
		super.drawDebug();
		
		for (child in children)
		{
			if (child.exists && child.visible) child.drawDebug();
		}
	}
	#end

	override function kill() {
		super.kill();
		for (slice in slices) slice.kill();
	}

  override function set_color(Color:FlxColor):FlxColor {
    for (child in children) child.color = Color;
    if (color == Color) return Color;
    color = Color;
    updateColorTransform();
    return color;
  }
  /**
   * Loads a 3D Sprite from a Sprite sheet
   * @param img 
   * @param slices 
   * @param slice_width 
   * @param slice_height 
   */
  public function loadSlices(img:FlxGraphicAsset, slices:Int, slice_width:Int, slice_height:Int):DepthSprite {
    this.slices.resize(0);
    // loadGraphic(img, true, slice_width, slice_height);
    makeGraphic(slice_width, slice_height, FlxColor.TRANSPARENT);
    for (i in 0...slices) loadSlice(img, i, i, slice_width, slice_height);

    return this;
  }
  /**
   * Loads a 3D Sprite from a FlxColor
   * @param color 
   * @param slices 
   * @param slice_width 
   * @param slice_height 
   */
  public function makeSlices(color:FlxColor = FlxColor.WHITE, slices:Int, slice_width:Int, slice_height:Int):DepthSprite {    
    this.slices.resize(0);
    // makeGraphic(slice_width, slice_height, color);
    makeGraphic(slice_width, slice_height, FlxColor.TRANSPARENT);
    for (i in 0...slices + 1) makeSlice(color, i, slice_width, slice_height);

    return this;
  }

  inline function loadSlice(img:FlxGraphicAsset, z:Int, frame:Int = 0, width:Int, height:Int) {
    var s = getSlice(z);
    s.loadGraphic(img, true, width, height);
    s.animation.frameIndex = frame;
    add(s);
  }

  inline function makeSlice(color:FlxColor = FlxColor.WHITE, z:Int, width:Int, height:Int) {
    var s = getSlice(z);
    s.makeGraphic(width, height, color);
    add(s);
  }

  inline function getSlice(z:Int):DepthSprite {
    var s:DepthSprite;
    s = new DepthSprite(x, y);
    s.relativeZ = -z * slice_offset;
    s.z = this.z + s.relativeZ;
    s.solid = false;
    s.camera = camera;
    #if FLX_DEBUG
    s.ignoreDrawDebug = true;
    #end
    slices.push(s);
    return s;
  }

  public inline function anchor_origin():Void {
		origin.set(frameWidth * 0.5, frameHeight);
	}

  public inline function set_children_visibility(value:Bool) {
    for (child in children) child.visible = value;
  }

  inline function get_relative_rotation() return ((-rotation - FlxG.camera.angle + 180) % 360); //.get_relative_degree();

  inline function set_relative_rotation(value:Float) return rotation = ((value - FlxG.camera.angle) % 360); //.get_relative_degree();

	var depth_pos:FlxVector = new FlxVector();
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
		
		alpha = Alpha * relativeAlpha;
		
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
		
		if (children != null)
		{
			for (child in children)
				child.alpha = alpha;
		}
		
		return alpha;
	}

	override function set_flipX(v:Bool) {
		if (children != null) for (child in children) if (child.exists && child.active) child.flipX = v;
		return super.set_flipX(v);
	}
	
	override function set_facing(Direction:Int):Int
	{
		super.set_facing(Direction);
		if (children != null) for (child in children)	{
			if (child.exists && child.active) child.facing = Direction;
		}
		
		return Direction;
	}

	inline function set_rotation(value:Float) {
		if (!billboard) angle = value;
		return rotation = value;
	}
	
	inline function get_count():Int 
	{ 
		return children.length; 
	}
}