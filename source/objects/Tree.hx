package objects;

class Tree extends DepthSprite {

  public var shadow:FlxSprite;

  public function new(x, y) {
    super(x,y);

    var pos = FlxPoint.get(x, y);

    slice_offset = 16.get_random(5);
    loadSlices(Images.tree_trunk__png, 128, 128, 11);
    // centerOrigin();
    this.make_and_center_hitbox(27, 27);
    set_slice_offsets(offset.x, offset.y);
    this.set_midpoint_position(pos);
    
    shadow = new FlxSprite();
    shadow.loadGraphic(Images.tree_trunk_shadow__png);
    shadow.centerOrigin();
    shadow.set_midpoint_position(pos);

    pos.put();
  }
  
  override function destroy() {
    super.destroy();

    shadow.destroy();
  }
}