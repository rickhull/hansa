require 'minitest/autorun'
require 'hansa/position'

include Hansa

describe Position do
  it "wraps a Vector representing a position in 3d space" do
    v = Vector[0.1, 0.2, 0.3]
    p = Position.new(v[0], v[1], v[2])
    expect(p).must_be_kind_of Position
    expect(p.vec).must_be_kind_of Vector
    expect(p.vec).must_equal v
  end

  it "has components (x,y,z) with values 0.0 - 1.0" do
    x = 0
    y = 1
    z = 0.5
    p = Position.new(x, y, z)
    expect(p.x).must_equal x
    expect(p.y).must_equal y
    expect(p.z).must_equal z

    expect { Position.new(-1, 0, 0) }.must_raise Position::OutOfBounds
    expect { Position.new(1, 2, 3) }.must_raise Position::OutOfBounds
  end

  it "has a radius (vector from (0.5, 0.5, 0.5))" do
    east = Position.new(1, 0.5, 0.5)
    north = Position.new(0.5, 1, 0.5)
    high = Position.new(0.5, 0.5, 1)
    [east, north, high].each { |pos|
      expect(pos.radial.magnitude).must_be_within_epsilon 0.5
      expect(pos.radial.magnitude).must_be_within_epsilon 0.5
      expect(pos.r3.r).must_be_within_epsilon 0.5
    }
  end

  it "has a 2d radius" do
    east = Position.new(1, 0.5, 0.5)
    north = Position.new(0.5, 1, 0.5)
    high = Position.new(0.5, 0.5, 1)
    [east, north].each { |pos|
      expect(pos.radial(2).magnitude).must_be_within_epsilon 0.5
      expect(pos.r2.r).must_be_within_epsilon 0.5
    }
    expect(high.r2.r).must_be_within_epsilon 0
  end

  it "determines distance to another position" do
    a = Position.new(0, 0, 0)
    b = Position.new(0, 0.2, 0)
    expect(a.distance(b)).must_be_within_epsilon 0.2
  end

  it "determines a midpoint to another position" do
    a = Position.new(0, 0, 0)
    b = Position.new(0, 0.2, 0)
    m = a.midpoint(b)
    expect(m.distance(a)).must_be_within_epsilon 0.1
    expect(m.distance(b)).must_be_within_epsilon 0.1
  end

  it "has an XY quadrant with NS-WE semantics" do
    sw = Position.new(0.2, 0.3, 0)
    nw = Position.new(0.3, 0.8, 0.2)
    se = Position.new(0.7, 0.2, 0.5)
    ne = Position.new(0.8, 0.7, 0.9)

    expect(sw.ns).must_equal :south
    expect(ne.ns).must_equal :north
    expect(se.we).must_equal :east
    expect(nw.we).must_equal :west

    expect(sw.quadrant).must_equal 'SW'
    expect(nw.quadrant).must_equal 'NW'
    expect(ne.quadrant).must_equal 'NE'
    expect(se.quadrant).must_equal 'SE'
  end

  it "has 3 classifications (inner, core, outer) for its XY radius" do
    expect(Position.new(0.5, 0.5, 0).centrality).must_equal :inner
    expect(Position.new(0.3, 0.3, 0.5).centrality).must_equal :core
    expect(Position.new(0, 0, 1).centrality).must_equal :outer
  end

  it "generates random (valid) positions" do
    last = Position.random
    expect(last).must_be_kind_of Position
    5.times {
      p = Position.random
      expect(p).must_be_kind_of Position
      expect(p.vec).wont_equal last.vec
      last = p
    }
  end
end
