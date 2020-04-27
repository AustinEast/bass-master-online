package objects;

class BaseSprite extends DepthSprite {
  

  public var state(default, set):Int = 0;

  function set_state(state:Int) {
    return this.state = state;
  }
}