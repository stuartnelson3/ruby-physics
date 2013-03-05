require 'chingu'
require 'gosu'

# need to find some way to make the balls not occupy same space
# and they need to be able to transfer their momentum in a
# non-linear fashion if there's no room?

class Game < Chingu::Window
  include Gosu
  def initialize
    super(800, 600, false, update_interval = 1) # calls update ever 1ms
    self.input = {[:q, :escape] => :exit}
    w, h = 160, 0
    7.times { 
      ball = Ball.create(image: Image["circle.png"], x: w, y: height - 10 - h)
      ball.density = 10
      w += 20
    }
    w, h = 170, 18
    6.times {
      ball = Ball.create(image: Image["circle.png"], x: w, y: height - 10 - h)
      ball.density = 10
      w += 20
    }
    w, h = 180, 18 * 2
    5.times {
      ball = Ball.create(image: Image["circle.png"], x: w, y: height - 10 - h)
      ball.density = 10
      w += 20
    }
    w, h = 190, 18 * 3
    4.times {
      ball = Ball.create(image: Image["circle.png"], x: w, y: height - 10 - h)
      ball.density = 10
      w += 20
    }
    i, j = 1, 4
    [3, 2, 1].each do |num|
      w, h = 190 + 10*i, 18 * j
      i += 1
      j += 1
      num.times do
        ball = Ball.create(image: Image["circle.png"], x: w, y: height - 10 - h)
        ball.density = 10
        w += 20
      end
    end

    @ball = Ball.create(image: Image["circle.png"])
    @ball.x, @ball.y = 220, height/2
    @ball.dx, @ball.dy = 0, 10
    @ball.density = 30
  end

  def draw
    fill(Color::WHITE)
    self.caption = "#{fps}"
    super
  end

  def update
    super
    change_color = ->(x) {self.color = Color::RED}
    Ball.balls.each {|ball| ball.instance_eval(&change_color)}

    Ball.balls.each_with_index do |ball, index|
      break if index == Ball.balls.count - 1
      ball.color = Color::BLUE
      ball.each_bounding_circle_collision(Ball.balls[index + 1 .. -1]) do |b1, b2|
        MomentumTransfer.calculate(b1, b2)
      end
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

      old_obj1_dy, old_obj2_dy = obj1.dy, obj2.dy
      obj1.dy = (obj1.mass - obj2.mass)/(obj1.mass + obj2.mass)*old_obj1_dy + (2*obj2.mass)/(obj1.mass + obj2.mass)*old_obj2_dy
      obj2.dy = (obj2.mass - obj1.mass)/(obj2.mass + obj1.mass)*old_obj2_dy + (2*obj1.mass)/(obj2.mass + obj1.mass)*old_obj1_dy
    end
  end
end

class Ball < Chingu::GameObject
  @@balls = []
  trait :collision_detection
  trait :bounding_circle, :debug => true
  attr_accessor :dx, :dy, :init_time
  attr_accessor :diameter, :density
  attr_accessor :color, :momentum

  def initialize(*args)
    super
    @@balls << self
    @init_time = Time.now
    # @x, @y = rand(width .. $window.width - width), rand(height .. $window.height - height)
    @dx, @dy = 0, 0 # rand(-10 .. 10), rand(-10 .. 10)
    self.scale = 1 # rand(1..3)
    @diameter = 3 * scale
    # @density = 10
    cache_bounding_circle
  end

  def self.balls
    @@balls
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

  # def occupied?
  #   coords = @@balls.map {|ball| ball.x, ball.y }
  #   r = height / 2
  #   x + r, x - r
  #   y + r, y - r
  #   coords.include? [x, y]
  # end

  def vert_decay
     self.dy = VelocityDecay.vertical(dy, elapsed_time)
  end

  def hori_decay
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
    # vert_decay
    hori_decay
    self.y = $window.height - height/2 if grounded?
    # calc_momentum
  end
end

Game.new.show