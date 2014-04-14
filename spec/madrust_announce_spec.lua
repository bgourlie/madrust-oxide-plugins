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
    PLUGIN.config.announcement_prefix = "[ANNOUNCEMENT]"
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
    PLUGIN.config = { announcement_prefix = "%%][ANN(.)O[.])[}]%UNCE%MENT]" }
    local extracted = PLUGIN:ExtractAnnouncement("%%][ANN(.)O[.])[}]%UNCE%MENT] They don't dance no mo'")
    assert.are.equal("They don't dance no mo'", extracted)
  end)
end)

describe("GetConfig", function() 
  it("should require setting \"subreddit\"", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement_prefix = "[ANNOUNCEMENT]",
        subreddit_admins = {"bgzee"}
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(false, result)
  end)

  it("should require setting \"subreddit_admins\"", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement_prefix = "[ANNOUNCEMENT]",
        subreddit = "madrust"
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(false, result)
  end)

  it("should require at least one subreddit_admin", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        announcer = "[ANNOUNCE]",
        announcement_prefix = "[ANNOUNCEMENT]",
        subreddit = "madrust",
        subreddit_admins = {}
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(false, result)
  end)

  it("should use default value \"[ANNOUNCE]\" for setting \"announcer\" if not specified", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        subreddit = "madrust",
        subreddit_admins = {"bgzee"}
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
        subreddit = "madrust",
        subreddit_admins = {"bgzee"}
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal("[ANNOUNCEMENT]", result.announcement_prefix)
  end)

  it("should convert subreddit_admins to fast lookup table", function() 
    -- Arrange
    PLUGIN.LoadConfigIntoTable = function(self)
      return {
        subreddit = "madrust",
        subreddit_admins = {"bgzee", "brettfavre"}
      }
    end
    
    -- Act
    local result = PLUGIN:InitConfig()

    -- Assert
    assert.are.equal(true, result.subreddit_admins["bgzee"])
    assert.are.equal(true, result.subreddit_admins["brettfavre"])
  end)
end)

describe("RedditUserIsAdmin", function() 
  it("should return true if user is admin", function()
    PLUGIN.config.subreddit_admins = {}
    PLUGIN.config.subreddit_admins["bgzee"] = true
    assert.are.equal(true, PLUGIN:RedditUserIsAdmin("bgzee"))
  end)

  it("should return false if user is admin", function()
    PLUGIN.config.subreddit_admins = {}
    PLUGIN.config.subreddit_admins["bgzee"] = true
    assert.are.equal(false, PLUGIN:RedditUserIsAdmin("johndoe"))
  end)
end)

describe("RetrieveAnnouncement", function() 
  before_each(function() 
    PLUGIN.config.subreddit_admins = {}
    PLUGIN.config.subreddit_admins["bgzee"] = true
    PLUGIN.config.subreddit = "madrust"
    PLUGIN.config.announcement_prefix = "[ANNOUNCEMENT]"
  end)

  it("should work", function()
    -- Arrange
    webrequest = {}
    webrequest.Send = function(requestUrl, callback)
      callback(200, "")
    end
  
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
    
    PLUGIN:RetrieveAnnouncement(function(retAnnounce) 
      announcement = retAnnounce
    end)
    
    print("before assert")
    assert.are.equal(true, announcement.isLoaded)
  end)
end)