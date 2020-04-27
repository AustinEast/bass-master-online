package objects;

class Rock extends DepthSprite {

  public function new(x, y) {
    super(x,y);

    var pos = FlxPoint.get(x, y);

    slice_offset = 2.get_random(0.2);
    loadSlices(Images.rock__png, 32, 32, 6);    

    pos.put();
  }
}