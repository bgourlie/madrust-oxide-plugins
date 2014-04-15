madrust-oxide-plugins
=====================

### madrust-announce [![Build Status](https://travis-ci.org/bgourlie/madrust-oxide-plugins.svg?branch=master)](https://travis-ci.org/bgourlie/madrust-oxide-plugins)

madrust-announce is an oxide plugin that will display a configurable message whenever a user enters the game.  

The most notable feature is the ability to extract announcements from a specified subreddit.

The following is a sample configuration for madrust-announce:

    {
      "conf" : 
      {
        "announcer" : "[ANNOUNCE]",
        "msg_no_announcements" : "There are no recent announcements.",
        "subreddit" : 
        {
          "name" : "madrust",
          "admins" : ["bgzee"],
		  "announcement_prefix" : "[ANNOUNCEMENT]",
          "check_interval" : 3600
        }        
      }
    }

