require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(640, 480, false)

    self.input = {[:q, :escape] => :exit}

    @ball = Ball.create(image: Image["circle.png"])
    @ball.diameter = 3 # cm
    @ball.density = 10 # g/cm^3; equivalent to 2 g/cm^3
    # @ball.x, @ball.y = width / 2, height / 2 # center of screen
    @ball.x, @ball.y = @ball.width/2, height - @ball.height/2 # lower left corner
    # @ball.x, @ball.y = @ball.width/2, height / 2 # halfway up left side of screen
    @ball.dx, @ball.dy = 5, 0

    @ball2 = Ball.create(image: Image["circle.png"])
    @ball2.diameter = 3 # cm
    @ball2.density = 15 # g/cm^3; equivalent to 2 g/cm^3
    # @ball.x, @ball.y = width / 2, height / 2 # center of screen
    # @ball2.x, @ball2.y = @ball.width/2, height - @ball.height/2 # lower left corner
    # @ball2.x, @ball2.y = @ball2.width/2, height / 2 # halfway up left side of screen
    @ball2.x, @ball2.y = width / 2, height - @ball.height/2
    @ball2.dx, @ball2.dy = 0, 0
  end

  def draw
    fill(Color::WHITE)
    self.caption = "Ball momentum: #{@ball.momentum}; Ball2 momentum: #{@ball2.momentum}"
    super
  end

  def update
    super
    @ball.color = Color::RED
    @ball2.color = Color::RED

    @ball.each_bounding_circle_collision(@ball2) do |b1, b2|
      MomentumTransfer.calculate(b1, b2)
    end

    # doesn't work, fires for both balls and undoes the momentum transfer
    # Ball.each_bounding_circle_collision(Ball) do |b1, b2|
    #   old_b1, old_b2 = b1.dx, b2.dx
    #   b1.dx = (b1.mass - b2.mass)/(b1.mass + b2.mass)*old_b1 + (2*b2.mass)/(b1.mass + b2.mass)*old_b2
    #   b2.dx = (b2.mass - b1.mass)/(b2.mass + b1.mass)*old_b2 + (2*b1.mass)/(b2.mass + b1.mass)*old_b1
    # end

    Ball.each_bounding_circle_collision(Ball) do |obj1, obj2|
      # MomentumTransfer.calculate(obj1, obj2)
      # obj1.dx *= 1.2
      obj1.color = Color::BLUE
      # if obj2.dx.abs > 0
      #   obj1.dx = obj2.dx
      #   obj2.dx = 0
      # end
    end
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

class MomentumTransfer
  class << self
    def calculate(obj1, obj2)
      old_obj1_dx, old_obj2_dx = obj1.dx, obj2.dx
      obj1.dx = (obj1.mass - obj2.mass)/(obj1.mass + obj2.mass)*old_obj1_dx + (2*obj2.mass)/(obj1.mass + obj2.mass)*old_obj2_dx
      obj2.dx = (obj2.mass - obj1.mass)/(obj2.mass + obj1.mass)*old_obj2_dx + (2*obj1.mass)/(obj2.mass + obj1.mass)*old_obj1_dx
    end
  end
end

class Ball < Chingu::GameObject
  trait :collision_detection
  trait :bounding_circle, :debug => true
  attr_accessor :dx, :dy, :init_time
  attr_accessor :diameter, :density
  attr_accessor :color, :momentum

  def initialize(*args)
    super
    @init_time = Time.now
    cache_bounding_circle
  end

  def recalc_dx
    self.dx = momentum / mass
  end

  def calc_momentum
    @momentum = Momentum.calculate(mass, dx)
  end

  def mass
    Mass.calculate(diameter, density)
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
    self.dx = VelocityDecay.horizontal(dx)
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
    calc_momentum
    if grounded?
    #   self.dy *= -1
      self.y = $window.height - height/2
    end
  end
end

Game.new.show