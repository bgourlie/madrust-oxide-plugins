PLUGIN.Title = "madrust-announce"
PLUGIN.Description = "Broadcast announcements using a subreddit as the source."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  self.Announcement = {}
  print("init madrust-announce")	
  self:AddChatCommand( "announce", self.cmdAnnounce )

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
              title = string.sub(_listing.data.title, 16)
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

function PLUGIN:cmdAnnounce( netuser, cmd, args )
  rust.BroadcastChat( "[ANNOUNCE]", self.Announcement.title )
end