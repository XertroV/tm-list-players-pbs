void Main() {
    if (!PermissionsOkay) {
        NotifyMissingPermissions();
        return;
    }
    startnew(MainLoop);
}

bool get_PermissionsOkay() {
    return Permissions::ViewRecords()
        // && Permissions::PlayRecords() // don't think this is required, just viewing
        ;
}

void NotifyMissingPermissions() {
    UI::ShowNotification(Meta::ExecutingPlugin().Name,
        "Missing permissions! D:\nYou probably don't have permission to view records/PBs.\nThis plugin won't do anything.",
        vec4(1, .4, .1, .3),
        10000
        );
}

void MainLoop() {
    // when current playground becomes not-null, get records
    // when player count changes, get records
    // when playground goes null, reset
    while (PermissionsOkay) {
        yield();
        if (GetApp().CurrentPlayground !is null) {
            startnew(UpdateRecords);
            while (GetApp().CurrentPlayground !is null) {
                yield();
                if (g_PlayersInServerLast != GetPlayersInServerCount()) {
                    g_PlayersInServerLast = GetPlayersInServerCount();
                    startnew(UpdateRecords);
                }
            }
            g_Records.RemoveRange(0, g_Records.Length);
        }
        while (GetApp().CurrentPlayground is null) yield();
    }
}

uint g_PlayersInServerLast = 0;
array<PBTime@> g_Records;
bool g_CurrentlyLoadingRecords = false;

void UpdateRecords() {
    g_Records = GetPlayersPBs();
}

// fast enough to call once per frame
uint lastLPR_Rank;
uint lastLPR_Time;
uint get_LocalPlayersRank() {
    // once per frame
    if (lastLPR_Time + 5 > Time::Now) return lastLPR_Rank;
    // otherwise update
    lastLPR_Time = Time::Now;
    lastLPR_Rank = g_Records.Length;
    for (uint i = 0; i < g_Records.Length; i++) {
        if (g_Records[i].isLocalPlayer) {
            lastLPR_Rank = i + 1;
            break;
        }
    }
    return lastLPR_Rank;
}

/* GET INFO FROM GAME */

uint GetPlayersInServerCount() {
    auto cp = cast<CTrackMania>(GetApp()).CurrentPlayground;
    if (cp is null) return 0;
    return cp.Players.Length;
}

string GetLocalPlayerWSID() {
    try {
        return GetApp().Network.ClientManiaAppPlayground.LocalUser.WebServicesUserId;
    } catch {
        return "";
    }
}

// array<CGamePlayer@>@ GetPlayersInServer() {
array<CSmPlayer@>@ GetPlayersInServer() {
    auto cp = cast<CTrackMania>(GetApp()).CurrentPlayground;
    if (cp is null) return {};
    array<CSmPlayer@> ret;
    for (uint i = 0; i < cp.Players.Length; i++) {
        auto player = cast<CSmPlayer>(cp.Players[i]);
        if (player !is null) ret.InsertLast(player);
    }
    return ret;
}

// Returns a sorted list of player PB time objects. This is assumed to be called only from UpdateRecords().
array<PBTime@> GetPlayersPBs() {
    auto mapg = cast<CTrackMania>(GetApp()).Network.ClientManiaAppPlayground;
    if (mapg is null) return {};
    auto scoreMgr = mapg.ScoreMgr;
    auto userMgr = mapg.UserMgr;
    if (scoreMgr is null || userMgr is null) return {};
    auto players = GetPlayersInServer();
    if (players.Length == 0) return {};
    auto playerWSIDs = MwFastBuffer<wstring>();
    dictionary wsidToPlayer;
    for (uint i = 0; i < players.Length; i++) {
        playerWSIDs.Add(players[i].User.WebServicesUserId);
        @wsidToPlayer[players[i].User.WebServicesUserId] = players[i];
    }

    g_CurrentlyLoadingRecords = true;
    auto rl = scoreMgr.Map_GetPlayerListRecordList(userMgr.Users[0].Id, playerWSIDs, GetApp().RootMap.MapInfo.MapUid, "PersonalBest", "", "", "");
    while (rl.IsProcessing) yield();
    g_CurrentlyLoadingRecords = false;

    if (rl.HasFailed || !rl.HasSucceeded) {
        warn("Requesting records failed. Type,Code,Desc: " + rl.ErrorType + ", " + rl.ErrorCode + ", " + rl.ErrorDescription);
        return {};
    }

    /* note:
        - usually we expect `rl.MapRecordList.Length != players.Length`
        - `players[i].User.WebServicesUserId != rl.MapRecordList[i].WebServicesUserId`
       so we use a dictionary to look up the players (wsidToPlayer we set up earlier)
    */

    string localWSID = GetLocalPlayerWSID();

    array<PBTime@> ret;
    for (uint i = 0; i < rl.MapRecordList.Length; i++) {
        auto rec = rl.MapRecordList[i];
        auto _p = cast<CSmPlayer>(wsidToPlayer[rec.WebServicesUserId]);
        if (_p is null) {
            warn("Failed to lookup player from temp dict");
            continue;
        }
        ret.InsertLast(PBTime(_p, rec, rec.WebServicesUserId == localWSID));
        // remove the player so we can quickly get all players in server that don't have records
        wsidToPlayer.Delete(rec.WebServicesUserId);
    }
    // get pbs for players without pbs
    auto playersWOutRecs = wsidToPlayer.GetKeys();
    for (uint i = 0; i < playersWOutRecs.Length; i++) {
        auto wsid = playersWOutRecs[i];
        auto player = cast<CSmPlayer>(wsidToPlayer[wsid]);
        try {
            // sometimes we get a null pointer exception here on player.User.WebServicesUserId
            ret.InsertLast(PBTime(player, null));
        } catch {
            warn("Got exception updating records. Will retry in 500ms. Exception: " + getExceptionInfo());
            startnew(RetryRecordsSoon);
        }
    }
    ret.SortAsc();
    return ret;
}

void RetryRecordsSoon() {
    sleep(500);
    UpdateRecords();
}

class PBTime {
    string name;
    string club;
    string wsid;
    uint time;
    string timeStr;
    string replayUrl;
    uint recordTs;
    string recordDate;
    bool isLocalPlayer;
    PBTime(CSmPlayer@ _player, CMapRecord@ _rec, bool _isLocalPlayer = false) {
        wsid = _player.User.WebServicesUserId; // rare null pointer exception here? `[        Platform] [11:24:26] [players-pbs-dev]  Invalid address for member ID 03002000. This is likely a Nadeo bug! Setting it to null!`
        name = _player.User.Name;
        club = _player.User.ClubTag;
        isLocalPlayer = _isLocalPlayer;
        if (_rec !is null) {
            time = _rec.Time;
            timeStr = Time::Format(_rec.Time);
            replayUrl = _rec.ReplayUrl;
            recordTs = _rec.Timestamp;
            recordDate = Time::FormatString("%y-%m-%d %H:%M", recordTs);
        } else {
            time = 0;
            timeStr = "???";
            replayUrl = "";
            recordTs = 0;
            recordDate = "??-??-?? ??:??";
        }
    }
    int opCmp(PBTime@ other) const {
        if (time == 0) {
            return (other.time == 0 ? 0 : 1); // one or both PB unset
        }
        if (other.time == 0 || time < other.time) return -1;
        if (time == other.time) return 0;
        return 1;
    }
}

/* DRAW UI */

bool g_ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    if (!PermissionsOkay) return;

    if (UI::MenuItem("\\$0f4" + Icons::ListAlt + "\\$z " + Meta::ExecutingPlugin().Name, "", g_ShowWindow)) {
        g_ShowWindow = !g_ShowWindow;
    }
}

void RenderInterface() {
    DrawUI();
}

void Render() {
    if (S_ShowWhenUIHidden && !UI::IsOverlayShown()) {
        DrawUI();
    }
}

void DrawUI() {
    if (!PermissionsOkay) return;
    if (!g_ShowWindow) return;

    int uiFlags = UI::WindowFlags::NoCollapse;
    if (S_LockWhenUIHidden && !UI::IsOverlayShown())
        uiFlags = uiFlags | UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoInputs;

    UI::SetNextWindowSize(400, 400, UI::Cond::Appearing);
    if (UI::Begin("Players' PBs", g_ShowWindow, uiFlags)) {
        if (GetApp().CurrentPlayground is null || GetApp().Editor !is null) {
            UI::Text("Not in a map \\$999(or in editor).");
        } else if (g_Records.IsEmpty()) {
            if (g_CurrentlyLoadingRecords) {
                UI::Text("Loading...");
            } else {
                UI::Text("No records :(");
            }
        } else {

            // put everything in a child so buttons work when interface is hidden
            if (UI::BeginChild("##pbs-full-ui", UI::GetContentRegionAvail())) {

                // refresh/loading    #N Players: 22    Your Rank: 19 / 22
                if (!S_HideTopInfo) {
                    UI::AlignTextToFramePadding();
                    auto curPos1 = UI::GetCursorPos();
                    if (g_CurrentlyLoadingRecords) {
                        UI::Text("Updating...");
                    } else {
                        if (UI::Button("Refresh##local-plrs-pbs")) {
                            startnew(UpdateRecords);
                        }
                    }
                    UI::SameLine();
                    UI::SetCursorPos(curPos1 + vec2(80, 0));
                    auto nbPlayers = GetPlayersInServerCount();
                    UI::Text("Your Rank: " + LocalPlayersRank + " / " + nbPlayers);
                    if (S_TopInfoMapName) {
                        UI::SameLine();
                        UI::SetCursorPos(curPos1 + vec2(220, 0));
                        UI::Text(MakeColorsOkayDarkMode(GetApp().RootMap.MapName));
                    }
                }


                if (UI::BeginChild("##pb-table", UI::GetContentRegionAvail())) {

                    uint nbCols = 3; // rank, player and pb time are mandatory
                    if (S_ShowClubs) nbCols += 1;
                    if (S_ShowDates) nbCols += 1;
                    if (S_ShowReplayBtn) nbCols += 1;

                    if (UI::BeginTable("local-players-records", nbCols, UI::TableFlags::SizingStretchProp | UI::TableFlags::RowBg)) {
                        UI::TableSetupColumn(""); // rank
                        if (S_ShowClubs) UI::TableSetupColumn("Club");
                        UI::TableSetupColumn("Player");
                        UI::TableSetupColumn("PB Time");
                        if (S_ShowDates) UI::TableSetupColumn("PB Date");
                        if (S_ShowReplayBtn) UI::TableSetupColumn("Replay");
                        UI::TableHeadersRow();

                        UI::ListClipper clip(g_Records.Length);
                        while(clip.Step()) {
                            for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                                auto pb = g_Records[i];
                                UI::TableNextRow();

                                UI::TableNextColumn();
                                UI::Text(tostring(i + 1) + ".");

                                if (S_ShowClubs) {
                                    UI::TableNextColumn();
                                    // 0.07 ms overhead for MakeColorsOkayDarkMode for 16 players
                                    UI::Text(MakeColorsOkayDarkMode(ColoredString(pb.club)));
                                    // UI::Text(ColoredString(pb.club));
                                }

                                UI::TableNextColumn();
                                UI::Text(pb.name);

                                UI::TableNextColumn();
                                UI::Text(pb.timeStr);

                                if (S_ShowDates) {
                                    UI::TableNextColumn();
                                    UI::Text(pb.recordDate);
                                }

                                if (S_ShowReplayBtn) {
                                    UI::TableNextColumn();
                                    if (pb.replayUrl.Length > 0) {
                                        if (UI::Button(Icons::FloppyO + "##replay"+pb.wsid)) {
                                            OpenBrowserURL(pb.replayUrl);
                                        }
                                    }
                                }
                            }
                        }
                        UI::EndTable();
                    }
                }
                UI::EndChild();
            }
            UI::EndChild();
        }
    }
    UI::End();
}
