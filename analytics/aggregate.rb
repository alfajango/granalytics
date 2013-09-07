module Analytics::Aggregate
  GRANULARITIES = {
    :all_time => nil,
    :yearly => 1.year.to_i,
    :monthly => 1.month.to_i,
    :weekly => 1.week.to_i,
    :daily => 1.day.to_i,
    :hourly => 1.hour.to_i,
    :minutely => 1.minute.to_i
  }

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, Mongoid::Document)
  end

  # t = event.created_at
  # interval = GRANULARITIES[granularity]
  # key = ( t.to_i / interval ) * interval
  # % = count
  #
  # e.g.
  # events: {
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

  module ClassMethods
    def incr(event)
      self.aggregate_scope(event).find_and_modify({'$inc' => upsert_hash(event)}, {'upsert' => 'true', :new => true})
    end

    def aggregate_scope(event)
      raise "Not Implemented"
    end

    def upsert_hash(event)
      raise "Not Implemented"
    end

    # t = Time.now.to_i     #=> 1377704456
    # key(t, 1.year.to_i)   #=> 1356976800
    # key(t, 1.month.to_i)  #=> 1376352000
    # key(t, 1.week.to_i)   #=> 1377129600
    # key(t, 1.day.to_i)    #=> 1377648000
    # key(t, 1.hour.to_i)   #=> 1377702000
    # key(t, 1.minute.to_i) #=> 1377704400
    # key(t, nil)           #=> nil
    def time_key(time, interval)
      interval && ( time.to_i / interval ) * interval
    end

    def data(granularity, start_at, end_at)
      raise "Not Implemented"
    end
  end
end

require_dependency 'analytics/aggregates/assignment_event'
require_dependency 'analytics/aggregates/assignment_prediction'
require_dependency 'analytics/aggregates/assignment_user_event'
require_dependency 'analytics/aggregates/course_event'
require_dependency 'analytics/aggregates/course_login'
require_dependency 'analytics/aggregates/course_pageview'
require_dependency 'analytics/aggregates/course_pageview_by_time'
require_dependency 'analytics/aggregates/course_page_pageview'
require_dependency 'analytics/aggregates/course_prediction'
require_dependency 'analytics/aggregates/course_user_event'
require_dependency 'analytics/aggregates/course_user_login'
require_dependency 'analytics/aggregates/course_user_pageview'
