package states;

import zero.flixel.states.sub.FadeOut;
import zero.flixel.states.sub.FadeIn;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.ui.FlxButton;
import states.FishingState;

using flixel.util.FlxSpriteUtil;

class BaseState extends State
{

	var ubble:FlxBitmapFont;
	var byond:FlxBitmapFont;
	var mouse:FlxSprite;

	override public function create()
	{
		super.create();

		FlxG.sound.play(Sounds.startup__wav, 0.5);

		openSubState(new FadeIn());

		// add_controller();

		ubble = FlxBitmapFont.fromAngelCode(Fonts.ubble__png, Fonts.ubble__fnt);
		byond = FlxBitmapFont.fromAngelCode(Fonts.byond__png, Fonts.byond__fnt);

		var title = new FlxBitmapText(ubble);
		title.text = 'Bass Master';
		title.x = FlxG.width.half() - title.width.half();
		title.y = 240;

		var start = new FlxBitmapText(byond);
		start.text = 'click to connect';
		start.x = FlxG.width.half() - start.width.half();
		start.y = 380;
		start.scale.set(0.5,0.5);
		start.flicker(0, 0.8);
		
		mouse = new FlxSprite().loadGraphic(Images.mouse__png);
		mouse.scale.set(3, 3);

		var comp = new FlxSprite().loadGraphic(Images.comp__png);

		add(title);
		add(start);
		add(mouse);
		add(comp);
	}

	function add_controller()
	{
		if (Reg.c == null) Reg.c = new PlayerController();
		Reg.c.add();
	}

	override public function update(dt:Float)
	{
		super.update(dt);

		mouse.setPosition(FlxG.mouse.x, FlxG.mouse.y);

		if (FlxG.mouse.justPressed) {
			FlxG.sound.play(Sounds.click__mp3);
			openSubState(new FadeOut(() -> FlxG.switchState(new FishingState()), 1.3));
		}
	}
}
