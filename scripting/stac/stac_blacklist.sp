#pragma semicolon 1

void LoadBlacklistFiles() {
	if (g_AngleSnapMapBlacklist == null) {
		g_AngleSnapMapBlacklist = new ArrayList(ByteCountToCells(64));
	} else {
		g_AngleSnapMapBlacklist.Clear();
	}

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,sizeof(path),"configs/stac_map_blacklist.txt");

	KeyValues kv = new KeyValues("StAC Blacklist");

	if (!kv.ImportFromFile(path)) {
		LogError("[StAC]: Failed to read map blacklist file %s",path);
		delete kv;
		return;
	}

	kv.Rewind();
	if (!kv.JumpToKey("anglesnap",false)) {
		char map[64];
		do {
			kv.GetString(NULL_STRING,map,sizeof(map));
			TrimString(map);
			if (map[0]=='\0') continue;
			g_AngleSnapMapBlacklist.PushString(map);
		} while (kv.GotoNextKey(false));
	}
	
	delete kv;

	return;
}

void CheckAndApplyBlacklist() {
	if (g_AngleSnapMapBlacklist==null) return;

	char map[64];
	GetCurrentMap(map,sizeof(map));

	char buffer[64];

	char regexErrorMsg[128];
	RegexError regexError;
	Regex pattern;
	bool found;

	for (int i = 0; i < g_AngleSnapMapBlacklist.Length; i++) {
		g_AngleSnapMapBlacklist.GetString(i, buffer, sizeof(buffer));
		pattern = new Regex(buffer, _, regexErrorMsg, sizeof(regexErrorMsg), regexError);
		if (regexError != REGEX_ERROR_NONE) {
			delete pattern;
			LogError("Error with regex pattern \"%s\": %s", buffer, regexErrorMsg);
		}
		if (pattern.Match(map) > 0) {
			found = true;
			break;
		}
	}
	
	if (found) {
		g_PrevAimSnapValue = stac_max_aimsnap_detections.IntValue;
		stac_max_aimsnap_detections.SetInt(CVAR_RESET_VAL);
	}

	delete pattern;
}