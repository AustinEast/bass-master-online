package client.objects;

class Bobber extends FlxSprite {
  
  var start:FlxPoint;

  public function new (x:Float, y:Float) {
    super(x, y);
    start = FlxPoint.get(x, y);

    makeGraphic(8,8, FlxColor.RED);
		centerOrigin();
  }
}