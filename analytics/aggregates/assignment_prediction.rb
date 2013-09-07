# TODO: refactor as AssignmentPredictionScore of type Aggregate::Average
class Analytics::AssignmentPrediction
  include Analytics::Aggregate

  field :assignment_id, type: Integer

  increment_keys "%{granular_key}.total" => lambda{ |event| event.data['score'].to_f / event.data['possible'].to_f },
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

  def self.aggregate_scope(event)
    self.where(assignment_id: event.data['assignment_id'])
  end
end
