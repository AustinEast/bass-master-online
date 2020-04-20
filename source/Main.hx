package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.BaseState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, BaseState, 1, 60, 60, true));
		FlxG.autoPause = false;
	}
}
