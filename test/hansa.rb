require 'minitest/autorun'
require 'hansa'

include Hansa

describe Hansa do
  describe "CONSUMPTION" do
    it "maps goods to utils" do
      expect(CONSUMPTION[:apple]).must_be_kind_of Numeric
    end

    it "has the same keys (goods) as LABOR" do
      LABOR.each_key { |k| expect(CONSUMPTION.key?(k)).must_equal(true) }
    end
  end

  describe "LABOR" do
    it "maps goods to labor cost" do
      expect(LABOR[:apple]).must_be_kind_of Numeric
    end

    it "has the same keys (goods) as CONSUMPTION" do
      CONSUMPTION.each_key { |k| expect(LABOR.key?(k)).must_equal(true) }
    end
  end
end
