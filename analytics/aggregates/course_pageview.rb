# TODO: refactor as CoursePageview of type Aggregate::Count
class Analytics::CoursePageview
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :pages, type: Hash

  scope_by :course_id

  increment_keys "pages.%{page}.%{granular_key}" => 1,
                 "pages._all.%{granular_key}" => 1

  # course_id: 1,
  # pages: {
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
  #   "/some/page": {
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

  def self.data(granularity, from, to, course, page="_all")
    interval = GRANULARITIES[granularity]
    start_at = self.time_key(from, interval)
    end_at = to.to_i
    range = (start_at..end_at).step(interval)

    keys = range.map { |i| :"pages.#{page}.#{granularity}.#{i}"}

    count_data = self.
      in(course_id: course.id).
      where('$or' => keys.map{ |k| {k => { '$exists' => true}} }).
      only(*keys).to_a

    count_data.each { |d| d[:name] = course.name }

    return {
      range: range,
      key: "pages.#{page}.#{granularity}",
      data: count_data
    }
  end
end
