require 'matrix'

module Hansa
  class Position
    class OutOfBounds < RuntimeError; end

    # returns an array of strings
    def self.quadrant(vec)
      ary = []
      if vec[1] > 0.5
        ary[0] = :north
        ary[2] = 'N'
      else
        ary[0] = :south
        ary[2] = 'S'
      end
      if vec[0] > 0.5
        ary[1] = :east
        ary[2] << 'E'
      else
        ary[1] = :west
        ary[2] << 'W'
      end
      ary
    end

    # returns a scalar
    def self.distance(pos1, pos2)
      (pos1.vec - pos2.vec).magnitude
    end

    # returns a position
    def self.midpoint(pos1, pos2)
      self.new((pos1.x + pos2.x) / 2.0,
               (pos1.y + pos2.y) / 2.0,
               (pos1.z + pos2.z) / 2.0)
    end

    # returns a position
    def self.random
      self.new(rand(0), rand(0), rand(0))
    end

    def self.valid?(x, y, z)
      0 <= x and x <= 1 and 0 <= y and y <= 1 and 0 <= z and z <= 1
    end

    attr_reader :vec, :r3, :r2, :ns, :we, :quadrant

    def initialize(x, y, z)
      unless self.class.valid?(x, y, z)
        raise(OutOfBounds, format("%.2f %.2f %.2f", x, y, z))
      end
      @vec = Vector[x, y, z]
      @r3 = self.radial(3)
      @r2 = self.radial(2)
      @ns, @we, @quadrant = *Position.quadrant(@vec)
    end

    def x
      @vec[0]
    end

    def y
      @vec[1]
    end

    def z
      @vec[2]
    end

    def radial(dim = 3)
      c = Vector[0.5, 0.5, 0.5]
      case dim
      when 2
        c - Vector[@vec[0], @vec[1], 0.5]
      when 3
        c - @vec
      else
        raise "unexpected dim: #{dim.inspect}"
      end
    end

    def distance(pos2)
      self.class.distance(self, pos2)
    end

    def midpoint(pos2)
      self.class.midpoint(self, pos2)
    end

    def central
      if @r2.r < 0.2
        :inner
      elsif @r2.r < 0.4
        :core
      else
        :outer
      end
    end
  end
end
