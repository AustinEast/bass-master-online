package;

import flixel.math.FlxRandom;
import flixel.FlxGame;
import openfl.display.Sprite;
import openfl.display.FPS;
import states.ClickState;

class Main extends Sprite
{

	public static var random = new FlxRandom();
	
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, ClickState, 1, 60, 60, true));
		addChild(new FPS());
		FlxG.autoPause = false;
	}
}
