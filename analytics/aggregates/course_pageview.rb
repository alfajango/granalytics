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
end
