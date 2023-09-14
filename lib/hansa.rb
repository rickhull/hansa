module Hansa
  # tunables
  DMU = 0.950 # diminishing marginal utility
  ICU = 1.010 # increasing complementary utility

  # utils when the first good is consumed (before DMU and ICU)
  CONSUMPTION = {
    leisure: 1,

    apple: 4,
    bread: 8,
    corn: 4,
    donut: 10,
    egg: 6,
    fish: 8,
    grape: 4,
    potato: 3,

    restaurant_meal: 18,
    fancy_meal: 30,
    cinema: 20,
    opera: 25,
    theater: 25,
    amusement_park: 40,

    water: 10,
    fuel: 10,
    wood: 10,

    bicycle: 40,
    motorcycle: 100,
    car: 200,
    truck: 240,
    apartment: 600,
    house: 1000,

    watch: 20,
    tv: 60,
    computer: 80,
    phone: 80,

    clothes: 20,
    fashion: 30,
    high_fashion: 50,

    medicine: 40,
    healthcare: 100,

    light_bulb: 10,
    water_filter: 16,
    hand_tools: 20,
    power_tools: 40,
  }

  LABOR = {
    apple: 5,
    bread: 10,
    corn: 5,
    donut: 15,
    egg: 5,
    fish: 10,
    grape: 5,
    potato: 2,

    restaurant_meal: 20,
    fancy_meal: 30,
    cinema: 15,
    opera: 20,
    theater: 20,
    amusement_park: 100,

    water: 5,
    fuel: 5,
    wood: 5,

    bicycle: 20,
    motorcycle: 50,
    car: 200,
    truck: 200,
    apartment: 500,
    house: 10_00,

    watch: 30,
    tv: 30,
    computer: 30,
    phone: 30,

    clothes: 5,
    fashion: 10,
    high_fashion: 25,

    medicine: 10,
    healthcare: 100,

    light_bulb: 5,
    water_filter: 5,
    hand_tools: 10,
    power_tools: 20,
  }

  CITY_TYPES = {
    nil => {},
    farming: {
      apple: 1/3r,
      bread: 2/3r,
      corn: 1/3r,
      donut: 2/3r,
      egg: 1/2r,
      grape: 1/3r,
      potato: 1/3r,
      restaurant_meal: 2/3r,
      fancy_meal: 2/3r,
    },
    high_tech: {
      donut: 2/3r,
      restaurant_meal: 2/3r,
      cinema: 1/2r,
      amusement_park: 1/2r,
      water: 1/3r,
      fuel: 1/2r,
      bicycle: 1/2r,
      motorcycle: 1/2r,
      car: 3/5r,
      truck: 3/5r,
      apartment: 1/2r,
      house: 3/5r,
      watch: 1/15r,
      tv: 1/6r,
      computer: 1/6r,
      phone: 1/6r,
      medicine: 1/6r,
      healthcare: 60/100r,
    },
    industrial: {
      bread: 2/10r,
      donut: 5/15r,
      restaurant_meal: 15/20r,
      water: 2/5r,
      fuel: 2/5r,
      wood: 3/5r,
      bicycle: 5/20r,
      motorcycle: 25/50r,
      car: 100/200r,
      truck: 80/200r,
      apartment: 1/2r,
      house: 300/500r,
      clothes: 1/5r,
      fashion: 2/10r,
      medicine: 2/10r,
      light_bulb: 1/5r,
      water_filter: 1/5r,
      hand_tools: 1/10r,
      power_tools: 3/20r,
    },
    culture: {
      restaurant_meal: 10/20r,
      fancy_meal: 1/2r,
      opera: 10/20r,
      theater: 10/20r,
      fashion: 6/10r,
      high_fashion: 10/25r,
      apartment: 2/3r,
      bicycle: 2/3r,
      motorcycle: 4/5r,
      car: 5/3r,
      truck: 5/3r,
      house: 5/3r,
    },
    coastal: {
      apple: 3/5r,
      fish: 2/10r,
      egg: 3/5r,
      grape: 2/5r,
      restaurant_meal: 12/20r,
      fancy_meal: 3/5r,
      cinema: 15/20r,
      opera: 15/20r,
      theater: 15/20r,
      amusement_park: 50/100r,
      water: 4/5r,
      fuel: 4/5r,
      bicycle: 15/20r,
      motorcycle: 40/50r,
      car: 150/200r,
      truck: 150/200r,
      house: 5/3r,
      fashion: 8/10r,
      high_fashion: 20/25r,
      medicine: 5/10r,
      healthcare: 75/100r,
      light_bulb: 4/5r,
      water_filter: 2/5r,
    },
    undeveloped: {
      bread: 20/10r,
      donut: 30/15r,
      restaurant_meal: 40/20r,
      fancy_meal: 5,
      cinema: 40/20r,
      opera: 40/20r,
      theater: 40/20r,
      amusement_park: 500/100r,
      water: 10/5r,
      fuel: 10/5r,
      bicycle: 50/20r,
      motorcycle: 200/50r,
      car: 500/200r,
      truck: 500/200r,
      apartment: 2,
      house: 2000/500r,
      watch: 100/30r,
      tv: 200/30r,
      computer: 500/30r,
      phone: 500/30r,
      clothes: 8/5r,
      fashion: 50/10r,
      high_fashion: 2000/25r,
      medicine: 20/10r,
      healthcare: 300/100r,
      light_bulb: 20/5r,
      water_filter: 10/5r,
      hand_tools: 15/10r,
      power_tools: 50/20r,
    },
  }

  MODIFIED = {}

  # generate a LABOR-like hash with modifications and disturbances
  def self.terrain(modifier = nil)
    hsh = {}
    self.modified(modifier).each { |good, cost|             # modifications
      hsh[good] = (cost + cost * (rand(0) - 0.5) / 2).round # disturbances
    }
    hsh
  end

  # apply modifier (default nil) values to LABOR; return a new hash
  def self.modified(modifier = nil)
    cached = MODIFIED[modifier]
    return cached unless cached.nil?
    mods = CITY_TYPES.fetch modifier
    hsh = {}
    LABOR.each { |good, labor| hsh[good] = labor * (mods[good] || 1) }
    hsh
  end

  # given [good => units], generate [good => labor] based on _terrain_
  def self.labor_cost(goods_hsh, terrain: LABOR)
    labor = {}
    goods_hsh.each { |good, count|
      labor[good] = count * terrain.fetch(good)
    }
    labor
  end

  # apply diminishing marginal and increasing complementary utility
  def self.mult(num_goods, num_other_goods)
    (DMU ** num_goods) * (ICU ** num_other_goods)
  end

  # given [good => units], generate [good => utility]
  def self.utility(goods_hsh)
    total_goods = goods_hsh.values.sum
    utility = {}
    goods_hsh.each { |good, count|
      other_goods = total_goods - count
      utils = CONSUMPTION.fetch(good)
      # for every util, add them up
      utility[good] = Array.new(count) { |i|
        # the multiplier gets smaller as i goes up
        self.mult(i, other_goods) * utils
      }.sum.round
    }
    utility
  end
end
