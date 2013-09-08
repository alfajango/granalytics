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

    def data(granularity, from, to, scope={}, select_keys={})
      interval = GRANULARITIES[granularity]
      start_at = self.time_key(from, interval)
      end_at = to.to_i
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
  end
end
