package;

import flixel.math.FlxRandom;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPS;
import states.BaseState;

class Main extends Sprite
{

	public static var random = new FlxRandom();
	
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, BaseState, 1, 60, 60, true));
		addChild(new FPS());
		FlxG.autoPause = false;
	}
}
