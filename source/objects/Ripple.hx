package objects;

import flixel.FlxObject;
import util.ParticleEmitter;

class Ripple extends Particle 
{
  public function new()
  {
    super();
    loadGraphic(Images.ripple__png, true, 32, 32);
		animation.add("play", [0, 1, 2, 3, 4, 5], 15, false);
		this.make_and_center_hitbox(2, 2);
		centerOrigin();
		// billboard = true;
		allowCollisions = FlxObject.NONE;
  }

  override public function update(elapsed:Float):Void {
		if (animation.finished) {
			kill();
		}
		super.update(elapsed);
  }

  override function fire(options:FireOptions) 
  {
    animation.play('play');
    super.fire(options);
		z = options.util_amount != null ? options.util_amount : 0;
		velocity_z = 0;
  }
}