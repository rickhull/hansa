module Hansa
  def self.city_name(locale:, scope: :global, sym: nil, exclude: [])
    case scope
    when :global
      mod, backup = Global, USA
    when :usa
      mod, backup = USA, Global
    else
      raise "unknown scope: #{scope.inspect}"
    end

    case locale
    when :inland
      mod.inland_name(sym, exclude: exclude) rescue
      backup.inland_name(sym, exclude: exclude)
    when :coastal
      mod.coastal_name(sym, exclude: exclude) rescue
      backup.coastal_name(sym, exclude: exclude)
    when :delta
      mod.delta_name(sym, exclude: exclude) rescue
      backup.delta_name(sym, exclude: exclude)
    when :island
      mod.island_name(sym, exclude: exclude) rescue
      backup.island_name(sym, exclude: exclude)
    when :mountain
      mod.mountain_name(sym, exclude: exclude) rescue
      backup.mountain_name(sym, exclude: exclude)
    else
      raise "unknown locale: #{locale.inspect}"
    end
  end

  module Global
    SYMS = (:a..:z).to_a

    def Global.meta_name(sym = nil, first, second, third, exclude: [])
      sym ||= SYMS.sample
      candidates = first.fetch(sym) - exclude
      if candidates.empty?
        candidates = second.fetch(sym) + third.fetch(sym) - exclude
        if candidates.empty?
          raise("No candidates for :#{sym} (exclude: #{exclude.inspect}")
        end
      end
      candidates.sample
    end

    # fall back to MOUNTAIN_NAMES
    def Global.inland_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                     INLAND_NAMES, MOUNTAIN_NAMES, INLAND_NAMES,
                     exclude: exclude)
    end

    # fall back to ISLAND_NAMES
    def Global.coastal_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                     COASTAL_NAMES, ISLAND_NAMES, COASTAL_NAMES,
                     exclude: exclude)
    end

    # fall back to NAMES and COASTAL_NAMES; exclude mountain and island
    def Global.delta_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                     DELTA_NAMES, NAMES, COASTAL_NAMES,
                     exclude: exclude)
    end

    # fall back to name()
    def Global.mountain_name(sym = nil, exclude: [])
      candidates = MOUNTAIN_NAMES.fetch(sym || SYMS.sample) - exclude
      return candidates.sample unless candidates.empty?
      if sym.nil? # try other random syms
        2.times {
          candidates = MOUNTAIN_NAMES.fetch(SYMS.sample) - exclude
          return candidates.sample unless candidates.empty?
        }
      end
      # if we've gotten this far, it's because sym != nil and !exclude.empty?
      # don't worry about circular reference back to MOUNTAIN_NAMES
      # calling name() ensures an exception if everything is excluded
      Global.name(sym, exclude: exclude)
    end

    # fall back to coastal_name()
    def Global.island_name(sym = nil, exclude: [])
      candidates = ISLAND_NAMES.fetch(sym || SYMS.sample) - exclude
      return candidates.sample unless candidates.empty?
      if sym.nil?
        2.times {
          candidates = ISLAND_NAMES.fetch(SYMS.sample) - exclude
          return candidates.sample unless candidates.empty?
        }
      end
      # see above comment from Global.mountain_names
      Global.coastal_name(sym, exclude: exclude)
    end

    INLAND_NAMES = {
      a: ['Antwerp', 'Ankara', 'Aleppo'],
      b: ['Brussels', 'Beijing', 'Bogota'],
      c: ['Cairo', 'Cordoba'],
      d: ['Delhi', 'Damascus', 'Dusseldorf'],
      e: ['Edmonton', 'Essen', 'Eindhoven'],
      f: ['Frankfurt', 'Florence'],
      g: ['Glasgow', 'Giza'],
      h: ['Hamburg', 'Hyderabad'],
      i: ['Isfahan'],
      j: ['Johannesburg', 'Jerusalem'],
      k: ['Krakow', 'Kinshasa', 'Kyiv'],
      l: ['London', 'La Paz'],
      m: ['Montreal', 'Manchester', 'Moscow', 'Madrid'],
      n: ['Nairobi', 'Novosibirsk', 'Nottingham'],
      o: ['Odessa', 'Ottawa'],
      p: ['Paris', 'Pretoria', 'Pyongyang'],
      q: ['Quito', 'Quebec City'],
      r: ['Rome'],
      s: ['Sao Paolo', 'Seville', 'Seoul'],
      t: ['Taipei', 'Tehran'],
      u: ['Utrecht', 'Urumqi', 'Uppsala'],
      v: ['Vienna'],
      w: ['Wuhan', 'Warsaw'],
      x: ["Xi'ian", 'Xolchimilco'],
      y: ['Yakutsk'],
      z: ['Zhengzhou', 'Zaporizhia', 'Zagreb'],
    }

    DELTA_NAMES = {
      a: ['Amsterdam', 'Antwerp'],
      b: ['Belfast', 'Bergen'],
      c: [],
      d: ['Dublin'],
      e: [],
      f: [],
      g: ['Glasgow'],
      h: [],
      i: ['Inverness', 'Istanbul', 'Incheon'],
      j: ['Jeju City'],
      k: ['Karachi'],
      l: ['Lagos', 'London', 'Liverpool', 'Londonderry'],
      m: ['Montreal', 'Melbourne'],
      n: ['Nicosia', 'Nice'],
      o: ['Osaka', 'Oslo'],
      p: ['Panama City', 'Pyongyang', 'Perth'],
      q: ['Quebec City'],
      r: ['Riga'],
      s: ['Suez', 'Stockholm', 'Shanghai', 'Seoul'],
      t: ['Tokyo', 'Taipei'],
      u: ['Utrecht', 'Uppsala'],
      v: ['Vancouver', 'Victoria', 'Venice', 'Valencia'],
      w: ['Weymouth'],
      x: ['Xiamen'],
      y: ['Yokohama'],
      z: ['Zamboanga'],
    }

    COASTAL_NAMES = {
      a: ['Athens', 'Alexandria', 'Amsterdam', 'Abu Dhabi'],
      b: ['Buenos Aires', 'Bangkok', 'Belfast', 'Bergen'],
      c: ['Cape Town', 'Casablanca', 'Copenhagen', 'Cancun', 'Caracas'],
      d: ['Durban', 'Dakar', 'Dubai', 'Dublin'],
      e: ['Edinburgh', 'Ensenada'],
      f: ['Fukuoka', 'Fujisawa'],
      g: [],
      h: ['Hong Kong'],
      i: ['Inverness', 'Istanbul', 'Incheon', 'Izmir'],
      j: ['Jeju City', 'Jakarta'],
      k: ['Karachi', 'Kingston'],
      l: ['Lagos', 'Lima', 'Liverpool', 'Londonderry'],
      m: ['Mumbai', 'Macao', 'Melbourne'],
      n: ['Naples', 'Nicosia', 'Nice'],
      o: ['Osaka', 'Oslo'],
      p: ['Panama City', 'Perth'],
      q: ['Quincy'],
      r: ['Rio de Janeiro', 'Riga'],
      s: ['Shanghai', 'Suez', 'Stockholm'],
      t: ['Tulum', 'Tokyo'],
      u: [],
      v: ['Vancouver', 'Victoria', 'Venice', 'Veracruz', 'Valencia'],
      w: ['Wellington', 'Weymouth'],
      x: ['Xiamen'],
      y: ['Yokohama'],
      z: ['Zamboanga'],
    }

    ISLAND_NAMES = {
      a: ['Aruba'],
      b: ['Bimini', 'Bermuda'],
      c: ['Corsica', 'Corfu', 'Curacao'],
      d: ['Dominica'],
      e: [],
      f: ['Falklands'],
      g: ['Guernsey'],
      h: ['Havana', 'Hamilton'],
      i: ['Ibiza'],
      j: ['Jeju City', 'Jersey'],
      k: ['Kingston'],
      l: [],
      m: ['Malta', 'Mikonos', 'Montego Bay'],
      n: ['Nicosia', 'Nassau'],
      o: [],
      p: ['Palma', 'Port-au-Prince'],
      q: [],
      r: [],
      s: ['Sardinia', 'Santo Domingo', 'San Juan'],
      t: ['Tortuga'],
      u: [],
      v: ['Vancouver Island'],
      w: [],
      x: ['Xiamen'],
      y: [],
      z: [],
    }

    MOUNTAIN_NAMES = {
      a: ['Addis Ababa'],
      b: ['Bogota'],
      c: ['Chamonix'],
      d: ['Davos'],
      e: [],
      f: [],
      g: [],
      h: ['Highlands'],
      i: ['Innsbruck'],
      j: [],
      k: ['Kabul', 'Kathmandu'],
      l: ['La Paz'],
      m: ['Mexico City'],
      n: ['Nairobi'],
      o: [],
      p: ['Pretoria'],
      q: ['Quito'],
      r: [],
      s: ['Salamanca', 'Schwarzwald'],
      t: ['Tehran'],
      u: ['Ushuaia'],
      v: [],
      w: [],
      x: [],
      y: [],
      z: ['Zermatt',],
    }
  end

  module USA
    SYMS = Global::SYMS

    # fall back to MOUNTAIN_NAMES
    def USA.inland_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                       INLAND_NAMES, MOUNTAIN_NAMES, INLAND_NAMES,
                       exclude: exclude)
    end

    # fall back to ISLAND_NAMES
    def USA.coastal_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                       COASTAL_NAMES, ISLAND_NAMES, COASTAL_NAMES,
                       exclude: exclude)
    end

    # fall back to NAMES and COASTAL_NAMES (exclude mountain and island)
    def USA.delta_name(sym = nil, exclude: [])
      Global.meta_name(sym,
                       DELTA_NAMES, INLAND_NAMES, COASTAL_NAMES,
                       exclude: exclude)
    end

    # fall back to name()
    def USA.mountain_name(sym = nil, exclude: [])
      candidates = MOUNTAIN_NAMES.fetch(sym || SYMS.sample) - exclude
      return candidates.sample unless candidates.empty?
      if sym.nil? # try other random syms
        2.times {
          candidates = MOUNTAIN_NAMES.fetch(SYMS.sample) - exclude
          return candidates.sample unless candidates.empty?
        }
      end
      # if we've gotten this far, it's because sym != nil and !exclude.empty?
      # don't worry about circular reference back to MOUNTAIN_NAMES
      # calling name() ensures an exception if everything is excluded
      USA.inland_name(sym, exclude: exclude)
    end

    # fall back to coastal_name()
    def USA.island_name(sym = nil, exclude: [])
      candidates = ISLAND_NAMES.fetch(sym || SYMS.sample) - exclude
      return candidates.sample unless candidates.empty?
      if sym.nil?
        2.times {
          candidates = ISLAND_NAMES.fetch(SYMS.sample) - exclude
          return candidates.sample unless candidates.empty?
        }
      end
      # see above comment from USA.mountain_names
      USA.coastal_name(sym, exclude: exclude)
    end

    INLAND_NAMES = {
      a: ['Atlanta', 'Austin', 'Albuquerque',],
      b: ['Birmingham', 'Boise', 'Baton Rouge', 'Buffalo', 'Beaumont',],
      c: ['Chicago', 'Cleveland', 'Chattanooga',],
      d: ['Denver', 'Dallas', 'Detroit',],
      e: ['El Paso', 'Eugene', 'Escondido',],
      f: ['Fargo', 'Fresno', 'Fairbanks',],
      g: ['Grand Rapids', 'Garden Grove',],
      h: ['Houston', 'Helena',],
      i: ['Indianapolis',],
      j: ['Jackson', 'Joliet', 'Johnson City',],
      k: ['Kansas City', 'Knoxville',],
      l: ['Louisville', 'Las Vegas', 'Lincoln', 'Little Rock',],
      m: ['Memphis', 'Milwaukee', 'Minneapolis',],
      n: ['New Orleans', 'Nashville', 'Napa',],
      o: ['Omaha', 'Oklahoma City', 'Oakland', 'Orlando', 'Olympia',],
      p: ['Phoenix', 'Pittsburgh',],
      q: ['Quakertown',],
      r: ['Redmond', 'Richmond', 'Reno', 'Raleigh'],
      s: ['St. Louis', 'Santa Fe', 'San Antonio', 'San Jose',],
      t: ['Tucson', 'Tulsa', 'Torino', 'Tacoma',],
      u: ['Utica', 'Urbana', 'Ukiah',],
      v: ['Victorville', 'Vallejo',],
      w: ['Washington D.C.', 'Wichita', 'Winston-Salem',],
      x: ['Xenia',],
      y: ['Yonkers', 'Yuma',],
      z: ['Zion', 'Zephyrhills',],
    }

    DELTA_NAMES = {
      a: ['Anchorage',],
      b: ['Boston', 'Baltimore', 'Biloxi', 'Beaumont', 'Bodega Bay',
          'Boca Raton',],
      c: ['Chesapeake', 'Corpus Christi'],
      d: [],
      e: ['Eureka'],
      f: ['Fort Bragg'],
      g: ['Gold Beach', 'Garden Grove',],
      h: ['Houston', 'Homestead'],
      i: ['Inverness',],
      j: ['Jacksonville', 'Juneau', 'Jersey City', 'Jamestown',],
      k: ['Klamath', 'Ketchikan',],
      l: ['Long Beach',],
      m: ['Mobile',],
      n: ['New York City', 'New Orleans', 'Newport News', 'Norfolk',],
      o: ['Oakland', 'Olympia',],
      p: ['Philadelphia', 'Providence', 'Point Arena', 'Panama City',
          'Pensacola'],
      q: ['Quincy',],
      r: [],
      s: ['San Jose', 'Seattle', 'Savannah', 'Sarasota', 'St. Augustine'],
      t: ['Tacoma', 'Tampa',],
      u: ['Union City',],
      v: ['Vallejo', 'Ventura',],
      w: ['Wilmington', 'West Palm Beach',],
      x: [],
      y: ['Yonkers'],
      z: [],
    }

    COASTAL_NAMES = {
      a: ['Anchorage', 'Athens', 'Alexandria', 'Alys Beach',],
      b: ['Boston', 'Baltimore', 'Biloxi', 'Bodega Bay', 'Boca Raton',],
      c: ['Charleston', 'Corpus Christi', 'Chesapeake', 'Clearwater'],
      d: ['Daytona Beach', 'Destin',],
      e: ['Encinitas', 'Eureka',],
      f: ['Fort Lauderdale', 'Fort Bragg',],
      g: ['Galveston', 'Gold Beach', 'Gold Coast'],
      h: ['Honolulu', 'Huntington Beach', 'Homestead',],
      i: ['Irvine', 'Inverness',],
      j: ['Jacksonville', 'Jamestown', 'Juneau', 'Jersey City'],
      k: ['Key West', 'Klamath', 'Ketchikan'],
      l: ['Los Angeles', 'Long Beach',],
      m: ['Miami', 'Myrtle Beach', 'Mobile',],
      n: ['New York City', 'Norfolk', 'Newport News', 'Newport Beach',],
      o: ['Oceanside',],
      p: ['Portland', 'Philadelphia', 'Providence', 'Point Arena',
          'Panama City', 'Pensacola'],
      q: ['Quincy',],
      r: ['Redondo Beach',],
      s: ['San Francisco', 'Seattle', 'San Diego', 'Savannah', 'Sarasota',
          'St. Petersburg', 'St. Augustine'],
      t: ['Tampa', 'Tulum',],
      u: ['Union City'],
      v: ['Virginia Beach', 'Ventura',],
      w: ['Wilmington', 'West Palm Beach',],
      x: [],
      y: ['Ybor City'],
      z: [],
    }

    ISLAND_NAMES = {
      a: [],
      b: ['Bimini', 'Bermuda'],
      c: [],
      d: ['Dominica'],
      e: [],
      f: ['Falklands'],
      g: [],
      h: ['Havana', 'Hamilton'],
      i: [],
      j: [],
      k: ['Key West', 'Key Largo', 'Kingston'],
      l: [],
      m: ['Montego Bay'],
      n: ['Nassau'],
      o: [],
      p: ['Port-au-Prince'],
      q: [],
      r: [],
      s: ['San Juan'],
      t: ['Tortuga'],
      u: [],
      v: ['Vancouver Island'],
      w: [],
      x: [],
      y: [],
      z: [],
    }

    MOUNTAIN_NAMES = {
      a: ['Aspen', 'Asheville', 'Albuquerque',],
      b: ['Boone', 'Breckenridge', 'Boulder',],
      c: ['Crested Butte', 'Cheyenne',],
      d: ['Denver', 'Deer Valley',],
      e: ['Ellijay', 'El Paso'],
      f: ['Frisco', 'Flagstaff'],
      g: ['Grand Junction'],
      h: ['Highlands', 'Heavenly'],
      i: ['Idaho Falls',],
      j: ['Jackson Hole'],
      k: ['Keystone',],
      l: ['La Paz', 'Lake Tahoe', 'Laramie'],
      m: ['Missoula',],
      n: [],
      o: ['Ogden'],
      p: ['Park City',],
      q: [],
      r: ['Rapid City'],
      s: ['Sun Valley', 'Salt Lake City', 'Snowmass', 'Stowe', 'Santa Fe',],
      t: ['Taos', 'Telluride',],
      u: [],
      v: ['Vail'],
      w: ['Winter Park'],
      x: [],
      y: ['Yuma'],
      z: [],
    }
  end
end
