require 'steam-condenser'

require 'tf2pug/constants'
require 'tf2pug/database'
require 'tf2pug/model/ftp'

class Server
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :required => true
  
  property :host, String,  :required => true
  property :port, Integer, :default => 27015
  property :pass, String
  property :rcon, String,  :required => true
  
  property :played_at,  DateTime, :index => true
  property :created_at, DateTime
  property :updated_at, DateTime
  
  belongs_to :ftp
  
  def server_obj
    SourceServer.new @host, @port
  end
  
  def start map
    server = server_obj
    info = server.server_info
    
    raise Exception.new("Could not connect.") unless info
    raise Exception.new("Server is full.") unless info['number_of_players'] < Constants.settings['server_full']
    
    server.rcon_connect @rcon
    server.rcon_exec "changelevel #{ map.file }"
    server.rcon_disconnect
  
    return true
  end
  
  # TODO: Colourize scores
  def status 
    begin
      server = server_obj
      info = server.server_info
      
      return "empty" unless info and info['number_of_players'] > 0
    rescue Exception => e
      return e.message
    end
    
    begin
      server.rcon_connect @rcon
      rinfo = Hash[server.rcon_exec("tournament_info").scan(/(\w+): "([^"]*)"/)]
      
      status = case rinfo
        when rinfo.empty?; "Warmup on #{ info['map_name'] } with #{ info['number_of_players'] } players"
        else; "#{ rinfo['Score'] } on #{ info['map_name'] } with #{ rinfo['Timeleft'] } remaining"
      end
    rescue Exception => e
      return e.message
    ensure
      server.rcon_disconnect
    end
    
    return status
  end
  
  def download_demos 
    server = server_obj
    info = server.server_info
    
    raise Exception.new("In use, please wait until the pug has ended") if info['number_of_players'] > Constants.settings['server_full']
    
    ftp.download_demos @name
  end
  
  def connect_info
    "connect #{ @host }:#{ @port }; password #{ @password }"
  end
  
  class << self
    def last_played; self.first(:order => :played_at.asc); end
  end
end
