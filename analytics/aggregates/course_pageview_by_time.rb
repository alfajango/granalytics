# TODO: refactor as CoursePageviewByTime of type Aggregate::Count
class Analytics::CoursePageviewByTime
  include Analytics::Aggregate

  field :course_id, type: Integer

  scope_by :course_id

  increment_keys "%{granular_key}.pages.%{page}" => 1,
                 "%{granular_key}.pages._all" => 1

  # course_id: 1,
  # all_time: {
  #   pages: {
  #     "_all": %,
  #     "/some/page": %
  #   }
  # },
  # yearly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # monthly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # weekly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # daily: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # hourly: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # },
  # minutely: {
  #   key: {
  #     pages: {
  #       "_all": %,
  #       "/some/page": %
  #     }
  #   }
  # }
end
