package objects;

class Bobber extends BaseSprite {
  
  var start:FlxPoint;

  public function new (x:Float, y:Float) {
    super(x, y);
    start = FlxPoint.get(x, y);

    loadSlices(Images.bobber__png, 8, 8, 6);
		centerOrigin();
  }
}