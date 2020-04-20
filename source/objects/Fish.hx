package objects;

class Fish extends FlxSprite {
  public function new(x, y) {
    super(x, y);

    makeGraphic(24, 24, FlxColor.BLUE);
		centerOrigin();
  }
}