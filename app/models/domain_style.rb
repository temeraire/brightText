
class DomainStyle < ActiveRecord::Base
  validates :app_alias,
    :presence => true,
    :length => {:minimum => 3, :maximum => 40} unless :app_alias == nil

  validates :group_alias,
    :presence => true,
    :length => {:minimum => 3, :maximum => 40} unless :group_alias == nil

  validates :set_alias,
    :presence =>true,
    :length => {:minimum => 3, :maximum => 40} unless :set_alias == nil

  validates :story_alias,
    :presence =>true,
    :length => {:minimum => 3, :maximum => 40} unless :story_alias == nil

  attr_accessible :domain_id, :style_id, :app_alias, :group_alias, :set_alias, :story_alias, :logo


end
