package.path = package.path .. ";../plugins/madrust-announce.lua"

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
    PLUGIN.config = {
      announcement_prefix = "[ANNOUNCEMENT]"
    }
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