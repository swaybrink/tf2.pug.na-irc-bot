require_relative '../database'

require_relative 'match'
require_relative 'team'
require_relative 'pick'

class Matchup
  include DataMapper::Resource
  
  belongs_to :match, :key => true
  belongs_to :team,  :key => true
  
  property :home, Boolean
  
  has n, :picks
  
  validates_uniqueness_of :home, :scope => :match
end