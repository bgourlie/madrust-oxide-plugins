package.path = package.path .. ";plugins/madrust-announce.lua"

require("busted")
require("madrust-announce")

before_each(function() 
  PLUGIN.config = {}
end)

describe("EscapePatternChars", function()
  it("should escape open brackets", function()
    local escaped = PLUGIN:EscapePatternChars("foo[bar")
    assert.are.equal("foo%[bar", escaped)
  end)

  it("should escape closing brackets", function()
    local escaped = PLUGIN:EscapePatternChars("foo]bar")
    assert.are.equal("foo%]bar", escaped)
  end)

  it("should escape percent sign", function()
    local escaped = PLUGIN:EscapePatternChars("foo%bar")
    assert.are.equal("foo%%bar", escaped)
  end)

  it("should escape open paren", function()
    local escaped = PLUGIN:EscapePatternChars("foo(bar")
    assert.are.equal("foo%(bar", escaped)
  end)

  it("should escape close paren", function()
    local escaped = PLUGIN:EscapePatternChars("foo)bar")
    assert.are.equal("foo%)bar", escaped)
  end)
 
  it("should escape dot", function()
    local escaped = PLUGIN:EscapePatternChars("foo.bar")
    assert.are.equal("foo%.bar", escaped)
  end)

  it("should escape multiple special characters", function()
    local escaped = PLUGIN:EscapePatternChars("foo%b[a]r")
    assert.are.equal("foo%%b%[a%]r", escaped)
  end)
end)

describe("ExtractAnnouncement", function()
  before_each(function() 
    PLUGIN.config.subreddit = {}
    PLUGIN.config.subreddit.announcement_prefix = "[ANNOUNCEMENT]"
  end)

  it("shouldn't extract whitespace after prefix", function()
    local extracted = PLUGIN:ExtractAnnouncement("[ANNOUNCEMENT]  They don't dance no mo'")
    assert.are.equal("They don't dance no mo'", extracted)
  end)

  it("shouldn't require whitespace after prefix", function()
    local extracted = PLUGIN:ExtractAnnouncement("[ANNOUNCEMENT]They don't dance no mo'")
    assert.are.equal("They don't dance no mo'", extracted)
  end)

  it("should handle wierd characters smoke test", function()
    PLUGIN.config.subreddit = {}
    PLUGIN.config.subreddit.announcement_prefix = "%%][ANN(.)O[.])[}]%UNCE%MENT]" 
    local extracted = PLUGIN:ExtractAnnouncement("%%][ANN(.)O[.])[}]%UNCE%MENT] They don't dance no mo'")
    assert.are.equal("They don't dance no mo'", extracted)
  end)
end)

describe("GetConfig", function() 
  it("should require setting \"subreddit\" if interpolating subreddit data", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"%subredditAnnouncement%"}
      }
    end

    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "Configuration is missing required setting \"subreddit\"")
  end)

  it("shouldn't require setting \"subreddit\" if not interpolating subreddit data", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"static announcement"}
      }
    end

    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_no.errors(errfn)
  end)

  it("should require setting \"subreddit.name\" if interpolating subreddit data", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          admins = {"bgzee"},
          check_interval = 3600
        }
      }
    end

    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "Configuration is missing required setting \"subreddit.name\"")
  end)

  it("should require setting \"subreddit.admins\" if interpolating subreddit data", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = "madrust"
        }
      }
    end
    
    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "Configuration is missing required setting \"subreddit.admins\"")
  end)

    it("should fail if \"subreddit.admins\" isn't a table", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = "madrust",
          admins = "not a table!"
        }
      }
    end
    
    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "\"subreddit.admins\" must be an array")
  end)

  it("should fail if \"subreddit.name\" isn't a string", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = 3243,
          admins = {"bgzee"},
        }
      }
    end
    
    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "\"subreddit.name\" must be a string")
  end)

  it("should fail if \"subreddit.announcement_prefix\" isn't a string", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = 234,
          name = "madrust",
          admins = {"bgzee"}
        }
      }
    end
    
    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "\"subreddit.announcement_prefix\" must be a string")
  end)

  it("should fail if \"announcer\" isn't a string", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = 343,
        announcement = {"some announcement"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = "madrust",
          admins = {"bgzee"}
        }
      }
    end
    
    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "\"announcer\" must be a string")
  end)

  it("should fail if \"msg_no_announcements\" isn't a string", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"some announcement"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = "madrust",
          admins = {"bgzee"},
        },
        msg_no_announcements = 2343
      }
    end

    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "\"msg_no_announcements\" must be a string")
  end)

  it("should require at least one subreddit_admin if interpolating subreddit data", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          announcement_prefix = "[ANNOUNCEMENT]",
          name = "madrust",
          admins = {}
        }
      }
    end

    local errfn = function()
      PLUGIN:InitConfig()
    end

    -- Assert
    assert.has_error(errfn, "You must specify at least one subreddit admin.")
  end)

  it("should use default value \"[ANNOUNCE]\" for setting \"announcer\" if not specified", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"some announcement"}
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal("[ANNOUNCE]", result.announcer)
  end)

  it("should use default value \"[ANNOUNCEMENT]\" for setting \"announcement_prefix\" if not specified", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          name = "madrust",
          admins = {"bgzee"}
        }
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal("[ANNOUNCEMENT]", result.subreddit.announcement_prefix)
  end)

  it("should use default value \"There are no recent announcements.\" for setting \"msg_no_announcements\" if not specified", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"some announcement"},
        subreddit = {
          name = "madrust",
          admins = {"bgzee"}
        }
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal("There are no recent announcements.", result.msg_no_announcements)
  end)

    it("should use default value 3600 for setting \"subreddit.check_interval\" if not specified", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
        name = "madrust",
        admins = {"bgzee"}
      }
    }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(3600, result.subreddit.check_interval)
  end)

  it("should convert subreddit_admins to fast lookup table", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcement = {"%subredditAnnouncement%"},
        subreddit = {
          name = "madrust",
          admins = {"bgzee", "brettfavre"}
        }
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(true, result.subreddit.admins["bgzee"])
    assert.are.equal(true, result.subreddit.admins["brettfavre"])
  end)
end)

describe("RedditUserIsAdmin", function() 
  it("should return true if user is admin", function()
    PLUGIN.config.subreddit = {}
    PLUGIN.config.subreddit.admins = {}
    PLUGIN.config.subreddit.admins["bgzee"] = true
    assert.are.equal(true, PLUGIN:RedditUserIsAdmin("bgzee"))
  end)

  it("should return false if user is admin", function()
    PLUGIN.config.subreddit = {}
    PLUGIN.config.subreddit.admins = {}
    PLUGIN.config.subreddit.admins["bgzee"] = true
    assert.are.equal(false, PLUGIN:RedditUserIsAdmin("johndoe"))
  end)
end)

describe("RetrieveSubredditAnnouncement", function() 
  before_each(function() 
    PLUGIN.config.subreddit = {}
    PLUGIN.config.subreddit.admins = {}
    PLUGIN.config.subreddit.admins["bgzee"] = true
    PLUGIN.config.subreddit.name = "madrust"
    PLUGIN.config.subreddit.announcement_prefix = "[ANNOUNCEMENT]"
    PLUGIN.config.msg_no_announcements = "There ain't no announcements!"

    webrequest = {}
    webrequest.Send = function(requestUrl, callback)
      callback(200, "")
    end
  end)

  it("should retrieve annoucement if author is admin", function()
    -- Arrange 
    PLUGIN.LoadListingsIntoTable = function(self, json)
      local ret = {}
      ret[0] = {
        title = "[ANNOUNCEMENT] Hello there earthlings!",
        author = "bgzee",
        created_utc = 1397488776.0 
      }

      return ret
    end
    local announcement = {}
    
    PLUGIN:RetrieveSubredditAnnouncement(function(retAnnounce) 
      announcement = retAnnounce
    end)
    
    assert.are.equal("Hello there earthlings!", announcement)
  end)

  it("should not retrieve announcement if author is not admin", function()
    -- Arrange 
    PLUGIN.LoadListingsIntoTable = function(self, json)
      local ret = {}
      ret[1] = {
        title = "[ANNOUNCEMENT] Hello there earthlings!",
        author = "george",
        created_utc = 1397488776.0 
      }

      return ret
    end
    local announcement = {}
    
    PLUGIN:RetrieveSubredditAnnouncement(function(retAnnounce) 
      announcement = retAnnounce
    end)
    
    assert.are.equal(PLUGIN.config.msg_no_announcements, announcement)
  end)
end)

describe("AnnouncementHasSubredditDependency", function() 
  it("should return true if any lines contain '%subredditAnnouncement%'", function()

    assert.are.equal(true, PLUGIN:AnnouncementHasSubredditDependency({"Announcement line 1", "%subredditAnnouncement% line 2"}))
    end)

  it("should return false if no lines contain '%subredditAnnouncement%'", function()
    assert.are.equal(false, PLUGIN:AnnouncementHasSubredditDependency({"Announcement line 1", "Announcement line 2"}))
    end)
end)

describe("PLUGIN:GetInterpolatedAnnouncement", function() 
  it("should interpolate the subreddit announcement ", function()
    PLUGIN.subredditAnnouncement = "This is the announcement!"
    PLUGIN.config.announcement = { "%subredditAnnouncement%" }
    PLUGIN.GetUserCount = function(self) return 4 end
    local interpolated = PLUGIN:GetInterpolatedAnnouncement()
    assert.are.equal("This is the announcement!", interpolated[1])
    end)

  it("should interpolate the user count ", function()
    PLUGIN.subredditAnnouncement = "This is the announcement!"
    PLUGIN.config.announcement = { "There are %userCount% online." }
    PLUGIN.GetUserCount = function(self) return 4 end
    local interpolated = PLUGIN:GetInterpolatedAnnouncement()
    assert.are.equal("There are 4 online.", interpolated[1])
  end)
end)

describe("GetUsersStartingWith", function()
  it("should return an exact match", function()
    PLUGIN.GetUserTable = function(self)
      local ret = {}
      ret[1] = {}
      ret[1].displayName = "bgzee"
      return ret
    end

    local result = PLUGIN:GetUsersStartingWith("bgzee")
    assert.are.equal("bgzee", result[1].displayName)
  end)

  it("should return even if case doesn't match", function()
    PLUGIN.GetUserTable = function(self)
      local ret = {}
      ret[1] = {}
      ret[1].displayName = "bgzEE"
      return ret
    end

    local result = PLUGIN:GetUsersStartingWith("bgzee")
    assert.are.equal("bgzEE", result[1].displayName)
  end)

  it("should all possible matches", function()
    PLUGIN.GetUserTable = function(self)
      local ret = {}
      ret[1] = {}
      ret[1].displayName = "bgzEE"

      ret[2] = {}
      ret[2].displayName = "bgzEEfosheezy"

      ret[3] = {}
      ret[3].displayName = "george"
      return ret
    end

    local result = PLUGIN:GetUsersStartingWith("bgzee")
    assert.are.equal("bgzEE", result[1].displayName)
    assert.are.equal("bgzEEfosheezy", result[2].displayName)
  end)
end)

describe("GetTableCount", function()
  it("smoke test", function()
    local table = { "one", "two", "three" }
    local result = PLUGIN:GetTableCount(table)
    assert.are.equal(3, result)
  end)
end)