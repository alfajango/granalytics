class Analytics::Event
  include Mongoid::Document

  field :event_type, type: String
  field :course_id, type: Integer
  field :user_id, type: Integer
  field :data, type: Hash
  field :created_at, type: DateTime

  validates :event_type, :course_id, :user_id, :created_at, presence: true

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
    when 'login'
      Analytics::CourseLogin.incr(event)
      Analytics::CourseUserLogin.incr(event)
    end
  end
end
