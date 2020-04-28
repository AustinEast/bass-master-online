package states;

import zero.flixel.states.sub.FadeOut;

class ClickState extends FlxState {
  override function create() {
    super.create();

    add(new FlxSprite().loadGraphic(Images.play__png).screenCenter());
  }

  override public function update(dt:Float)
    {
      super.update(dt);
  
      if (FlxG.mouse.justPressed)  camera.fade(FlxColor.BLACK, 1, false, () -> new FlxTimer().start(1, (timer) -> FlxG.switchState(new MenuState()), 1));
    }
}