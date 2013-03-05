require 'virtus'

class Ball
  include Virtus

  attribute :vertical_velocity, Float
  attribute :horizontal_velocity, Float
  attribute :g, Float, default: 9.8
  attribute :y, Float, default: 0
  attribute :x, Float, default: 0

  def vertical_position(time)
    # time in seconds
    time = time.to_f
    # velocity in m/s
    # gravitational acceleration
    (vertical_velocity * time) - ((0.5 * g) * time**2)
  end

  def horizontal_position(time)
    time = time.to_f * -1
    # shows distance to catcher, multiply by -1 to show distance
    # from starting point
    (2 * horizontal_velocity * vertical_velocity)/g 
      - horizontal_velocity * time
  end

  def d_vert_velocity(dt)
    self.vertical_velocity -= g * dt 
  end
  
  def d_hor_velocity(dt)
    self.horizontal_velocity *= 0.75 
  end
end

class Derivative
  include Virtus

  attribute :dy, Float
  attribute :dx, Float
  attribute :d_velocity_v, Float
  attribute :d_velocity_h, Float
end

def integrate(state_object, t, dt)
  a = Derivative.new
  a.evaluate1(state_object, t)
  b = Derivative.new
  b.evaluate2(state_object, t, dt * 0.5, a)
  c = Derivative.new
  c.evaluate2(state_object, t, dt * 0.5, b)
  d = Derivative.new
  d.evaluate2(state_object, t, dt, c)

  dxdt = 1.0/6 * (a.dx + 2.0 * (b.dx + c.dx) + d.dx)
  dvdt = 1.0/6 * (a.dv + 2.0 * (b.dv + c.dv) + d.dv)

  state_object.x += (dxdt * dt)
  # state_object.v += (dvdt * dt)

  state_object.recalculate_velocity(dvdt * dt)
end

# ball = Ball.new(vertical_velocity: 10, horizontal_velocity: 10)
# ball.y = ball.vertical_position(0.1)
# # ball.x = ball.horizontal_position(1)
# dt = 0.1
# t = 0.1
# while ball.y > 0
#   # ball.y += ball.d_vert_velocity(dt)
#   # ball.d_vert_velocity(dt)
#   ball.y = ball.vertical_position(t)
#   # ball.x
#   puts "Ball height(m): #{ball.y}\nTime: #{t} seconds"
#   t += dt
# end

