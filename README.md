## madrust-announce [![Build Status](https://travis-ci.org/bgourlie/madrust-oxide-plugins.svg?branch=master)](https://travis-ci.org/bgourlie/madrust-oxide-plugins)

madrust-announce is an oxide plugin that will display a configurable message whenever a user enters the game.  The most notable feature is the ability to extract announcements from a specified subreddit.

### Configuration

The following is a sample configuration, which should reside in `oxide/data/cfg_madrust_announce.txt`:

    {
      "conf" : 
      {
        "announcement" : 
        [
          "%subredditAnnouncement%", 
          "Subscribe to the official server subreddit @ www.reddit.com/r/madrust", 
          "There are %userCount% users online.  Type '/help' for available commands."
        ],
        "subreddit" : 
        {
          "name" : "madrust",
          "admins" : ["bgzee"],
          "check_interval" : 3600
        }        
      }
    }

#### Required Settings

- **announcement**: An array of lines that are displayed whenever a user connects.  The following variables can be used:
  - `%subredditAnnouncement%` - Displays the most recent announcement from the configured subreddit.
  - `%userCount%` - Displays the number of connected users.
- **subreddit**: This section is used for pulling in the most recent announcement from a subreddit.  It's only required if using the `%subredditAnnouncement%` variable.
  - **name**: The name of the subreddit.  If the url for your subreddit is `www.reddit.com/r/ilikecake`, then the name of your subreddit is `ilikecake`.
  - **admins**:  The users whose posts will be considered for announcements.  These users do not actually have to be admins of the subreddit.
  - **announcement_prefix**:  The text that announcements are prefixed with when posted to the subreddit.
  - **check_interval**: The number of seconds to wait before checking if any new announcements have been posted to the subreddit.
  
## madrust-stats

### Sample Configuration
    {
	  "DbName" : "madrust-stats",
	  "DbUser" : "someuser",
	  "DbPassword" : "asdf1234",
	  "HttpPort" : 8787
    }