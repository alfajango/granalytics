# TODO: refactor as AssignmentUserEvent of type Aggregate::Count
class Analytics::AssignmentUserEvent
  include Analytics::Aggregate

  field :assignment_id, type: Integer
  field :user_id, type: Integer
  field :events, type: Hash

  scope_by :assignment_id, :user_id

  increment_keys "events.%{event_type}.%{granular_key}" => 1,
                 "events._all.%{granular_key}" => 1

  # assignment_id: 1,
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
end
