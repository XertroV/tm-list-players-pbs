# List Players' PBs

Provides a window showing players' PBs for players in the current server/room.

PBs will refreshed whenever a player leaves/joins the server, or after 60s if nobody has joined/left in that time.

PBs will show up green when they were set within the last minute (and fade to white over that time).

*Live* updates are supported via the *optional dependency* **MLFeed: Race Data**.
If you install that (along with MLHook) then you will see a player's new PB immediately when it is set (without a refresh).

Settings:

* Show when overlay hidden (persistent window); default true
* Lock window when overlay hidden; default true
* Hide top info (refresh button, rank, map name); default false
* Map name in top info; default true
* Show players' club tag; default true
* Show the date the PB was set; default false
* (If MLFeed is installed) Disable checking MLFeed for updates; default false

License: Public Domain

Authors: XertroV

Suggestions/feedback: @XertroV on Openplanet discord

Code/issues: [https://github.com/XertroV/tm-list-players-pbs](https://github.com/XertroV/tm-list-players-pbs)

GL HF
