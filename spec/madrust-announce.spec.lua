package.path = package.path .. ";../madrust-announce.lua"

require("busted")
require("madrust-announce")

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
end)