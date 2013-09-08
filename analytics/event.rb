class Analytics::Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :event_type, type: String
  field :created_at, type: DateTime

  validates :event_type, :created_at, presence: true

  after_create do |event|
    case event.event_type
    when 'predictor'
      AssignmentEvent.incr(event)
      AssignmentPrediction.incr(event)
      AssignmentUserEvent.incr(event)
      CourseEvent.incr(event)
      CoursePrediction.incr(event)
      CourseUserEvent.incr(event)
    when 'pageview'
      CoursePageview.incr(event)
      CourseUserPageview.incr(event)
      CoursePageviewByTime.incr(event)
      CoursePagePageview.incr(event)
    when 'login'
      CourseLogin.incr(event)
      CourseUserLogin.incr(event)
    end
  end

  # TODO: Create methods to export Event collection for backup and clear out persisted collection.
end
