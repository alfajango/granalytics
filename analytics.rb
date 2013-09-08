module Analytics
  # TODO: Add configuration to make Analytics::Event persistence optional.

  def self.configure(&block)
    yield configuration
  end

  def self.configuration
    @configuration ||= Analytics::Configuration.new
  end
end

require_dependency 'analytics/configuration'
require_dependency 'analytics/event'
require_dependency 'analytics/aggregate'
require_dependency 'analytics/data'
