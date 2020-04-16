package;

import flixel.FlxGame;
import openfl.display.Sprite;
import client.states.BaseState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, BaseState));
		FlxG.autoPause = false;
	}
}
