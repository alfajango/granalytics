class Analytics::Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :event_type, type: String
  field :created_at, type: DateTime

  validates :event_type, :created_at, presence: true

  after_create do |event|
    case event.event_type
    when 'predictor'
      Analytics::AssignmentEvent.incr(event)
      Analytics::AssignmentPrediction.incr(event)
      Analytics::AssignmentUserEvent.incr(event)
      Analytics::CourseEvent.incr(event)
      Analytics::CoursePrediction.incr(event)
      Analytics::CourseUserEvent.incr(event)
    when 'pageview'
      Analytics::CoursePageview.incr(event)
      Analytics::CourseUserPageview.incr(event)
      Analytics::CoursePageviewByTime.incr(event)
      Analytics::CoursePagePageview.incr(event)
    when 'login'
      Analytics::CourseLogin.incr(event)
      Analytics::CourseUserLogin.incr(event)
    end
  end

  # TODO: Create methods to export Event collection for backup and clear out persisted collection.
end
