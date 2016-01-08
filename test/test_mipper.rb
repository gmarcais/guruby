require 'minitest/autorun'
require 'mipper'

module MIPPeR
  module MIPPeRModelTest
    def test_mip
      x = Variable.new(0, 1, 1, :binary, 'x')
      y = Variable.new(0, 1, 1, :binary, 'y')
      z = Variable.new(0, 1, 2, :binary, 'z')
      vars = [x, y, z]
      vars.each { |var| @model << var }
      @model.sense = :max
      @model.update

      @model << Constraint.new(x + y * 2 + z * 3, :<=, 4.0, 'c0')
      @model << Constraint.new(x + y, :>=, 1.0, 'c1')

      @model.update
      @model.optimize

      assert_equal x.value, true
      assert_equal y.value, false
      assert_equal z.value, true

      assert_in_delta @model.objective_value, 3, 0.001
    end

    def test_inspect_var
      var = Variable.new 0, 1, 1, :binary, 'x'
      @model << var
      @model.update
      @model.optimize

      assert_equal var.inspect, 'x = false'
    end

    def test_store_variables
      x = Variable.new 0, 1, 0, :binary, 'x'
      @model << x
      @model.update

      assert_equal @model.variables, [x]
    end

    def test_inspect_expr_skip_zeros
      var = Variable.new 0, 1, 1, :continuous, 'x'
      @model << var
      @model.update

      constr = Constraint.new var * 1, :>=, 0
      @model << constr

      @model.update
      @model.sense = :min
      @model.optimize

      assert_equal constr.expression.inspect, ''
    end
  end

  class GurobiTest < MiniTest::Test
    include MIPPeRModelTest

    def setup
      @model = GurobiModel.new
    end

    # XXX This should be moved to MIPPeRModelTest once GLPK support is added
    def test_set_variable_bounds
      var = Variable.new 0, 1, 1, :continuous, 'x'
      @model << var
      @model.update
      var.upper_bound = 5

      @model.update
      @model.sense = :max
      @model.optimize

      assert_in_delta var.value, 5, 0.001
    end

    def test_compute_iis
      var = Variable.new 0, 1, 1, :continuous, 'x'
      @model << var
      @model.update

      # These two constraints cannot be satisfied
      @model << Constraint.new(var * 1, :==, 0)
      @model << Constraint.new(var * 1, :==, 1)
      @model.update

      @model.optimize
      @model.compute_IIS
    end
  end

  class GLPKTest < MiniTest::Test
    include MIPPeRModelTest

    def setup
      @model = GLPKModel.new
    end
  end

  class VarTest
    def test_inspect_unknown_var
      var = Variable.new 0, 1, 0, :binary, 'x'

      assert_equal var.inspect, 'x = ?'
    end

    def test_nil_value_unsolved
      x = Variable.new 0, 1, 0, :binary, 'x'
      @model << x

      assert_nil x.value
    end
  end

  class ExprTest
    def test_inspect_expr_simple
      x = Variable.new 0, 1, 0, :binary, 'x'
      y = Variable.new 0, 1, 0, :binary, 'y'

      assert_equal (x + y).inspect, 'x + y'
    end

    def test_inspect_expr_coeffs
      x = Variable.new 0, 1, 0, :binary, 'x'
      y = Variable.new 0, 1, 0, :binary, 'y'

      assert_equal (x * 2 + y).inspect, 'x * 2 + y'
    end

    def test_expr_add_expr
      x = Variable.new(0, 1, 1, :binary, 'x')
      y = Variable.new(0, 1, 1, :binary, 'y')
      expr = LinExpr.new({x => 1.0})
      expr.add LinExpr.new({y => 1.0})

      assert_equal expr.terms, { x => 1.0, y => 1.0}
    end

    def test_expr_add_var
      x = Variable.new(0, 1, 1, :binary, 'x')
      y = Variable.new(0, 1, 1, :binary, 'y')
      expr = LinExpr.new({x => 1.0})
      expr.add y

      assert_equal expr.terms, { x => 1.0, y => 1.0}
    end
  end
end
