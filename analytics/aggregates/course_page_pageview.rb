# TODO: refactor as CoursePageview of type Aggregate::Count
class Analytics::CoursePagePageview
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :page, type: String

  # course_id: 1,
  # page: "/some/page",
  # all_time: %,
  # yearly: {
  #   key: %
  # },
  # monthly: {
  #   key: %
  # },
  # weekly: {
  #   key: %
  # },
  # daily: {
  #   key: %
  # },
  # hourly: {
  #   key: %
  # },
  # minutely: {
  #   key: %
  # }

  def self.aggregate_scope(event)
    self.where(course_id: event.course_id, page: event.data['page'])
  end

  def self.upsert_hash(event)
    upsert_hash = Hash.new.tap do |hash|
      GRANULARITIES.each do |granularity, interval|
        granular_key = [granularity, self.time_key(event.created_at, interval)].compact

        hash[ granular_key.join('.') ] = 1
      end
    end
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
      only("page", *keys).to_a

    count_data.each { |d| d[:name] = d.page }

    return {
      range: range,
      key: "#{granularity}",
      data: count_data
    }
  end
end
