class Analytics::CoursePrediction
  include Analytics::Aggregate

  field :course_id, type: Integer

  # course_id: 1,
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
    self.where(course_id: event.course_id)
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
