require 'virtus'
require 'matrix'
# f = m*a
# df = a * dm
# dv/dt = a = f/m

class State
  include Virtus

  attribute :position, Vector
  attribute :velocity, Vector

  attribute :mass, Float

  def inverse_mass
    1 / mass
  end

  def recalculate_velocity(speed)
    self.velocity = speed
  end
end

class Derivative
  include Virtus

  attribute :dposition, Vector
  attribute :dvelocity, Vector

  def evaluate1(state_object, t)
    self.dposition = state_object.velocity
    self.dvelocity = acceleration(state_object, t)
  end

  def evaluate2(state_object, t, dt, derivative_object)
    state_object.position += (derivative_object.dposition * dt)
    state_object.velocity += (derivative_object.dvelocity * dt)

    self.dposition = state_object.velocity
    self.dvelocity = force(state_object, derivative_object, dt) * dt / state_object.mass
  end
end

# state_object is a State object instance
def acceleration(state_object, t)
  k = 10
  b = 1
  (- k * state_object.position) - (b * state_object.velocity)
end

def force(state_object, derivative_object, dt)
  state_object.mass * (derivative_object.dvelocity / dt)
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

  dxdt = 1.0/6 * (a.dposition + 2.0 * (b.dposition + c.dposition) + d.dposition)
  dvdt = 1.0/6 * (a.dvelocity + 2.0 * (b.dvelocity + c.dvelocity) + d.dvelocity)

  state_object.position += (dxdt * dt)
  # state_object.velocity += (dvdt * dt)

  state_object.recalculate_velocity(dvdt * dt)
end

def main
  state = State.new(position: Vector[10, 10, 10],
                    velocity: Vector[10, 10, 10],
                    mass: 1)
  t = 0.0
  dt = 0.1

  while state.position.r > 0.001 || state.velocity.r > 0.001
    puts "Position: #{state.position.r}; Velocity: #{state.velocity.r}"
    integrate(state, t, dt)
    t += dt
  end
end

main