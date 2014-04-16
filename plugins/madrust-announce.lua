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

  if self:AnnouncementHasSubredditDependency(self.config.announcement) then
    local checkfn = function()
        self:RetrieveSubredditAnnouncement(function(announcement) 
          if self.subredditAnnouncement ~= announcement then
            self.subredditAnnouncement = announcement
            for _, line in pairs(self:GetInterpolatedAnnouncement()) do
              rust.BroadcastChat(self.config.announcer, line)
            end
          end
        end)
    end

    -- initial check
    checkfn()

    -- continue check every n seconds, where n = config.check_interval
    self.checkTimer = timer.Repeat(self.config.subreddit.check_interval, checkfn)
  end
 end

function PLUGIN:Unload()
  if self.checkTimer then self.checkTimer:Destroy() end
end

function PLUGIN:OnUserConnect(netuser)
  self:CmdAnnounce(netuser)
end

function PLUGIN:CmdAnnounce(netuser, cmd, args)
  for _, line in pairs(self:GetInterpolatedAnnouncement()) do
    rust.SendChatToUser(netuser, self.config.announcer, line)
  end
end

function PLUGIN:GetInterpolatedAnnouncement()
  local interpolated = {}
  for index, line in pairs(self.config.announcement) do
    interpolated[index] = line:gsub("%%subredditAnnouncement%%", self.subredditAnnouncement)
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
