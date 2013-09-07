# TODO: refactor as CourseUserLoginFrequency type Aggregate::Average
class Analytics::CourseUserLogin
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :user_id, type: Integer

  increment_keys "%{granular_key}.total" => lambda { |event, granularity, interval| self.frequency(interval, event.data['last_login_at'], event.created_at) },
                 "%{granular_key}.count" => 1

  ## No 'all_time' key since frequency for all-time would be 0
  # course_id: 1,
  # user_id: 1,
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
    self.where(course_id: event.course_id, user_id: event.user_id)
  end

  def self.frequency(interval, last_time, this_time)
    ( interval.to_f / (this_time.to_i - last_time.to_i) ).round(2)
  end
end
