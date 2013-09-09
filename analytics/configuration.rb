class Analytics::Configuration
  attr_accessor :event_aggregates,
                :default_granularity_options_for_select,
                :default_range_options_for_select

  def initialize
    self.event_aggregates = {}
    self.default_granularity_options_for_select = Analytics::Aggregate::GRANULARITIES.keys[1..-1].collect{ |g| [g.to_s.titleize, g] }.unshift(["Auto", nil])
    self.default_range_options_for_select = [['Past Day', 'past_day'], ['Past Week', 'past_week'], ['Past Month', 'past_month'], ['Past Year', 'past_year']]
  end
end
