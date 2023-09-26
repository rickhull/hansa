module Hansa
  class City
    def self.name(sym, exclude: [])
      candidates = NAMES.fetch(sym) - exclude
      if candidates.empty?
        candidates = MOUNTAIN_NAMES.fetch(sym) +
                     NAMES.fetch(sym) - exclude
        if candidates.empty?
          raise("No candidates for #{sym} (exclude: #{exclude.inspect}")
        end
      end
      candidates.sample
    end

    def self.coastal_name(sym, exclude: [])
      candidates = COASTAL_NAMES.fetch(sym) - exclude
      if candidates.empty?
        candidates = ISLAND_NAMES.fetch(sym) +
                     COASTAL_NAMES.fetch(sym) - exclude
        if candidates.empty?
          raise("No candidates for #{sym} (exclude: #{exclude.inspect}")
        end
      end
      candidates.sample
    end

    def self.delta_name(sym, exclude: [])
      candidates = DELTA_NAMES.fetch(sym) - exclude
      if candidates.empty?
        candidates = NAMES.fetch(sym) +
                     COASTAL_NAMES.fetch(sym) - exclude
        if candidates.empty?
          raise("No candidates for #{sym} (exclude: #{exclude.inspect}")
        end
      end
      candidates.sample
    end

    def self.mountain_name(sym, exclude: [])
      candidates = MOUNTAIN_NAMES.fetch(sym) - exclude
      if candidates.empty?
        self.name(sym, exclude: exclude)
      else
        candidates.sample
      end
    end

    def self.island_name(sym, exclude: [])
      candidates = ISLAND_NAMES.fetch(sym) - exclude
      if candidates.empty?
        self.coastal_name(sym, exclude: exclude)
      else
        candidates.sample
      end
    end

    NAMES = {
      a: ['Atlanta', 'Austin', 'Albuquerque',
          'Antwerp', 'Ankara', 'Aleppo'],
      b: ['Birmingham', 'Boise', 'Baton Rouge', 'Buffalo', 'Beaumont',
          'Brussels', 'Beijing', 'Bogota'],
      c: ['Chicago', 'Cleveland', 'Chattanooga', 'Cairo', 'Cordoba'],
      d: ['Denver', 'Dallas', 'Detroit', 'Delhi', 'Damascus', 'Dusseldorf'],
      e: ['El Paso', 'Eugene', 'Escondido', 'Edmonton', 'Essen', 'Eindhoven'],
      f: ['Fargo', 'Fresno', 'Fairbanks', 'Frankfurt', 'Florence'],
      g: ['Grand Rapids', 'Garden Grove', 'Glasgow', 'Giza'],
      h: ['Houston', 'Helena', 'Hamburg', 'Hyderabad'],
      i: ['Indianapolis', 'Isfahan'],
      j: ['Jackson', 'Jersey', 'Johannesburg', 'Jerusalem'],
      k: ['Kansas City', 'Knoxville', 'Krakow', 'Kinshasa', 'Kyiv'],
      l: ['Louisville', 'Las Vegas', 'Lincoln', 'Little Rock',
          'London', 'La Paz'],
      m: ['Memphis', 'Milwaukee', 'Minneapolis',
          'Montreal', 'Manchester', 'Moscow', 'Madrid'],
      n: ['New Orleans', 'Nashville', 'Napa',
          'Nairobi', 'Novosibirsk', 'Nottingham'],
      o: ['Omaha', 'Oklahoma City', 'Oakland', 'Orlando', 'Olympia',
          'Odessa', 'Ottawa'],
      p: ['Phoenix', 'Pittsburgh', 'Paris', 'Pretoria', 'Pyongyang'],
      q: ['Quakertown', 'Quito', 'Quebec City'],
      r: ['Redmond', 'Richmond', 'Reno', 'Raleigh', 'Rome'],
      s: ['St. Louis', 'Santa Fe', 'San Antonio', 'San Jose',
          'Sao Paolo', 'Seville', 'Seoul'],
      t: ['Tucson', 'Tulsa', 'Torino', 'Tacoma',
          'Taipei', 'Tehran'],
      u: ['Utica', 'Urbana', 'Ukiah', 'Utrecht', 'Urumqi', 'Uppsala'],
      v: ['Victorville', 'Vallejo', 'Vienna'],
      w: ['Washington D.C.', 'Wichita', 'Winston-Salem',
          'Wuhan', 'Warsaw'],
      x: ['Xenia', "Xi'ian", 'Xolchimilco'],
      y: ['Yonkers', 'Yuma', 'Yakutsk'],
      z: ['Zion', 'Zephyrhills', 'Zhengzhou', 'Zaporizhia', 'Zagreb'],
    }

    DELTA_NAMES = {
      a: ['Anchorage', 'Amsterdam', 'Antwerp'],
      b: ['Boston', 'Baltimore', 'Biloxi', 'Beaumont', 'Bodega Bay',
          'Belfast', 'Bergen'],
      c: ['Chesapeake', 'Corpus Christi'],
      d: ['Dublin'],
      e: ['Eureka'],
      f: ['Fort Bragg'],
      g: ['Gold Beach', 'Garden Grove', 'Glasgow'],
      h: ['Houston', 'Homestead'],
      i: ['Inverness', 'Istanbul', 'Incheon'],
      j: ['Jacksonville', 'Juneau', 'Jersey City', 'Jeju City'],
      k: ['Klamath', 'Ketchikan', 'Karachi'],
      l: ['Long Beach', 'Lagos', 'London', 'Liverpool', 'Londonderry'],
      m: ['Mobile', 'Montreal', 'Melbourne'],
      n: ['New York City', 'New Orleans', 'Newport News', 'Norfolk',
          'Nicosia', 'Nice'],
      o: ['Oakland', 'Olympia', 'Osaka', 'Oslo'],
      p: ['Philadelphia', 'Providence', 'Point Arena',
          'Panama City', 'Pyongyang', 'Perth'],
      q: ['Quincy', 'Quebec City'],
      r: ['Riga'],
      s: ['San Jose', 'Seattle', 'Savannah',
          'Suez', 'Stockholm', 'Shanghai', 'Seoul'],
      t: ['Tacoma', 'Tampa', 'Tokyo', 'Taipei'],
      u: ['Union City', 'Utrecht', 'Uppsala'],
      v: ['Vallejo', 'Ventura',
          'Vancouver', 'Victoria', 'Venice', 'Valencia'],
      w: ['Wilmington', 'West Palm Beach', 'Weymouth'],
      x: ['Xiamen'],
      y: ['Yonkers', 'Yokohama'],
      z: ['Zamboanga'],
    }

    COASTAL_NAMES = {
      a: ['Anchorage', 'Athens', 'Alexandria', 'Amsterdam', 'Abu Dhabi'],
      b: ['Boston', 'Baltimore', 'Biloxi', 'Bodega Bay',
          'Buenos Aires', 'Bangkok', 'Belfast', 'Bergen'],
      c: ['Charleston', 'Corpus Christi', 'Chesapeake', 'Cape Town',
          'Casablanca', 'Copenhagen', 'Cancun', 'Caracas'],
      d: ['Daytona Beach', 'Durban', 'Dakar', 'Dubai', 'Dublin'],
      e: ['Encinitas', 'Eureka', 'Edinburgh', 'Ensenada'],
      f: ['Fort Lauderdale', 'Fort Bragg', 'Fukuoka', 'Fujisawa'],
      g: ['Galveston', 'Gold Beach', 'Gold Coast'],
      h: ['Honolulu', 'Huntington Beach', 'Homestead', 'Hong Kong'],
      i: ['Irvine', 'Inverness', 'Istanbul', 'Incheon', 'Izmir'],
      j: ['Jacksonville', 'Juneau', 'Jersey City', 'Jeju City', 'Jakarta'],
      k: ['Key West', 'Klamath', 'Ketchikan', 'Karachi'],
      l: ['Los Angeles', 'Long Beach',
          'Lagos', 'Lima', 'Liverpool', 'Londonderry'],
      m: ['Miami', 'Myrtle Beach', 'Mobile',
          'Mumbai', 'Macao', 'Melbourne'],
      n: ['New York City', 'Norfolk', 'Newport News', 'Newport Beach',
          'Naples', 'Nicosia', 'Nice'],
      o: ['Oceanside', 'Osaka', 'Oslo'],
      p: ['Portland', 'Philadelphia', 'Providence', 'Point Arena',
          'Panama City', 'Perth'],
      q: ['Quincy'],
      r: ['Redondo Beach', 'Rio de Janeiro', 'Riga'],
      s: ['San Francisco', 'Seattle', 'San Diego', 'Savannah',
          'Shanghai', 'Suez', 'Stockholm'],
      t: ['Tampa', 'Tulum', 'Tokyo'],
      u: ['Union City'],
      v: ['Virginia Beach', 'Ventura',
          'Vancouver', 'Victoria', 'Venice', 'Veracruz', 'Valencia'],
      w: ['Wilmington', 'West Palm Beach',
          'Wellington', 'Weymouth'],
      x: ['Xiamen'],
      y: ['Yokohama'],
      z: ['Zamboanga'],
    }

    ISLAND_NAMES = {
      a: [],
      b: ['Bimini'],
      c: ['Corsica', 'Corfu'],
      d: [],
      e: [],
      f: [],
      g: ['Guernsey'],
      h: [],
      i: ['Ibiza'],
      j: ['Jeju City', 'Jersey'],
      k: ['Key West', 'Key Largo'],
      l: [],
      m: ['Malta', 'Mikonos'],
      n: ['Nicosia', 'Nassau'],
      o: [],
      p: ['Palma'],
      q: [],
      r: [],
      s: ['Sardinia'],
      t: [],
      u: [],
      v: ['Vancouver Island'],
      w: [],
      x: ['Xiamen'],
      y: [],
      z: [],
    }

    MOUNTAIN_NAMES = {
      a: ['Aspen', 'Asheville', 'Albuquerque'],
      b: ['Boone', 'Breckenridge', 'Boulder'],
      c: ['Crested Butte', 'Cheyenne'],
      d: ['Denver', 'Deer Valley'],
      e: ['Ellijay', 'El Paso'],
      f: ['Frisco', 'Flagstaff'],
      g: ['Grand Junction'],
      h: ['Highlands', 'Heavenly'],
      i: ['Idaho Falls'],
      j: [],
      k: ['Keystone'],
      l: ['La Paz', 'Lake Tahoe', 'Laramie'],
      m: ['Missoula'],
      n: [],
      o: ['Ogden'],
      p: ['Park City'],
      q: ['Quito'],
      r: ['Rapid City'],
      s: ['Sun Valley', 'Salt Lake City', 'Snowmass', 'Stowe', 'Santa Fe'],
      t: ['Taos', 'Telluride'],
      u: [],
      v: ['Vail'],
      w: ['Winter Park'],
      x: [],
      y: ['Yuma'],
      z: [],
    }
  end
end
