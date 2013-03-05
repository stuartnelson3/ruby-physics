require 'virtus'
# f = m*a
# df = a * dm
# dv/dt = a = f/m
class State
  include Virtus
  attribute :x, Float
  attribute :v, Float
  attribute :mass, Float

  def inverse_mass
    1 / mass
  end

  def recalculate_velocity(momentum)
    self.v = momentum # * inverse_mass
  end
end

class Derivative
  include Virtus
  attribute :dx, Float
  attribute :dv, Float

  def evaluate1(state_object, t)
    self.dx = state_object.v
    self.dv = acceleration(state_object, t)
  end

  def evaluate2(state_object, t, dt, derivative_object)
    state_object.x += (derivative_object.dx * dt)
    state_object.v += (derivative_object.dv * dt)

    self.dx = state_object.v
    self.dv = force(state_object, derivative_object, dt) * dt / state_object.mass
  end
end

# state_object is a State object instance
def acceleration(state_object, t)
  k = 10
  b = 1
  (- k * state_object.x) - (b * state_object.v)
end

# Switch from integrating (velocity directly from acceleration) 
# to integrating (momentum from force) instead (the derivative of momentum is force). 
# You will need to add “mass” and “inverseMass” to the State struct 
# and I recommend adding a method called “recalculate” which updates 
# velocity = momentum * inverseMass whenever it is called. 
# Every time you modify the momentum value you need to recalculate the velocity. 
# You should also rename the acceleration method to “force”.

# f = m * (dv/dt)
def force(state_object, derivative_object, dt)
  state_object.mass * (derivative_object.dv / dt)
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

def main
  state = State.new(x: 100, v: 0, mass: 1000)
  t = 0.0
  dt = 0.1

  while state.x > 0.001 || state.v > 0.001
    puts "Position: #{state.x}; Velocity: #{state.v}"
    integrate(state, t, dt)
    t += dt
  end
end

main