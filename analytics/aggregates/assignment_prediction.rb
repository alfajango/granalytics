# TODO: refactor as AssignmentPredictionScore of type Aggregate::Average
class Analytics::AssignmentPrediction
  include Analytics::Aggregate

  field :assignment_id, type: Integer

  scope_by :assignment_id

  increment_keys "%{granular_key}.total" => lambda{ |event| event.score.to_f / event.possible.to_f },
                 "%{granular_key}.count" => 1

  # assignment_id: 1,
  # all_time: %,
  # yearly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # monthly: {
  #   ...
  # },
  # ...

  def self.incr(event)
    super
    # TODO: Increment cached average
  end
end
