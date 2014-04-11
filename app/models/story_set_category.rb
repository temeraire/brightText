class StorySetCategory < ActiveRecord::Base
  has_many :story_sets, :foreign_key => :category_id, :dependent => :destroy
  belongs_to :bright_text_application, :foreign_key => :application_id
  attr_accessible :rank, :name, :description, :application_id
  validates :name,
              :uniqueness => { :scope => :application_id, :message => "This name is already taken. Please select another name" },
              :presence => {:message => "Please insert a name."}

  def application
    return "-- unassigned --" if ( application_id == nil )

    appObj = BrightTextApplication.find_by_sql [ "select * from bright_text_applications where id = ?", application_id ]
    return appObj[0].name unless appObj == nil || appObj.count < 1
  end

  before_save :set_rank

  def set_rank
    if self.rank.blank? || self.rank == 0 || self.application_id_changed?
      self.rank = 1 + StorySetCategory.maximum(:rank, :conditions => ["application_id = ?", self.application_id]).to_i
    end
  end

  def self.dummy_story_set_category()
    dummy = StorySetCategory.new
    dummy.name = "My Stuff Will Appear Here";
    dummy.rank = 1;
    return dummy
  end
end
