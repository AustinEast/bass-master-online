package objects;

using flixel.math.FlxMath;

class Player extends BaseSprite {

  var l_x = 0.;
  var l_y = 0.;

  var foot = true;

  public function new(x, y) {
    super(x, y);

    l_x = x;
    l_y = y;

    loadSlices('assets/images/wiz_${Main.random.int(1,5)}.png', 32, 32, 19);
    centerOrigin();
  }

  override function update(elapsed:Float) {
    super.update(elapsed);

    if (slice_offset > 0.9 && (!l_x.equal(x) || !l_y.equal(y))) {
      slice_offset = 0.3;
      FlxG.sound.play(foot ? Sounds.step_1__wav : Sounds.step_2__wav, 0.5);
      foot = !foot;
    }
    
    if (slice_offset < 1)
      slice_offset = (slice_offset + 3 * elapsed).min(1);

    l_x = x;
    l_y = y;
  }
}