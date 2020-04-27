package;

import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTile;
import flixel.tile.FlxBaseTilemap;
import flixel.math.FlxVelocity;
import flixel.FlxCamera;
import flixel.tile.FlxTilemap;

typedef TilemapSlice = {
  graphic:FlxTilemapGraphicAsset,
  slices:Int,
  auto_tile:FlxTilemapAutoTiling,
  ?alpha:Float,
  ?draw_index:Int,
  ?use_scale_hack:Bool
}

class DepthTilemap extends FlxTilemap {
  /**
   * Simulated position of the sprite on the Z axis.
   */
   public var z:Float = 0;

	public var local_x:Float;

	public var local_y:Float;
	/**
   * Simulated position of the sprite on the Z axis, relative to the sprite's parent
   */
	public var local_z:Float;

	public var local_angle:Float;

  public var slices:Array<DepthTilemap> = [];
   /**
   * Offset of each 3D "Slice"
   */
  public var slice_offset:Int = 1;

  override function kill() {
		super.kill();
		for (slice in slices) slice.kill();
  }
  
  override function revive() {
		super.revive();
		for (slice in slices) slice.revive();
  }
  
  override public function update(elapsed:Float) 
  {
    super.update(elapsed);

    sync();
    
    for (slice in slices) if (slice.active && slice.exists) slice.update(elapsed);
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
      var i = slices.length - 1;
      while (i > 0)
      {
        var slice = slices[i];
        if (slice.exists && slice.visible) slice.draw();
        i--;
      }

      super.draw();
    }
    
    #if FLX_DEBUG
    override public function drawDebug():Void 
    { 
      for (slice in slices)
      {
        if (slice.exists && slice.visible) slice.drawDebug();
      }

      super.drawDebug();
    }
    #end

    override function set_visible(Value:Bool):Bool {
      for (slice in slices) slice.visible = Value;
      return super.set_visible(Value);
    }

    public function loadDepthMapFromArray(MapData:Array<Int>, WidthInTiles:Int, HeightInTiles:Int, TileSlices:Array<TilemapSlice>, ?TileWidth:Int = 0, ?TileHeight:Int = 0, ?StartingIndex:Int = 0, ?DrawIndex:Int = 1, ?CollideIndex:Int = 1):FlxBaseTilemap<FlxTile> {
      var count = 0;
      
      for (tilemap_slice in TileSlices) {
        for (i in 0...tilemap_slice.slices) {
          var t = count == 0 ? this : getSlice(count);
          t.loadMapFromArray(MapData, WidthInTiles, HeightInTiles, tilemap_slice.graphic, TileWidth, TileHeight, tilemap_slice.auto_tile, StartingIndex, tilemap_slice.draw_index == null ? DrawIndex : tilemap_slice.draw_index, CollideIndex);
          if (tilemap_slice.alpha != null) t.alpha = tilemap_slice.alpha;
          if (tilemap_slice.use_scale_hack != null) t.useScaleHack = tilemap_slice.use_scale_hack;
          count--;
        }
      }

      return this;
    }

    public function sync() {
      for (slice in slices) if (slice.active && slice.exists) {
        slice.x = slice.local_x + x;
        slice.y = slice.local_y + y;
        slice.z = slice.local_z + z;
        slice.angle = slice.local_angle + angle;
  
        slice.sync();
      }
    }

    inline function getSlice(z:Int):DepthTilemap {
      var t = new DepthTilemap();
      t.local_z = -z * slice_offset;
      t.z = this.z + t.local_z;
      t.solid = false;
      t.camera = camera;
      #if FLX_DEBUG
      t.ignoreDrawDebug = true;
      #end
      slices.push(t);
      return t;
    }
}