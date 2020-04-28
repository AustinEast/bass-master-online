package states;

import zero.flixel.states.sub.FadeOut;
import zero.flixel.states.sub.FadeIn;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.ui.FlxButton;
import states.FishingState;

using flixel.util.FlxSpriteUtil;

class MenuState extends State
{

	var ubble:FlxBitmapFont;
	var byond:FlxBitmapFont;
	var mouse:FlxSprite;

	override public function create()
	{
		super.create();

		camera.bgColor = 0xff361027;

		FlxG.sound.play(Sounds.power_on__wav);
		new FlxTimer().start(0.5, (timer) -> {
			FlxG.sound.play(Sounds.startup__wav, 0.5);
			FlxG.sound.playMusic(Music.hum__wav);
		});

		openSubState(new FadeIn());

		// add_controller();

		ubble = FlxBitmapFont.fromAngelCode(Fonts.ubble__png, Fonts.ubble__fnt);
		byond = FlxBitmapFont.fromAngelCode(Fonts.byond__png, Fonts.byond__fnt);

		var title = new FlxBitmapText(ubble);
		title.text = 'Bass Master';
		title.x = FlxG.width.half() - title.width.half();
		title.y = 240;

		var start = new FlxBitmapText(byond);
		start.text = 'click to join';
		start.x = FlxG.width.half() - start.width.half();
		start.y = 380;
		start.scale.set(0.5,0.5);
		start.flicker(0, 0.8);
		
		FlxG.mouse.visible = false;
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
			FlxG.sound.play(Sounds.click_down__wav);
		}

		// The left mouse button has just been released
		if (FlxG.mouse.justReleased) {
			FlxG.sound.play(Sounds.click_up__wav);
			openSubState(new FadeOut(() -> {
				FlxG.sound.music.stop();
				FlxG.switchState(new FishingState());
			}, 1.3));
		}
	}
}
