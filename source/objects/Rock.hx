package objects;

class Rock extends DepthSprite {

  public function new(x, y) {
    super(x,y);

    var pos = FlxPoint.get(x, y);

    var ran = 1.6.get_random(1);
    scale.set(ran, ran);

    slice_offset = 3.get_random(0.6);
    loadSlices(Images.rock__png, 32, 32, 6);  
    
    this.set_midpoint_position(pos);

    pos.put();
  }
}