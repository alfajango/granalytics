# TODO: refactor as CoursePageviewByTime of type Aggregate::Count
class Analytics::CoursePageviewByTime
  include Analytics::Aggregate

  field :course_id, type: Integer

  increment_keys "%{granular_key}.pages.%{page}" => 1,
                 "%{granular_key}.pages._all" => 1

  # course_id: 1,
  # all_time: {
  #   pages: {
  #     "_all": %,
  #     "/some/page": %
  #   }
  # },
  # yearly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # monthly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # weekly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # daily: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # hourly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # minutely: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # }

  def self.aggregate_scope(event)
    self.where(course_id: event.course_id)
  end

  def self.format_hash(event)
    super.merge(:page => event.data['page'])
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

    count_data.each { |d| d[:name] = course.name }

    return {
      range: range,
      key: "#{granularity}",
      data: count_data
    }
  end
end
