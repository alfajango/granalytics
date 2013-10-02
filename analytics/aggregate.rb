module Analytics::Aggregate
  GRANULARITIES = {
    :all_time => nil,
    :yearly => 1.year.to_i,
    :monthly => 1.month.to_i,
    :weekly => 1.week.to_i,
    :daily => 1.day.to_i,
    :hourly => 1.hour.to_i,
    :minutely => 1.minute.to_i
  }

  RANGE_SELECTS = {
    :past_year => lambda { (1.year.ago..Time.now) },
    :past_month => lambda { (1.month.ago..Time.now) },
    :past_week => lambda { (1.week.ago..Time.now) },
    :past_day => lambda { (1.day.ago..Time.now) },
    :past_hour => lambda { (1.hour.ago..Time.now) },
  }

  AUTO_RANGE_GRANULARITIES = {
    :past_year => :monthly,
    :past_month => :weekly,
    :past_week => :daily,
    :past_day => :hourly,
    :past_hour => :minutely
  }

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, Mongoid::Document)
  end

  # t = event.created_at
  # interval = GRANULARITIES[granularity]
  # key = ( t.to_i / interval ) * interval
  # % = count
  #
  # e.g.
  # events: {
  #   "predictor": {
  #     all_time: %,
  #     yearly: {
  #       key: %
  #     },
  #     monthly: {
  #       key: %
  #     },
  #     weekly: {
  #       key: %
  #     },
  #     daily: {
  #       key: %
  #     },
  #     hourly: {
  #       key: %
  #     },
  #     minutely: {
  #       key: %
  #     }
  #   }
  # }

  module ClassMethods
    def incr(event)
      self.aggregate_scope(event).find_and_modify({'$inc' => upsert_hash(event)}, {'upsert' => 'true', :new => true})
    end

    def aggregate_scope(event)
      self.where( Hash[ @scope_by.map{ |k| [k, format_hash(event)[k]] } ] )
    end

    # Build the upsert hash for Mongo from the increment_keys and granularities
    def upsert_hash(event)
      h = format_hash(event)

      Hash.new.tap do |hash|
        @increment_keys.each do |key, value|
          # Set and cache increment value if it's numeric (i.e. static independent of event or granularity)
          # or if it's a lambda that requires the event instance as the only argument
          inc_value = value.respond_to?(:call) && value.arity == 1 ? value.call(event) : value

          if key.to_s.include?("%{granular_key}")
            GRANULARITIES.each do |granularity, interval|
              # Set the increment value if it's a lambda that requires the event instance and the granularity
              # and interval as arguments (i.e. it's still a lambda due to having arity != 1 above)
              inc_value = inc_value.call(event, granularity, interval) if inc_value.respond_to?(:call)

              h[:granular_key] = granular_key(granularity, interval, event.created_at)
              hash[ sprintf(key, h) ] = inc_value
            end
          else
            hash[ sprintf(key, h) ] = inc_value
          end
        end
      end
    end

    def decr(event)
      # First decrement
      hash = downsert_hash(event)
      scope = self.aggregate_scope(event)
      #STDOUT.puts "  Decrementing #{self.name} #{scope.selector}"

      record = scope.find_and_modify({'$inc' => hash}, {:new => true})

      # Then, remove if values empty (this is the opposite of the 'upsert' => 'true' in the #incr method)
      unset_keys = {}
      hash.keys.each do |key|

        # Remove the key if new value is zero or NaN
        if record[key] == 0 || (record[key].is_a?(Float) && record[key].nan?)
          record.unset(key)

          key_levels = key.split('.')

          # Then delete each parent key of nested hash if it is now empty after unset
          loop do
            # Start by popping once since key was unset above
            last_key = key_levels.pop

            break if key_levels.empty?

            next_key = key_levels.join('.')

            unset_keys[next_key] ? unset_keys[next_key] << last_key : unset_keys[next_key] = [last_key]
            value_excluding_unset_keys = record[next_key].reject{ |k,v| unset_keys[next_key].include?(k) }

            if value_excluding_unset_keys.empty?
              record.unset(next_key)
            else
              break
            end
          end
        end

      end
      #STDOUT.puts "  Unset keys: #{unset_keys}" if unset_keys.any?
      record
    end

    # Create the inverse of the upsert_hash
    def downsert_hash(event)
      Hash.new.tap do |hash|
        upsert_hash(event).each do |key, value|
          hash[ key ] = value * -1
        end
      end
    end

    # t = Time.now.to_i     #=> 1377704456
    # key(t, 1.year.to_i)   #=> 1356976800
    # key(t, 1.month.to_i)  #=> 1376352000
    # key(t, 1.week.to_i)   #=> 1377129600
    # key(t, 1.day.to_i)    #=> 1377648000
    # key(t, 1.hour.to_i)   #=> 1377702000
    # key(t, 1.minute.to_i) #=> 1377704400
    # key(t, nil)           #=> nil
    def time_key(time, interval)
      interval && ( time.to_i / interval ) * interval
    end

    # granular_key(:all_time, nil)           #=> "all_time"
    # granular_key(:minutely, 1.minute.to_i) #=> "minutely.1377704400"
    def granular_key(granularity, interval, time)
      [granularity, time_key(time, interval)].compact.join('.')
    end

    # Auto-populate our format_hash with all attributes from event.
    def format_hash(event)
      event.attributes.symbolize_keys
    end

    def scope_by(*keys)
      @scope_by = keys
    end

    def increment_keys(key_formats)
      @increment_keys = key_formats
    end

    # Can be called in following ways:
    # MyAggregate.data
    # MyAggregate.data(:minutely, 15.minutes.ago..Time.now)
    # MyAggregate.data(:minutely, :past_day)
    # MyAggregate.data(nil, :past_day)
    def data(granularity=nil, range=nil, scope={}, select_keys={})
      range = self.default_range if range.nil?

      if range.is_a?(Symbol)
        granularity ||= self.default_granularity(range)
        range = RANGE_SELECTS[range].call
      end

      granularity ||= self.default_granularity
      interval = GRANULARITIES[granularity]

      start_at = self.time_key(range.first, interval)
      end_at = range.last.to_i
      range = (start_at..end_at).step(interval)

      data_lookup_keys = @increment_keys.keys.map { |k| sprintf( k, select_keys.merge(granular_key: "{{t}}") ) }.uniq

      keys = range.to_a.product(@increment_keys.keys).map { |i, k| sprintf( k, select_keys.merge(granular_key: "#{granularity}.#{i}") ).to_sym }

      results = self.
        in(scope).
        where('$or' => keys.map{ |k| {k => { '$exists' => true}} }).
        only(*@scope_by, *keys).to_a

      return Analytics::Data.new(
        granularity,
        range,
        data_lookup_keys,
        results
      )
    end

    def set_default_granularity(granularity)
      @default_granularity = granularity
    end

    def set_default_range(range_symbol)
      @default_range = range_symbol
    end

    def default_granularity(range_symbol=nil)
      @default_granularity || AUTO_RANGE_GRANULARITIES[range_symbol || default_range]
    end

    def default_range
      @default_range ||= :past_day
    end
  end
end
