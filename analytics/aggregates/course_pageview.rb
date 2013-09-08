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
end
