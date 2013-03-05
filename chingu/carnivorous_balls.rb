require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(800, 600, false, update_interval = 1) # calls update ever 1ms
    self.input = {[:q, :escape] => :exit}
    20.times { Ball.create(image: Image["circle.png"])}
  end

  def draw
    fill(Color::WHITE)
    self.caption = "#{Ball.all.count}"
    super
  end

  def update
    super

    Ball.all.each_with_index do |ball, index|

      set_color = ->(x) { self.color = Color::RED }
      Ball.all.each {|ball| ball.instance_eval(&set_color)}

      ball.consume_internal_ball
      ball.in_boundaries.each do |invader|
        invader.color = Color::BLACK
      end

      # calculate consume based on distance from surface
      # not based on impact (well, impact also)

      # transfer mass, not diameter
      # calculate new diameter from mass increase

      # if newly expanded size is beyond the borders of the screen
      # push the ball away from it

      ball.scale == 5 if ball.scale > 5
      break if index == Ball.all.count - 1
      ball.each_bounding_circle_collision(Ball.all[index + 1 .. -1]) do |b1, b2|
        [b1, b2].each {|b| b.color = Color::BLUE }
        MomentumTransfer.calculate(b1, b2)
        scales = [b1, b2].sort {|b1, b2| b1.scale <=> b2.scale }
        larger = scales.last
        smaller = scales.first
        transfer_rate = (0.1 * larger.scale)
        larger.scale += transfer_rate
        smaller.scale -= transfer_rate
        smaller.destroy if smaller.scale <= 0
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
  attr_accessor :density
  attr_accessor :color, :momentum

  def initialize(*args)
    super
    @@balls << self
    @init_time = Time.now
    @x, @y = rand(width .. $window.width - width), rand(height .. $window.height - height)
    @dx, @dy = rand(-5 .. 5), rand(-5 .. 5)
    self.scale = rand(1..3)
    @density = 10
    # cache_bounding_circle
  end

  def self.balls
    @@balls
  end

  def diameter
    scale * 3
  end

  def consume_internal_ball
    in_boundaries.each(&:destroy)
  end

  def other_balls
    @@balls.reject {|b| b == self }
  end

  def in_boundaries
    other_balls.select {|b| 
      b.x.between?(x - radius, x + radius) &&
       b.y.between?(y - radius, y + radius)
     }
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
    # calc_momentum
  end
end

Game.new.show