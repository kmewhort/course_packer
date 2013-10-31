# content in a course pack (either an article or a chapter seperator)
class Content
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :course_pack, touch: true
  field :title, type: String, default: ""
  field :num_pages, type: Integer
  field :weight, type: Integer, default: 0 #controls order of appearance in the CoursePack
  attr_accessible :title, :num_pages, :weight, :_type, :_id

  before_destroy {|content| content.course_pack.touch unless content.course_pack.nil? }
end
