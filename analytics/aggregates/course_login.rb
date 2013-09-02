class Analytics::CourseLogin
  include Analytics::Aggregate

  field :course_id, type: Integer

  # course_id: 1,
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
    self.where(course_id: event.course_id)
  end
end
