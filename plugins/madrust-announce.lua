PLUGIN = PLUGIN or {} -- accommodates testing

PLUGIN.Title = "madrust-announce"
PLUGIN.Description = "Announcment broadcaster with optional reddit integration."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  print("init madrust-announce")
  self.config = self:InitConfig()
  self.subredditAnnouncement = nil

  self:AddChatCommand("announce", self.CmdAnnounce)
  self:AddChatCommand("a", self.CmdAnnounce)
  self:AddChatCommand("compass", self.CmdCompass)
  self:AddChatCommand("c", self.CmdCompass)
  self:AddChatCommand("list", self.CmdList)
  self:AddChatCommand("l", self.CmdList)
  self:AddChatCommand("whisper", self.CmdWhisper)
  self:AddChatCommand("w", self.CmdWhisper)
  self:AddChatCommand("help", self.CmdHelp)
  self:AddChatCommand("h", self.CmdHelp)

  if self:AnnouncementHasSubredditDependency(self.config.announcement) then
    local checkfn = function()
        self:RetrieveSubredditAnnouncement(function(announcement) 
          if self.subredditAnnouncement ~= announcement then
            self.subredditAnnouncement = announcement
          end
        end)
    end

    -- initial check
    checkfn()

    -- continue check every n seconds, where n = config.check_interval
    self.checkTimer = timer.Repeat(self.config.subreddit.check_interval, checkfn)
  end
 end

function PLUGIN:AnnounceToUser(netuser, text)
  rust.SendChatToUser(netuser, self.config.announcer, "[color #66FF00]" .. text)
end

function PLUGIN:AnnounceBroadcast(text)
  rust.BroadcastChat(self.config.announcer, "[color #66FF00]" .. text)
end

function PLUGIN:CmdCompass(netuser, cmd, args)
  -- most of this taken from an oxide example at http://wiki.rustoxide.com/Snippets
  local controllable = netuser.playerClient.controllable
  local char = controllable:GetComponent( "Character" )

  local forward = char.forward -- This should be a forward vector.
  local pitch = char.eyesPitch -- You can use angles if you'd prefer
  local yaw = char.eyesYaw -- You can use angles if you'd prefer

  -- Convert unit circle angle to compass angle.
  -- Known error: char.eyesYaw randomly returns a String value and breaks output
  local degrees = (yaw+90)%360

  local direction = self:GetDirectionString(degrees)

  self:AnnounceToUser(netuser, "You are facing " .. direction)
end

function PLUGIN:GetDirectionString(degrees)
  -- see http://en.wikipedia.org/wiki/Points_of_the_compass
  if (degrees >= 354.38 and degrees <= 360) or degrees <= 5.62 then return "north [N]" end
  if degrees >= 5.63 and degrees <= 16.87 then return "north by east [NbE]" end
  if degrees >= 16.88 and degrees <= 28.12 then return "north-northeast [NNE]" end
  if degrees >= 28.13 and degrees <= 39.37 then return "northeast by north [NEbN]" end
  if degrees >= 39.38 and degrees <= 39.37 then return "northeast [NE]" end 
  if degrees >= 50.63 and degrees <= 61.87 then return "northeast by east [NEbE]" end
  if degrees >= 61.88 and degrees <= 73.12 then return "east-northeast [ENE]" end
  if degrees >= 73.13 and degrees <= 84.37 then return "east by north [EbN]" end
  if degrees >= 84.38 and degrees <= 95.62 then return "east [E]" end
  if degrees >= 95.63 and degrees <= 106.87 then return "east by south [EbS]" end 
  if degrees >= 106.88 and degrees <= 118.12 then return "east-southeast [ESE]" end
  if degrees >= 118.13 and degrees <= 129.37 then return "southeast by east [SEbE]" end
  if degrees >= 129.38 and degrees <= 140.62 then return "southeast [SE]" end
  if degrees >= 140.63 and degrees <= 151.87 then return "southeast by south [SEbS]" end
  if degrees >= 151.88 and degrees <= 163.12 then return "south-southeast [SSE]" end
  if degrees >= 163.13 and degrees <= 174.37 then return "south by east [SbE]" end
  if degrees >= 174.38 and degrees <= 185.62 then return "south [S]" end 
  if degrees >= 185.63 and degrees <= 196.87 then return "south by west [SbW]" end 
  if degrees >= 196.88 and degrees <= 208.12 then return "south-southwest [SSW]" end
  if degrees >= 208.13 and degrees <= 219.37 then return "southwest by south [SWbS]" end
  if degrees >= 219.38 and degrees <= 230.62 then return "southwest [SW]" end 
  if degrees >= 230.63 and degrees <= 241.87 then return "southwest by west [SWbW]" end
  if degrees >= 241.88 and degrees <= 253.12 then return "west-southwest [WSW]" end
  if degrees >= 253.13 and degrees <= 264.37 then return "west by south [WbS]" end
  if degrees >= 264.38 and degrees <= 275.62 then return "west [W]" end
  if degrees >= 275.63 and degrees <= 286.87 then return "west by north [WbN]" end
  if degrees >= 286.88 and degrees <= 298.12 then return "west-northwest [WNW]" end
  if degrees >= 298.13 and degrees <= 309.37 then return "northwest by west [NWbW]" end
  if degrees >= 309.38 and degrees <= 320.62 then return "northwest [NW]" end
  if degrees >= 320.63 and degrees <= 331.87 then return "northwest by north [NWbN]" end
  if degrees >= 331.88 and degrees <= 343.12 then return "north-northwest [NNW]" end
  if degrees >= 343.13 and degrees <= 354.37 then return "north by west [NbW]" end

  return "[Unable to determine direction]"
end

function PLUGIN:GetUserTable()
  return rust.GetAllNetUsers()
end

function PLUGIN:GetUsersStartingWith(user)
  local len = user:len()
  local i = 1
  local matches = {}
  for _,u in pairs(self:GetUserTable()) do
    if u.displayName:lower():sub(1, len) == user:lower() then 
      matches[i] = u
      i = i + 1
    end
  end
  return matches;
end

function PLUGIN:GetUserCount()
  local count = 0;
  for _,__ in pairs(self:GetUserTable()) do
    count = count + 1
  end
  return count;
end

function PLUGIN:CmdWhisper(netuser, cmd, args)
  local targetUser = args[1]
  if not targetUser or not args[2] then return end
  local message = ""

  for i, str in pairs(args) do
    if i > 1 then
      message = message .. str .. " "
    end
  end

  local users = self:GetUsersStartingWith(targetUser)
  local userCount = self:GetTableCount(users)
  if userCount == 0 then 
    self:AnnounceToUser(netuser, string.format("No user with a name like %q is logged on.", targetUser))
    return 
  end

  if userCount > 1 then 
    self:AnnounceToUser(netuser, string.format("More than one user has a name like %q.", targetUser))
    return 
  end
  
  rust.SendChatToUser(users[1], netuser.displayName .. " (whisper)", message)
  rust.SendChatToUser(netuser, netuser.displayName .. string.format(" (to %s)", users[1].displayName), message)
end

function PLUGIN:CmdList(netuser, cmd, args)
  for _, user in pairs(self:GetUserTable()) do
    self:AnnounceToUser(netuser, user.displayName)
  end
end

function PLUGIN:CmdHelp(netuser, cmd, args)
  self:AnnounceToUser(netuser, "/announce or /a - Repeat the announcement message.")
  self:AnnounceToUser(netuser, "/list or /l - See who's online.")
  self:AnnounceToUser(netuser, "/compass or /c - See which direction you're facing.")
  self:AnnounceToUser(netuser, "/whisper or /w [user] [message] - Send a message to a user that only they can see.")
end

function PLUGIN:Unload()
  if self.checkTimer then self.checkTimer:Destroy() end
end

function PLUGIN:OnUserConnect(netuser)
  self:CmdAnnounce(netuser)
  self:AnnounceBroadcast(netuser.displayName .. " has joined the game.")
end

function PLUGIN:OnUserDisconnect(networkplayer)
    local netuser = networkplayer:GetLocalData()
    if (not netuser or netuser:GetType().Name ~= "NetUser") then
      return
    end
    self:AnnounceBroadcast(netuser.displayName .. " has left the game.")
end

function PLUGIN:CmdAnnounce(netuser, cmd, args)
  for _, line in pairs(self:GetInterpolatedAnnouncement()) do
    self:AnnounceToUser(netuser, line)
  end
end

function PLUGIN:GetInterpolatedAnnouncement()
  local interpolated = {}
  for index, line in pairs(self.config.announcement) do
    interpolated[index] = line:gsub("%%subredditAnnouncement%%", self.subredditAnnouncement)
    interpolated[index] = interpolated[index]:gsub("%%userCount%%", tostring(self:GetUserCount()))
  end
  return interpolated
end

function PLUGIN:RedditUserIsAdmin(redditUser)
  return self.config.subreddit.admins[redditUser] == true
end

-- TODO: move to some sort of util api
function PLUGIN:EscapePatternChars(text)
  return string.gsub(text, "(.)",
    function(c)
      if string.match(c, "[%[%]%(%)%.%%]") then return "%" .. c end
    end)
end

function PLUGIN:ExtractAnnouncement(linkTitle)
  local prefixPattern = "^" .. self:EscapePatternChars(self.config.subreddit.announcement_prefix) .. "%s*(.+)"
  return string.match(linkTitle, prefixPattern)
end

function PLUGIN:RetrieveSubredditAnnouncement(callback)
  print(string.format("requesting subreddit data from %q", self.config.subreddit.name))
  local requestUrl = string.format("http://www.reddit.com/r/%s/.json", self.config.subreddit.name)
  
  webrequest.Send (requestUrl, 
    function(respCode, response)
      print(string.format("received subreddit response [HTTP %d]", respCode))
      local listings = self:LoadListingsIntoTable(response)
      local announcementFound = false
      for _, listing in pairs(listings) do
        local announcement = self:ExtractAnnouncement(listing.title)
        if announcement and self:RedditUserIsAdmin(listing.author) then
          announcementFound = true
          callback(announcement)
          break
        end
      end

      if not(announcementFound) then
        callback(self.config.msg_no_announcements)
      end
    end)
end

function PLUGIN:InitConfig()
  local conf = self:LoadConfigIntoTable()  
  
  -- verify required settings exist
  if not conf.announcement then
    error("Configuration is missing for required setting \"announcement\"")
  end

  if type(conf.announcement) ~= "table" then
    error("announcement must be an array.")
  end

  local hasSubredditDependency = self:AnnouncementHasSubredditDependency(conf.announcement)

  if hasSubredditDependency then
    -- some of the subreddit fields are required if interpolating reddit data
    if not conf.subreddit then
      error("Configuration is missing required setting \"subreddit\"")
    end

    if not conf.subreddit.name then
      error("Configuration is missing required setting \"subreddit.name\"")
    end

    if not conf.subreddit.admins then
      error("Configuration is missing required setting \"subreddit.admins\"")
    end

    -- apply default settings for reddit specific settings if not specified
    if not conf.subreddit.announcement_prefix then conf.subreddit.announcement_prefix = "[ANNOUNCEMENT]" end
    if not conf.subreddit.check_interval then conf.subreddit.check_interval = 3600 end
  end

  -- apply default settings for general settings if not specified
  if not conf.announcer then conf.announcer = "[ANNOUNCE]" end
  if not conf.msg_no_announcements then conf.msg_no_announcements = "There are no recent announcements." end

  -- makes sure we have expected types
  if type(conf.announcer) ~= "string" then
    error("\"announcer\" must be a string")
  end

  if type(conf.msg_no_announcements) ~= "string" then
    error("\"msg_no_announcements\" must be a string")
  end

  local config =  
  {
    announcer = conf.announcer,
    announcement = conf.announcement,
    msg_no_announcements = conf.msg_no_announcements
  }

  if hasSubredditDependency then
    if type(conf.subreddit.announcement_prefix) ~= "string" then
      error("\"subreddit.announcement_prefix\" must be a string")
    end

    if type(conf.subreddit.check_interval) ~= "number" then
      error("\"subreddit.check_interval\" must be a number")
    end

    if type(conf.subreddit.name) ~= "string" then
      error("\"subreddit.name\" must be a string")
    end

    if type(conf.subreddit.admins) ~= "table" then
      error("\"subreddit.admins\" must be an array")
    end
    -- hacky way to determine if at least admin has been specified
    local adminSpecified = false
    for i, admin in pairs(conf.subreddit.admins) do
      adminSpecified = true
      break
    end
    
    if not adminSpecified then
      error("You must specify at least one subreddit admin.")
      return false
    end

    local subreddit_admins = {}
    -- convert the table such that the names are keys for fast lookup
    for _, admin in pairs(conf.subreddit.admins) do
      subreddit_admins[admin] = true
    end

    config.subreddit = 
    {
      name = conf.subreddit.name,
      check_interval = conf.subreddit.check_interval,
      announcement_prefix = conf.subreddit.announcement_prefix,
      admins = subreddit_admins
    }
  end 

  return config
end

-- Parse the subbredit json, massage it into saner model
function PLUGIN:LoadListingsIntoTable(listingsJson)
  local resp = json.decode(listingsJson)
  local listings = {}
  for index, listing in pairs(resp.data.children) do
    listings[index] = 
    {
      author = listing.data.author,
      title = listing.data.title,
      created_utc = listing.data.created_utc,
      id = listing.data.id
    }
  end

  return listings
end 

function PLUGIN:AnnouncementHasSubredditDependency(announcement)
  for _, line in pairs(announcement) do
    if line:match("%%subredditAnnouncement%%") then return true end
  end 
  return false
end

-- TODO: move to some sort of util api
function PLUGIN:LoadConfigIntoTable()
  local _file = util.GetDatafile( "cfg_madrust_announce" )
  local _txt = _file:GetText()
  local _conf = json.decode(_txt)

  if not _conf or not _conf.conf then
    error("Configuration is missing or malformed.")
  end
  
  return _conf.conf  
end

function PLUGIN:GetTableCount(table)
  if type(table) ~= "table" then return 0 end
  local count = 0
  for _,__ in pairs(table) do
    count = count + 1
  end
  return count
end