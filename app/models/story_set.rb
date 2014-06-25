class StorySet < ActiveRecord::Base
  has_many :stories, :dependent => :destroy
  belongs_to :story_set_category, :foreign_key => :category_id
  attr_accessible :name, :category_id, :rank
  before_save :set_rank

  validates :name,
              :uniqueness => { :scope => :category_id, :message => "This name is already taken. Please select another name" },
              :presence => {:message => "Please insert a name."}

  def category
    return "-- unassigned --" if ( category_id == nil )

    catObj = StorySetCategory.find_by_sql [ "select * from story_set_categories where id = ?", category_id ]
    return catObj[0].name unless catObj == nil || catObj.count < 1
  end

  def set_rank
    if self.rank.blank? || self.rank == 0 || self.category_id_changed?
      self.rank = 1 + StorySet.maximum(:rank, :conditions => ["category_id = ?", self.category_id]).to_i
    end
  end

  def self.dummy_story_set()
    dummy = StorySet.new
    dummy.name = "My Apologies"
    return dummy
  end
end
