# TODO: refactor as AssignmentPredictionScore of type Aggregate::Average
class Analytics::AssignmentPrediction
  include Analytics::Aggregate

  field :assignment_id, type: Integer

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

  def self.upsert_hash(event)
    total = (event.data['score'].to_f / event.data['possible'].to_f)
    upsert_hash = Hash.new.tap do |hash|
      GRANULARITIES.each do |granularity, interval|
        granular_key = [granularity, self.time_key(event.created_at, interval)].compact

        hash[ (granular_key + ['total']).join('.') ] = total
        hash[ (granular_key + ['count']).join('.') ] = 1
      end
    end
  end
end
