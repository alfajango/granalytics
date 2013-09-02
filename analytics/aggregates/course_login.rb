# TODO: refactor as CourseLoginFrequency type Aggregate::Average
class Analytics::CourseLogin
  include Analytics::Aggregate

  field :course_id, type: Integer

  ## No 'all_time' key since frequency for all-time would be 0
  # course_id: 1,
  # yearly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # monthly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # weekly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # daily: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # hourly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # minutely: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # }

  def self.incr(event)
    super
    # TODO: calculage cached average
  end

  def self.aggregate_scope(event)
    self.where(course_id: event.course_id)
  end

  def self.upsert_hash(event)
    upsert_hash = Hash.new.tap do |hash|
      GRANULARITIES.except(:all_time).each do |granularity, interval|
        freq = self.frequency(interval, event.data['last_login_at'], event.created_at)
        granular_key = [granularity, self.time_key(event.created_at, interval)].compact

        hash[ (granular_key + ['total']).join('.') ] = freq
        hash[ (granular_key + ['count']).join('.') ] = 1
      end
    end
  end

  def self.frequency(interval, last_time, this_time)
    ( interval.to_f / (this_time.to_i - last_time.to_i) ).round(2)
  end
end
