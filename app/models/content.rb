# content in a course pack (either an article or a chapter seperator)
class Content
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :course_pack
  field :title, type: String, default: ""
  field :num_pages, type: Integer
  field :weight, type: Integer, default: 0 #controls order of appearance in the CoursePack
  attr_accessible :title, :num_pages, :weight, :_type
  attr_accessor :temp_id

  def initialize(attributes, options)
    super(attributes, options)

    # also initialize the non-persistent temp_id
    @temp_id = attributes[:temp_id]
  end

  def as_json(options={})
    result = super(options)
    result[:temp_id] = temp_id
    result
  end
end
