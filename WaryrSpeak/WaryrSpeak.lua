local gluks = {
	"ckk!",
	"gluk!",
	"slp.",
	"slp~slp~slp"
	"*bleh!*",
}

-- Turning false many areas, including whispers
local defaults = {
	enabled = true,
	guild = false,
	officer = false,
	whisper = false,
}

-- Default blocking many popular channels where RP doesn't occur.
local blockedChannelsDefaults = {
	"NewcomerChat",
	"Raid",
	"LookingForGroup",
	"Trade",
	"General",
	"GuildRecruitment",
	"LocalDefense",
	"WorldDefense",
}

local db
local blockedChannels
local hyperlinks = {}

local function OnEvent(self, event, addon)
	if addon == "WaryrSpeak" then
		WaryrSpeakDB = WaryrSpeakDB or CopyTable(defaults)
		WaryrSpeakDBBlockedChannels = WaryrSpeakDBBlockedChannels or CopyTable(blockedChannelsDefaults)
		blockedChannels = WaryrSpeakDBBlockedChannels
		db = WaryrSpeakDB
		for k, v in pairs(defaults) do
			if db[k] == nil then
				db[k] = v
			end
		end
		self:UnregisterEvent("ADDON_LOADED")
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

-- gluk1, gluk2, etc placeholders
local function ReplaceLink(s)
	tinsert(hyperlinks, s)
	return "gluk"..#hyperlinks
end

local function RestoreLink(s)
	local n = tonumber(s:match("%d"))
	return hyperlinks[n]
end

local channelOptions = {
	GUILD = function() return db.guild end,
	OFFICER = function() return db.officer end,
	WHISPER = function() return db.whisper end,
}

local function ShouldGluk(chatType)
	if db.enabled then
		if channelOptions[chatType] then
			return channelOptions[chatType]()
		else
			return true
		end
	end
end

local function ShouldGlukTwo(chatType, channel)
	if chatType == "CHANNEL" then
		local id, channelName = GetChannelName(channel)

		for key, value in pairs(blockedChannels) do
			if channelName == value then
				-- print("Found " .. channelName .. " in blockedChannels table.  Do not gluk")
				return false
			end
		end
	end
	-- print("Did not find " .. channelName .. " in blockedChannels table.  gluk away!")
	return true
end

local makegluk = SendChatMessage

function SendChatMessage(msg, chatType, language, channel)

	if msg == "GHI2ChannelReadyCheck" then
		return
	end

	-- if Emote, then return it and end.
	if CHAT_MSG_EMOTE then
		return
	end

	if ShouldGluk(chatType) and ShouldGlukTwo(chatType, channel) then
		wipe(hyperlinks)

		local gluk = gluks[random(#gluks)]
		local rng = random(5)
		local s = msg:gsub("|c.-|r", ReplaceLink)
		
		s = s:gsub("{.-}", ReplaceLink)

		-- Alternating some O's to make it look a bit forced?
		s = s:gsub("([lr])([%S]*s?)", function(l, following)
		    if l == 'o' and following == 'o' then
		        return 'O' .. following
		    elseif l == 'O' and following == 'o' then
		        return 'O' .. following
		    else
		        return 'O' .. following
		    end
		end)

		s = s:gsub("c " , "k ")
		s = s:gsub("C " , "K ")
		s = s:gsub("j" , "jh")
		s = s:gsub("J" , "JH")
		s = s:gsub("p " , "lp ")
		s = s:gsub("P " , "Lp ")
		s = s:gsub("v " , "e ")
		s = s:gsub("V " , "E ")
		s = s:gsub("w" , "r")
		s = s:gsub("W" , "R")
		s = s:gsub("w " , "r ")
		s = s:gsub("W " , "R ")

		-- Reformats as string, I think?
		s = format(" %s ", s)

		-- Adds stutter on first character randomly:
		for k in gmatch(s, "%a+") do
			if random(6) == 2 then
				local firstChar = k:sub(1, 1)
				s = s:gsub(format(" %s ", k), format(" %s-%s ", firstChar, k))
			end
		end

		-- Trims up data and pushes out the function for game:
		s = s:trim()

		-- Inserts the random "glucks" (renamed object "gluk")
		s = rng == 1 and s.." "..gluk or s:gsub("!$", " "..gluk)
		s = #s <= 500 and s:gsub("gluk%d", RestoreLink) or msg
		makegluk(s, chatType, language, channel)
	else
		makegluk(msg, chatType, language, channel)
	end
end

-- Enabled/Disabled Messaging:
local EnabledMsg = {
	[true] = "|cffADFF2FEnabled|r",
	[false] = "|cffFF2424Disabled|r",
}

local function PrintMessage(msg)
	print("WaryrSpeak: "..msg)
end

SLASH_WaryrSPEAK1 = "/Waryr"
SLASH_WaryrSPEAK2 = "/Waryrspeak"

local function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

-- Help Page Command In Game:
SlashCmdList.WaryrSPEAK = function(msg)
	if msg == "guild" then
		db.guild = not db.guild
		PrintMessage("Guild - "..EnabledMsg[db.guild])
	elseif msg == "officer" then
		db.officer = not db.officer
		PrintMessage("Officer - "..EnabledMsg[db.officer])
	elseif msg == "whisper" then
		db.whisper = not db.whisper
		PrintMessage("Whisper - "..EnabledMsg[db.whisper])
	elseif string.find(msg, "add") then
		local exploded = {}
		for substring in string.gmatch(msg, "[^%s]+") do
		   table.insert(exploded, substring)
		end
		if exploded[2] then
			table.insert(blockedChannels, exploded[2])
			PrintMessage("Added " .. exploded[2] .. " to the blocked channel list.")
		else
			PrintMessage("You must provide a channel name to block.")
		end
	elseif string.find(msg, "remove") then
		local exploded = {}
		local foundAndRemoved = false
		for substring in string.gmatch(msg, "[^%s]+") do
		   table.insert(exploded, substring)
		end
		if exploded[2] then
			for key, value in pairs(blockedChannels) do
				if value == exploded[2] then
					PrintMessage("Removed " .. exploded[2] .. " from the blocked channels list.")
					table.remove(blockedChannels, tablefind(blockedChannels, exploded[2]))
					foundAndRemoved = true
				end
			end
			if foundAndRemoved == false then
				PrintMessage("Could not find the specified channel in the blocked channels list.")
			end
		else
			PrintMessage("You must provide a channel name to unblock.")
		end
	elseif msg == "blocked" then
		PrintMessage("Currently blocked channels:")
		for key, value in pairs(blockedChannels) do
			print(value)
		end
	elseif msg == "help" then
		PrintMessage("Available commands:")
		print("/Waryr guild - enable/disable guild chat Waryrspeak")
		print("/Waryr officer - enable/disable officer chat Waryrspeak")
		print("/Waryr whisper - enable/disable whisper Waryrspeak")
		print("/Waryr add <channel name> - prevent Waryrspeak in a specific channel")
		print("/Waryr remove <channel name> - re-enable Waryrspeak in a blocked channel (see /Waryr add)")
		print("/Waryr blocked - print list of currently blocked channels")
	else
		db.enabled = not db.enabled
		PrintMessage(EnabledMsg[db.enabled])
	end
end
