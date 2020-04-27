package objects;

class BaseSprite extends DepthSprite {
  
  var scale_tween:FlxTween;

  public var state(default, set):Int = 0;

  function set_state(state:Int) {
    return this.state = state;
  }

  public function new (x, y) {
    super(x, y);

    scale.set();
    if (scale_tween != null) scale_tween.cancel();
    scale_tween = FlxTween.tween(scale, {x: 1, y: 1}, 0.3);
  }

  // override function kill() {
  //   if (scale_tween != null) scale_tween.cancel();
  //   scale_tween = FlxTween.tween(scale, {x: 0, y: 0}, 1, {onComplete: (tween) -> {
  //     alive = false;
  //     exists = false;
  //     for (slice in slices) slice.kill();
  //   }});
  // }

  override function destroy() {
    super.destroy();

    if (scale_tween != null) scale_tween.cancel();
  }
}