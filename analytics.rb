module Analytics
  # TODO: Add configuration to make Analytics::Event persistence optional.
end

require_dependency 'analytics/event'
require_dependency 'analytics/aggregate'
require_dependency 'analytics/data'
