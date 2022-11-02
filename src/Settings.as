[Setting hidden]
bool S_ShowWindow = true;

[Setting category="PB List" name="Show when Overlay Hidden" description="Whether to show the window regardless of if the Openplanet overlay is hidden or not."]
bool S_ShowWhenUIHidden = true;

[Setting category="PB List" name="Lock Window when Overlay Hidden" description="No effect unless 'Show when Overlay Hidden' is checked."]
bool S_LockWhenUIHidden = true;

[Setting category="PB List" name="Show Title Bar when Unlocked?" description="When the overlay is shown and/or the window isn't locked, it will have a title bar with a little (X) to close it."]
bool S_TitleBarWhenUnlocked = true;

[Setting category="PB List" name="Hide Window in Solo Play" description="When checked, the window will only show in multiplayer servers, not local games."]
bool S_HideInSoloMode = true;

[Setting category="PB List" name="Hide Top Info?" description="The top info (showing refresh btn, #Players, and your rank) will be hidden if this is checked."]
bool S_HideTopInfo = false;

[Setting category="PB List" name="Map Name in Top Info?" description="Show the map name in the top info."]
bool S_TopInfoMapName = true;

[Setting category="PB List" name="Show Clubs?" description="Will show club tags in the list. Club tags have a slight performance impact."]
bool S_ShowClubs = true;

[Setting category="PB List" name="Show Dates?" description="Will show the date the PB was set"]
bool S_ShowDates = false;

// don't expose via settings -- not sure it's that useful and mucks up formatting.
// [Setting category="PB List" name="Show Replay Download Button?" description="Will show a button to download a player's PB ghost/replay"]
const bool S_ShowReplayBtn = false;

[Setting category="PB List" name="Highlight Recent PBs?" description="Will highlight PBs set within the last 60s."]
bool S_ShowRecentPBsInGreen = true;

#if DEPENDENCY_MLFEEDRACEDATA
[Setting category="PB List" name="Disable Live Updates via MLFeed?" description="Disable this to skip checking current race data for better times."]
#endif
bool S_SkipMLFeedCheck = false;

[Setting category="PB List" name="Hotkey Active?" description="The hotkey will only work when this is checked."]
bool S_HotkeyEnabled = false;

[Setting category="PB List" name="Show/Hide Hotkey" description="The hotkey to toggle the list of PBs window."]
VirtualKey S_Hotkey = VirtualKey::F4;
