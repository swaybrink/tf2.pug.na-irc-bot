require './playersLogic.rb'
require './pickingLogic.rb'
require './stateLogic.rb'
require './util.rb'

class Pug
  include Cinch::Plugin
  include PlayersLogic
  include PickingLogic
  include StateLogic
  
  listen_to :part, method: :part
  listen_to :quit, method: :part
  
  match /add (.+)/, method: :add
  match /remove/, method: :remove
  match /list/, method: :list
  match /players/, method: :list
  match /need/, method: :need
  
  match /pick ([^\s]+) ([^\s]+)/, method: :pick
  match /captain/, method: :captain

  def initialize *args
    super
    setup
  end
  
  # variables that do not reset between pugs
  def setup
    @channel = "#tf2.pug.na.beta"
    @picking_delay = 45
    
    @afk_threshold = 60 * 10
    @afk_delay = 45
  
    @players = {}
    @afk = []
    
    @team_count = 2
    @team_colours = ["red", "blue"]
    @team_size = 6
    @team_classes = { "scout" => 2, "soldier" => 2, "demo" => 1, "medic" => 1, "captain" => 1 }
    
    @title_width = 15
    
    start_game
  end
  
  # variables that reset between pugs
  def start_game
    @captains = []
    @teams = []
    
    @state = 0 # 0 = add/remove, 1 = afk check, 2 = delay, 3 = picking
    @pick = 0
  end

  def part m
    list_players if remove_player m.user
  end

  # !add
  def add m, args
    if add_player m.user, args.split(/ /)
      list_players
      attempt_afk # checks if minimum requirements are met
    end
  end

  # !remove
  def remove m
    list_players if remove_player m.user
  end
  
  # !list
  def list m
    list_players
    list_players_detailed
  end
  
  # !need
  def need m
    list_classes_needed
  end
  
  # !pick
  def pick m, arg1, arg2
    pick_player m.user, User(arg1), arg2
  end
  
  # !captain
  def captain m
    list_captain m.user
  end
  
  def colour_start foreground, background = 0
    "\x03#{ foreground.to_s.rjust(2, "0") },#{ background.to_s.rjust(2, "0") }"
  end
  
  def colour_end
    "\x03"
  end
  
  def make_title message
    colour_start(0, 2) + message.rjust(@title_width) + colour_end
  end

  def msg channel = @channel, message
    bot.msg channel, message
  end
  
  def priv user, message
    #bot.notice user, message
  end
end