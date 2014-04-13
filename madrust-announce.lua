PLUGIN.Title = "madrust-announce"
PLUGIN.Description = "Broadcast announcements using a subreddit as the source."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  self.Config = {}
  self.Announcement = {}
  print("init madrust-announce")
  self:LoadConfig()
  self:AddChatCommand( "announce", self.CmdAnnounce )

  print("requesting data from subreddit")

  webrequest.Send ("http://www.reddit.com/r/madrust/.json", 
    function(respCode, response)
      print("subreddit request callback [HTTP " .. respCode .. "]")
      local resp = json.decode(response)
      for _, _listing in pairs(resp.data.children) do
        local title = _listing.data.title
        if string.sub(string.upper(title), 0, 15) == "[ANNOUNCEMENT] " then
          print("announcement is " .. title)
          self.Announcement = { 
              title = string.sub(_listing.data.title, 16),
              id = _listing.data.id,
              created_utc = _listing.data.created_utc
          }
          break
        end
      end
    end
  )

  print("subreddit request sent")
 end
 
function PLUGIN:OnUserConnect( netuser )
  rust.SendChatToUser( netuser, "[ANNOUNCE]", "Brian is the bomb.com" )
end

function PLUGIN:CmdAnnounce( netuser, cmd, args )
  rust.BroadcastChat( "[ANNOUNCE]", self.Announcement.title )
end

function PLUGIN:LoadConfig()
  print("Loading madrust-announce config.")
  local _file = util.GetDatafile( "cfg_madrust_announce" )
  local _txt = _file:GetText()
  print("config text: " .. _txt)
  local _conf = json.decode( _txt )

  if (not(_conf)) then
    print ("Configuration is missing or malformed.")
    return false
  end

  self.Config = _conf.conf
  print("subbreddit is " .. self.Config.subreddit)
end
