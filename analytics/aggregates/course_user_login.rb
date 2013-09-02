class Analytics::CourseUserLogin
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :user_id, type: Integer

  # course_id: 1,
  # user_id: 1,
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
    self.where(course_id: event.course_id, user_id: event.user_id)
  end
end
