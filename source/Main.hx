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
		#if debug
		addChild(new FlxGame(0, 0, ClickState, 1, 60, 60, true));
		// addChild(new FPS());
		#else
		addChild(new FlxGame(0, 0, ClickState, 1, 60, 60, false));
		#end
		
		FlxG.autoPause = false;
	}
}
