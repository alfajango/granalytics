# TODO: refactor as CoursePageview of type Aggregate::Count
class Analytics::CoursePagePageview
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :page, type: String

  scope_by :course_id, :page

  increment_keys "%{granular_key}" => 1

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
end
