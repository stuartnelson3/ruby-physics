# hello world example
require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(640, 480, false)
    
    HelloWorld.create(x: 0, y: height / 2, image: Image["hello_world.png"])
    self.input = {[:q, :escape] => :exit}
  end

  def update
    super
    self.caption = "Hello World, at #{fps} frames per second"
  end

  def draw
    fill(Color::WHITE)
    super
  end
end

class HelloWorld < Chingu::GameObject
  def update
    @x += 1.5
  end
end

Game.new.show