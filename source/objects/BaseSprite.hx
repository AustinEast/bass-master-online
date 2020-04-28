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

  override function revive() {
    super.revive();
    scale.set();
    if (scale_tween != null) scale_tween.cancel();
    scale_tween = FlxTween.tween(scale, {x: 1, y: 1}, 0.3);
  }

  override function kill() {
    alive = false;
    if (scale_tween != null) scale_tween.cancel();
    scale_tween = FlxTween.tween(scale, {x: 0, y: 0}, 0.5, {onComplete: (tween) -> {
      exists = false;
    }});
  }

  override function destroy() {
    super.destroy();

    if (scale_tween != null) scale_tween.cancel();
  }
}