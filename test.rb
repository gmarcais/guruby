require_relative 'lib/guruby'

env = Guruby::Environment.new
model = Guruby::Model.new env

x = Guruby::Variable.new(0, 1, 1, Guruby::GRB_BINARY, 'x')
y = Guruby::Variable.new(0, 1, 1, Guruby::GRB_BINARY, 'y')
z = Guruby::Variable.new(0, 1, 2, Guruby::GRB_BINARY, 'z')
vars = [x, y, z]
vars.each { |var| model << var }
model.set_sense Guruby::GRB_MAXIMIZE
model.update

model.add_constraint x + y * 2 + z * 3, Guruby::GRB_LESS_EQUAL, 4.0, 'c0'
model.add_constraint x + y, Guruby::GRB_GREATER_EQUAL, 1.0, 'c1'
model.update

model.write '/tmp/test.lp'

model.optimize

vars.each do |var|
  puts "#{var.name} = #{var.value}"
end

p model.status
