# TODO: refactor as CourseUserEvent of type Aggregate::Count
class Analytics::CourseUserEvent
  include Analytics::Aggregate

  field :course_id, type: Integer
  field :user_id, type: Integer
  field :events, type: Hash

  increment_keys "events.%{event_type}.%{granular_key}" => 1,
                 "events._all.%{granular_key}" => 1

  # course_id: 1,
  # user_id: 1,
  # events: {
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
  #   "predictor": {
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
    self.where(course_id: event.course_id, user_id: event.user_id)
  end
end
