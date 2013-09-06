# TODO: refactor as CoursePageview of type Aggregate::Count
class Analytics::CoursePageview
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :pages, type: Hash

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

  def self.aggregate_scope(event)
    self.where(course_id: event.course_id)
  end

  def self.upsert_hash(event)
    page = event.data['page']
    upsert_hash = Hash.new.tap do |hash|
      GRANULARITIES.each do |granularity, interval|
        page_key = ["pages", page]
        granular_key = [granularity, self.time_key(event.created_at, interval)].compact

        hash[ (page_key + granular_key).join('.') ] = 1
        hash[ (["pages", "_all"] + granular_key).join('.') ] = 1
      end
    end
  end

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
