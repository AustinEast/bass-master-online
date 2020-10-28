package objects;

import flixel.FlxObject;
import util.ParticleEmitter;

class Poof extends Particle 
{
  // public var shadow:Shadow;
  public function new()
  {
    super();
    loadGraphic(Images.poofs__png, true, 16, 16);
		animation.add("0", [7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("1", [6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("2", [5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("3", [4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("4", [3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("5", [2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("6", [1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("7", [0, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 15, false);
		animation.add("8", [7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("9", [6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("10", [5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("11", [4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("12", [3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("13", [2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("14", [1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("15", [0, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		this.make_and_center_hitbox(2, 2);
		centerOrigin();
		billboard = true;
		allowCollisions = FlxObject.NONE;

		// shadow = PlayState.i.shadows.activate(this, AssetPaths.poofs__png, 16, 16);
		// shadow.color = 0xff312e2f;
		// shadow.matchTargetFrame = true;
		// shadow.unique = true;
		// shadow.kill();
  }

  override public function update(elapsed:Float):Void {
		if (animation.finished) {
			// shadow.kill();
			kill();
		}
		super.update(elapsed);
		velocity_z -= Main.random.float(0, 2);

		// Set size for correct shadow size
		switch (animation.frameIndex) {
			case 0:
				setSize(16, 16);
			case 1:
				setSize(14, 14);
			case 2:
				setSize(12, 12);
			case 3:
				setSize(10, 10);
			case 4:
				setSize(8, 8);
			case 5:
				setSize(6, 6);
			case 6:
				setSize(5, 5);
			case 7:
				setSize(4, 4);
			case 8:
				setSize(2, 2);
		}
  }

  override function fire(options:FireOptions) 
  {
    super.fire(options);
    // shadow.reset(x, y);
		// shadow.animation.frameIndex = animation.frameIndex;
		z = options.util_amount != null ? options.util_amount : 0;
		velocity_z = 0;
  }
}