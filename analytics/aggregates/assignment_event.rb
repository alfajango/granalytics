class Analytics::AssignmentEvent
  include Analytics::Aggregate

  field :assignment_id, type: Integer
  field :events, type: Hash

  # assignment_id: 1,
  # events: {
  #   "_all": {
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
  #   },
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

  def self.aggregate_scope(event)
    self.where(assignment_id: event.assignment_id)
  end

  def self.upsert_hash(event)
    upsert_hash = Hash.new.tap do |hash|
      GRANULARITIES.each do |granularity, interval|
        event_key = ["events", event.event_type]
        granular_key = [granularity, self.time_key(event.created_at, interval)].compact

        hash[ (event_key + granular_key).join('.') ] = 1
        hash[ (["events", "_all"] + granular_key).join('.') ] = 1
      end
    end
  end

  def self.data(granularity, from, to, assignments, event="_all")
    interval = GRANULARITIES[granularity]
    start_at = self.time_key(from, interval)
    end_at = to.to_i
    range = (start_at..end_at).step(interval)

    keys = range.map { |i| :"events.#{event}.#{granularity}.#{i}"}

    all_data = self.
      in(assignment_id: assignments.keys).
      where('$or' => keys.map{ |k| {k => { '$exists' => true}} }).
      only("assignment_id", *keys).to_a

    events = all_data.collect { |d| d.events.keys }.flatten.uniq

    return {
      range: range,
      events: events,
      assignments: assignments,
      data: all_data
    }
  end
end
