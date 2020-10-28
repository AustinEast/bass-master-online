package objects;

class Fish extends BaseSprite {

  public function new(x, y) {
    super(x, y);

    loadGraphic(Images.fish__png, true, 17, 12);
    
    animation.add("wiggle", [0,1,2,3,4,5,6,7], 3);
    animation.play("wiggle");
    centerOrigin();
    
    z = - 3;
  }
}