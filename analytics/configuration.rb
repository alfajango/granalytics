class Analytics::Configuration
  attr_accessor :event_aggregates

  def initialize
    self.event_aggregates = {}
  end
end
