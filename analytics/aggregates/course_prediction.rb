# TODO: refactor as CoursePredictionScore of type Aggregate::Average
class Analytics::CoursePrediction
  include Analytics::Aggregate

  field :course_id, type: Integer

  scope_by :course_id

  increment_keys "%{granular_key}.total" => lambda { |event| event.data['score'].to_f / event.data['possible'].to_f },
                 "%{granular_key}.count" => 1

  # course_id: 1,
  # all_time: %,
  # yearly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # monthly: {
  #   ...
  # },
  # ...

  def self.incr(event)
    super
    # TODO: Increment cached average
  end

  def self.data(granularity, from, to, course)
    interval = GRANULARITIES[granularity]
    start_at = self.time_key(from, interval)
    end_at = to.to_i
    range = (start_at..end_at).step(interval)

    keys = range.map { |i| :"#{granularity}.#{i}"}

    count_data = self.
      in(course_id: course.id).
      where('$or' => keys.map{ |k| {k => { '$exists' => true}} }).
      only(*keys).to_a

    count_data.each do |d|
      d[:name] = course.name
      d[granularity].each do |key, values|
        d[granularity][key] = (values['total'] / values['count'] * 100).to_i
      end
    end

    return {
      range: range,
      key: "#{granularity}",
      data: count_data
    }
  end
end
