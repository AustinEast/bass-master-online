package objects;

import flixel.math.FlxRandom;
import flixel.math.FlxMath;

class Player extends BaseSprite {

  public function new(x, y) {
    super(x, y);

    loadSlices('assets/images/wiz_${Main.random.int(1,5)}.png', 32, 32, 19);
    centerOrigin();
  }
}