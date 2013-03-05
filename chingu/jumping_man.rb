# jumping man demo
require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(640, 480, false)

    @jm = JumpingMan.create(image: Image["jumping_man.png"])
    @jm.x = width / 2
    @jm.y = height - (@jm.height/2)
    @jm.dy, @jm.dx, @jm.start_time = 0, 0, Time.now
    @jm.input = { :space => :jump,
                  :holding_left => :move_left,
                  :holding_right => :move_right }

    self.input = {[:q, :escape] => :exit}
  end

  def draw
    fill(Color::WHITE)
    draw_circle(width/2 , height/2, 100, Color::RED)
    # fill_circle(width/2 , height/2, 100, Color::RED)
    # fill_arc(width/2 , height/2, 100, Color::RED)
    self.caption = "JM dy: #{@jm.dy}; JM y: #{@jm.y}"
    super
  end
end

class VelocityDecay
  class << self
    def g
      -9.8
    end

    def vertical(dy, dt)
      dy + g * dt
    end

    def horizontal(dx, modifier = 1)
      dx * (0.90 * modifier)
    end
  end
end

class JumpingMan < Chingu::GameObject
  attr_accessor :dy, :dx, :start_time

  def jump
    self.dy = 20
    @start_time = Time.now
  end

  def grounded?
    @y >= $window.height - height/2
  end

  def airbourne?
    !grounded?
  end

  def dt
    Time.now - @start_time
  end

  def move_left
    self.dx -= 4
  end

  def move_right
    self.dx += 4
  end

  def vert_decay
     self.dy = VelocityDecay.vertical(dy, dt)
  end

  def hori_decay
    modifier = airbourne? ? 1 : 0.7
    self.dx = VelocityDecay.horizontal(dx, modifier)
  end

  def update
    super

    vert_decay
    @y -= dy
    hori_decay
    @x += dx

    if grounded?
      self.dy *= -1 # bounce on impact
      # self.dy = 0
      @y = ($window.height - height/2)
    end

    if !@x.between?(0, $window.width)
      self.dx *= -1 # bounce on impact
    end
  end
end

Game.new.show