require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(640, 480, false)

    self.input = {[:q, :escape] => :exit}
    @ball = Ball.create(image: Image["circle.png"])
    @ball.x, @ball.y = width / 2, height / 2 # center of screen
    # @ball.x, @ball.y = @ball.width/2, height - @ball.height/2 # lower left corner
    # @ball.x, @ball.y = @ball.width/2, height / 2 # halfway up left side of screen
    @ball.dx, @ball.dy = 0, 0

    @ball2 = Ball.create(image: Image["circle.png"])
    # @ball.x, @ball.y = width / 2, height / 2 # center of screen
    @ball2.x, @ball2.y = @ball.width/2, height - @ball.height/2 # lower left corner
    # @ball2.x, @ball2.y = @ball2.width/2, height / 2 # halfway up left side of screen
    @ball2.dx, @ball2.dy = 7, -5
  end

  def draw
    fill(Color::WHITE)
    self.caption = "FPS: #{fps}; Elapsed time: #{@ball.elapsed_time}"
    super
  end
end

class VelocityDecay
  class << self
    def g
      9.8
    end

    def size_conversion
      # scale pixels to centimeters
      # if one pixel == one centimeter,
      # need to convert gravity calculation
      # current value is in meters/sec^2
      0.08
    end

    def vertical(dy, dt)
      dy + g * dt * size_conversion
    end

    def horizontal(dx, modifier = 1)
      dx * (1.0 * modifier)
    end
  end
end

class Momentum
  class << self
    def calculate(mass, velocity)
      mass * velocity
    end
  end
end

class Mass
  class << self
    def calculate(diameter, density)
      4/3 * Math::PI * (diameter/2)**3 * density
    end
  end
end

class Position
  def self.vertical_position(time)
    # time in seconds
    time = time.to_f
    # velocity in m/s
    # gravitational acceleration
    (vertical_velocity * time) - ((0.5 * -9.8) * time**2)
  end
end

class ElapsedTime
  def initialize
    Time.now
  end
end

class Ball < Chingu::GameObject
  attr_accessor :dx, :dy, :init_time

  def initialize(*args)
    super
    @init_time = Time.now
  end

  def elapsed_time
    Time.now - @init_time
  end

  def grounded?
    @y >= $window.height - height/2
  end

  def airbourne?
    !grounded?
  end

  def vert_decay
     self.dy = VelocityDecay.vertical(dy, elapsed_time)
  end

  def hori_decay
    modifier = airbourne? ? 1 : 0.95
    self.dx = VelocityDecay.horizontal(dx, modifier)
  end

  def at_hori_boundary?
    @x < width/2 || @x > $window.width - width/2
  end

  def at_vert_boundary?
    @y < height/2 || @y > $window.height - height/2   
  end

  def update
    super
    self.y += dy
    self.x += dx
    self.dy *= -1 if at_vert_boundary?
    self.dx *= -1 if at_hori_boundary?
    vert_decay
    hori_decay
    if grounded?
    #   self.dy *= -1
      self.y = $window.height - height/2
    end
    # self.y = Position.vertical_position(elapsed_time)
  end
end

Game.new.show