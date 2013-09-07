# TODO: refactor as AssignmentEvent type Aggregate::Count
class Analytics::AssignmentEvent
  include Analytics::Aggregate

  field :assignment_id, type: Integer
  field :events, type: Hash

  scope_by :assignment_id

  increment_keys "events.%{event_type}.%{granular_key}" => 1,
                 "events._all.%{granular_key}" => 1

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

  def self.data(granularity, from, to, assignments, event="_all")
    interval = GRANULARITIES[granularity]
    start_at = self.time_key(from, interval)
    end_at = to.to_i
    range = (start_at..end_at).step(interval)

    keys = range.map { |i| :"events.#{event}.#{granularity}.#{i}"}

    count_data = self.
      in(assignment_id: assignments.keys).
      where('$or' => keys.map{ |k| {k => { '$exists' => true}} }).
      only("assignment_id", *keys).to_a

    count_data.each { |d| d[:name] = assignments[d.assignment_id] }

    return {
      range: range,
      key: "events.#{event}.#{granularity}",
      data: count_data
    }
  end
end
