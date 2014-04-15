PLUGIN = PLUGIN or {} -- accommodates testing

PLUGIN.Title = "madrust-announce"
PLUGIN.Description = "Broadcast announcements using a subreddit as the source."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  print("init madrust-announce")
  self.config = self:InitConfig()
  self.isLoading = true
  self.announcement = nil

  self:AddChatCommand("announce", self.CmdAnnounce)
  self:RetrieveAnnouncement(
    function(announcement) 
      self.announcement = announcement
      rust.BroadcastChat(self.config.announcer, self.announcement)
    end)
 end

function PLUGIN:OnUserConnect(netuser)
  self:CmdAnnounce(netuser)
end

function PLUGIN:CmdAnnounce(netuser, cmd, args)
  if not self.isLoading then return end
  rust.SendChatToUser(netuser, self.config.announcer, self.announcement)
end

function PLUGIN:RedditUserIsAdmin(redditUser)
  return self.config.subreddit_admins[redditUser] == true
end

-- TODO: move to some sort of util api
function PLUGIN:EscapePatternChars(text)
  return string.gsub(text, "(.)",
    function(c)
      if string.match(c, "[%[%]%(%)%.%%]") then return "%" .. c end
    end)
end

function PLUGIN:ExtractAnnouncement(linkTitle)
  local prefixPattern = "^" .. self:EscapePatternChars(self.config.announcement_prefix) .. "%s*(.+)"
  return string.match(linkTitle, prefixPattern)
end

function PLUGIN:RetrieveAnnouncement(callback)
  print(string.format("requesting subreddit data from %q", self.config.subreddit))
  local requestUrl = string.format("http://www.reddit.com/r/%s/.json", self.config.subreddit)
  
  webrequest.Send (requestUrl, 
    function(respCode, response)
      print(string.format("received subreddit response [HTTP %d]", respCode))
      local listings = self:LoadListingsIntoTable(response)
      local announcementFound = false
      for _, listing in pairs(listings) do
        local announcement = self:ExtractAnnouncement(listing.title)
        if announcement and self:RedditUserIsAdmin(listing.author) then
          announcementFound = true
          print("announcement is " .. announcement)
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
  if not(conf.subreddit) then
    print ("Configuration is missing required setting \"subreddit\"")
    return false
  end

  if not(conf.subreddit_admins) then
    print ("Configuration is missing required setting \"subreddit_admins\"")
    return false
  end

  -- hacky way to determine if at least admin has been specified
  local adminSpecified = false
  for i, admin in pairs(conf.subreddit_admins) do
    adminSpecified = true
    break
  end
  
  if not(adminSpecified) then
    print ("You must specify at least one subreddit admin.")
    return false
  end

  -- apply default settings for certain settings if not specified
  if not(conf.announcer) then conf.announcer = "[ANNOUNCE]" end
  if not(conf.announcement_prefix) then conf.announcement_prefix = "[ANNOUNCEMENT]" end
  if not(conf.msg_no_announcements) then conf.msg_no_announcements = "There are no recent announcements." end
  local subreddit_admins = {}

  -- convert the table such that the names are keys for fast lookup
  for _, admin in pairs(conf.subreddit_admins) do
    subreddit_admins[admin] = true
  end
  
  return 
  {
    announcer = conf.announcer,
    announcement_prefix = conf.announcement_prefix,
    msg_no_announcements = conf.msg_no_announcements,
    subreddit = conf.subreddit,
    subreddit_admins = subreddit_admins
  }
end

-- Parse the subbredit json, massage it into saner model
function PLUGIN:LoadListingsIntoTable(listingsJson)
  local resp = json.decode(listingsJson)
  local listings = {}
  for index, listing in pairs(resp.data.children) do
    print("index is " .. index)
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

-- TODO: move to some sort of util api
function PLUGIN:LoadConfigIntoTable()
  local _file = util.GetDatafile( "cfg_madrust_announce" )
  local _txt = _file:GetText()
  local _conf = json.decode(_txt)

  if not(_conf) or not(_conf.conf) then
    print ("Configuration is missing or malformed.")
    return false
  end
  
  return _conf.conf  
end
