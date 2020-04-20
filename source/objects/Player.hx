package objects;

class Player extends FlxSprite {

  public function new(x, y, ghost) {
    super(x, y);

    makeGraphic(32, 32, FlxColor.WHITE);
		centerOrigin();
  }
}