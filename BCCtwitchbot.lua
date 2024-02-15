-- Twitch Bot Variables
TwitchBotVars = {
	Channel = "",
	Name = "",
	OAuth = "",
	Client = nil
}
loadfile("settings.txt")()

socket = require("socket.core")
ram = require("RAM")
database = require("data")
utils = require("utils")
local cli,err = socket.tcp()
TwitchBotVars.Client = cli

if TwitchBotVars.Client then
	TwitchBotVars.Client:settimeout(1/5)
	TwitchBotVars.Client:connect(socket.dns.toip("irc.chat.twitch.tv"),6667)
	TwitchBotVars.Client:send("PASS "..TwitchBotVars.OAuth.."\r\n")
	TwitchBotVars.Client:send("NICK "..TwitchBotVars.Name:lower().."\r\n")
	TwitchBotVars.Client:send("JOIN #"..TwitchBotVars.Channel:lower().."\r\n")
end

function twitchbot_commands()
	local msg, err = TwitchBotVars.Client:receive()
	if msg then
		print(msg)
		
		m, l = string.find(msg, ":!info")
		if m then
			TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :!fight <UserName>,<CodeName>,<Code> to add a setup! !left <value>, !right <value>, or !random <value> to bet on combatants at the start of each battle with Zenny! !balance to see how much Zenny you have! Use !banned to check the current Chip ban list! Navi Setups can be generated here: https://therockmanexezone.com/ncgen/\r\n")
			return
		end
		
		m, l = string.find(msg, ":!banned")
		if m then
			if #TwitchBotVars.ActiveBanList > 0 then
				local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
				local chips = ""
				for _,v in pairs(TwitchBotVars.ActiveBanList[2]) do
					if chips:len() > 0 then chips = chips .. ", " end
					chips = chips .. database.lookup_chips[v]
				end
				TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName.." Here's the current ban list, titled \"".. TwitchBotVars.ActiveBanList[1] .."\": ".. chips .."\r\n")
			end
		end
		
		m, l = string.find(msg, ":!banchange")
		if m then
			local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
			local val = string.sub(msg, l+2, string.len(msg))
			if twitchName == TwitchBotVars.Channel or twitchName == TwitchBotVars.Name then
				for i=1,#TwitchBotVars.BanLists do
					if val == TwitchBotVars.BanLists[i][1] then
						TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[i]
						TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Active Ban List set to ".. TwitchBotVars.ActiveBanList[1] ..".\r\n")
						return
					end
				end
			end
			return
		end
		
		m, l = string.find(msg, ":!turncount")
		if m then
			local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
			local val = string.sub(msg, l+2, string.len(msg))
			if twitchName == TwitchBotVars.Channel or twitchName == TwitchBotVars.Name then
				if ram.get_state() == 0x12 then
					TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Tournament in progress.\r\n")
					return
				else
					if tonumber(val) ~= nil then
						val = tonumber(val)
						if val > 99 then val = 99 end
						TwitchBotVars.TurnCount = val
						TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Turn Count set to " .. val .. ".\r\n")
					end
				end
			end
		end
		
		m, l = string.find(msg, ":!balance")
		if m then
			local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
			SQL.opendatabase("db/database.db")
			local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
			if tbl == "No rows found" then
				SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
				tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
				return
			end
			TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName.." Has "..tbl["zenny 0"].." Zenny.\r\n")
			return
		end
		
		m, l = string.find(msg, ":!left")
		if m then
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
				val = tonumber(val)
				
				if val ~= nil and type(val) == "number" then
					SQL.opendatabase("db/database.db")
					local viewers = SQL.readcommand("SELECT * FROM viewers WHERE twitchName=\""..twitchName.."\"")
					if viewers == "No rows found" then
						SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
					end
					if val > 0 then
						local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
						if val > tbl["zenny 0"] then val = tbl["zenny 0"] end
						SQL.writecommand("UPDATE viewers SET betValue = "..val..", betTarget = \"l\" WHERE twitchName = \""..twitchName.."\"")
						TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName.." bets left with "..val.." Zenny!\r\n")
						return
					end
				end
			end
			return
		end
		
		m, l = string.find(msg, ":!right")
		if m then
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
				val = tonumber(val)
				
				if val ~= nil and type(val) == "number" then
					SQL.opendatabase("db/database.db")
					local viewers = SQL.readcommand("SELECT * FROM viewers WHERE twitchName=\""..twitchName.."\"")
					if viewers == "No rows found" then
						SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
					end
					if val > 0 then
						local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
						if val > tbl["zenny 0"] then val = tbl["zenny 0"] end
						SQL.writecommand("UPDATE viewers SET betValue = "..val..", betTarget = \"r\" WHERE twitchName = \""..twitchName.."\"")
						TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName.." bets right with "..val.." Zenny!\r\n")
						return
					end
				end
			end
			return
		end
		
		m, l = string.find(msg, ":!random")
		if m then
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
				val = tonumber(val)
				
				if val ~= nil and type(val) == "number" then
					SQL.opendatabase("db/database.db")
					local viewers = SQL.readcommand("SELECT * FROM viewers WHERE twitchName=\""..twitchName.."\"")
					if viewers == "No rows found" then
						SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
					end
					if val > 0 then
						local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
						if val > tbl["zenny 0"] then val = tbl["zenny 0"] end
						local choice = "l"
						if math.random(0,1) == 1 then choice = "r" end
						SQL.writecommand("UPDATE viewers SET betValue = "..val..", betTarget = \""..choice.."\" WHERE twitchName = \""..twitchName.."\"")
						TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName.." bets randomly with "..val.." Zenny!\r\n")
						return
					end
				end
			end
			return
		end
		
		m, l = string.find(msg, ":!fight")
		if m then
			local newmsg = string.sub(msg, l+2, string.len(msg))
			if ram.get_state() == 0x12 then
				TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Tournament in progress.\r\n")
				return
			else
				local username = string.sub(newmsg, 0, string.find(newmsg, ",")-1)
				local codeName = string.sub(newmsg, string.find(newmsg, ",")+1, string.len(newmsg))
				local code = string.sub(codeName, string.find(codeName, ",")+1, string.len(newmsg))
				local twitchName = string.sub(msg, 2, string.find(msg, "!")-1)
				codeName = string.sub(codeName, 0, string.find(codeName, ",")-1)
				codeName = string.upper(codeName)
				
				if username ~= nil and codeName ~= nil and code ~= nil then
					if #codeName <= 4 and #code == 29 then
						local data = utils.decode_navicode(codeName, code)
						local badcode = false
						if data[1] < 200 or data[13] ~= 1 then
							badcode = true
						end
						for i=2,12 do
							if data[i] > 190 then
								badcode = true
							end
						end
						if badcode then
							TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName..": Bad code detected.\r\n")
							return
						else
							local banned = ""
							if #TwitchBotVars.ActiveBanList > 0 then
								for i=1,12 do
									for _,v in pairs(TwitchBotVars.ActiveBanList[2]) do
										if data[i] == v and v > 0 then
											if banned:len() > 0 then banned = banned .. ", " end
											banned = banned .. database.lookup_chips[v]
										end
									end
								end
							end
							if banned:len() > 0 then
								TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..twitchName..": Banned Chips Detected! (".. banned ..")\r\n")
								return
							end
							
							SQL.opendatabase("db/database.db")
							local participants = SQL.readcommand("SELECT * FROM navicodes")
							local count = 0
							if participants ~= "No rows found" then
								for k,v in pairs(participants) do
									if count < tonumber(string.sub(k, string.find(k, " ")+1,#k))+1 then
										count = tonumber(string.sub(k, string.find(k, " ")+1,#k))+1
									end
								end
							else
								count = 0
							end
							if count < 16 then
								local codeCheck = SQL.readcommand("SELECT * FROM navicodes WHERE code = \""..code.."\" AND codeName =\""..codeName.."\"")
								local userCheck = SQL.readcommand("SELECT * FROM navicodes WHERE username = \""..username.."\" AND twitchName =\""..twitchName.."\"")
								local oldcodeCheck = SQL.readcommand("SELECT * FROM oldcodes WHERE code = \""..code.."\" AND codeName =\""..codeName.."\"")
								local olduserCheck = SQL.readcommand("SELECT * FROM oldcodes WHERE username = \""..username.."\" AND twitchName =\""..twitchName.."\"")
								if userCheck == "No rows found" and codeCheck == "No rows found" then
									SQL.writecommand("INSERT INTO navicodes VALUES (\""..username.."\", \""..twitchName.."\", \""..code.."\", \""..codeName.."\", 0, 0)")
									if olduserCheck == "No rows found" and oldcodeCheck == "No rows found" then
										SQL.writecommand("INSERT INTO oldcodes VALUES (\""..username.."\", \""..twitchName.."\", \""..code.."\", \""..codeName.."\", 0, 0)")
									end
									TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :"..username.." submitted!\r\n")
									joypad.set({A=true,B=true,Start=true,Select=true})
									if count >= 15 then
										if #TwitchBotVars.ActiveBanList > 0 then
											TwitchBotVars.ActiveBanList = {}
											TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Active Ban List reset.\r\n")
										end
										TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Starting Tournament!\r\n")
										return
									end
								else
									TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Duplicate Entry found.\r\n")
									return
								end
							else
								TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Tournament's full!\r\n")
								return
							end
						end
					end
				end
			end
			return
		end
	end
end

local function get_results()
	SQL.opendatabase("db/database.db")
	local bets_left = SQL.readcommand("SELECT betValue, twitchName FROM viewers WHERE betTarget=\"l\"")
	local bets_right = SQL.readcommand("SELECT betValue, twitchName FROM viewers WHERE betTarget=\"r\"")
    local prizepool = {0,0}
	if bets_left ~= "No rows found" then
		for k,v in pairs(bets_left) do
			local m, l = string.find(k, "betValue")
			if m then
				prizepool[1] = prizepool[1] + bets_left[k]
			end
		end
	end
	if bets_right ~= "No rows found" then
		for k,v in pairs(bets_right) do
			local m, l = string.find(k, "betValue")
			if m then
				prizepool[2] = prizepool[2] + bets_right[k]
			end
		end
	end
	console.log("Total Prize Pool: "..prizepool[1]+prizepool[2].." Zenny")
	if ram.did_left_win() then
		if bets_left ~= "No rows found" and bets_right ~= "No rows found" then
			for k,v in pairs(bets_right) do
				m, l = string.find(k, "twitchName")
				if m then
					local tbl = SQL.readcommand("SELECT zenny FROM viewers where twitchName =\""..v.."\"")
					SQL.writecommand("UPDATE viewers SET zenny = "..tbl["zenny 0"]-bets_right["betValue "..string.sub(k, string.find(k, " ")+1,#k)]..", betValue = 0 WHERE twitchName = \""..v.."\"")
				end
			end
			for k,v in pairs(bets_left) do
				m, l = string.find(k, "twitchName")
				if m then
					local tbl = SQL.readcommand("SELECT zenny FROM viewers where twitchName =\""..v.."\"")
					local prizeamount = math.floor(prizepool[2] * (bets_left["betValue "..string.sub(k, string.find(k, " ")+1,#k)]/prizepool[1]))
					SQL.writecommand("UPDATE viewers SET zenny = "..tbl["zenny 0"]+prizeamount..", betValue = 0 WHERE twitchName = \""..v.."\"")
				end
			end
		end
		SQL.writecommand("UPDATE viewers SET betValue = 0, betTarget = \"n\"")
		SQL.writecommand("UPDATE viewers SET zenny = 100 WHERE zenny < 100")
        return {
			winner = "Left",
			prize = prizepool[2],
			totalbet = prizepool[1]+prizepool[2]
		}
    else
		if bets_left ~= "No rows found" and bets_right ~= "No rows found" then
			for k,v in pairs(bets_left) do
				m, l = string.find(k, "twitchName")
				if m then
					local tbl = SQL.readcommand("SELECT zenny FROM viewers where twitchName =\""..v.."\"")
					SQL.writecommand("UPDATE viewers SET zenny = "..tbl["zenny 0"]-bets_left["betValue "..string.sub(k, string.find(k, " ")+1,#k)]..", betValue = 0 WHERE twitchName = \""..v.."\"")
				end
			end
			for k,v in pairs(bets_right) do
				m, l = string.find(k, "twitchName")
				if m then
					local tbl = SQL.readcommand("SELECT zenny FROM viewers where twitchName =\""..v.."\"")
					local prizeamount = math.floor(prizepool[1] * (bets_right["betValue "..string.sub(k, string.find(k, " ")+1,#k)]/prizepool[2]))
					SQL.writecommand("UPDATE viewers SET zenny = "..tbl["zenny 0"]+prizeamount..", betValue = 0 WHERE twitchName = \""..v.."\"")
				end
			end
		end
		SQL.writecommand("UPDATE viewers SET betValue = 0, betTarget = \"n\"")
		SQL.writecommand("UPDATE viewers SET zenny = 100 WHERE zenny < 100")
        return {
			winner = "Right",
			prize = prizepool[1],
			totalbet = prizepool[1]+prizepool[2]
		}
    end
end

counter = 0
SQL.opendatabase("db/database.db")
SQL.writecommand("CREATE TABLE oldcodes (username varChar(255), twitchName varChar(255), code varChar(4), codeName varChar(32), wins int NOT null, totalGames int NOT null)")
SQL.writecommand("CREATE TABLE navicodes (username varChar(255), twitchName varChar(255), code varChar(4), codeName varChar(32), wins int NOT null, totalGames int NOT null)")
SQL.writecommand("CREATE TABLE viewers (twitchName varChar(255), zenny int NOT null, betValue int NOT null, betTarget varChar(8))")
while true do
	if #TwitchBotVars.ActiveBanList < 1 and #TwitchBotVars.BanLists > 0 then
		TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[math.random(1, #TwitchBotVars.BanLists)]
		TwitchBotVars.Client:send("PRIVMSG #"..TwitchBotVars.Channel.." :Active Ban List set to ".. TwitchBotVars.ActiveBanList[1] ..".\r\n")
	end
	if counter % 10 == 0 and TwitchBotVars.Client then
		twitchbot_commands()
	end
	if counter % 3600 == 0 and TwitchBotVars.Client then
		TwitchBotVars.Client:settimeout(1/60)
	end
	if ram.get_state() == 0x12 then
		if TwitchBotVars.TurnCount > 0 then
			if TwitchBotVars.TurnCount > 99 then TwitchBotVars.TurnCount = 99 end
			memory.write_u8(0x0308AE, TwitchBotVars.TurnCount, "ROM")
		end
		if ram.get_tournament_state() == 0x04 and ram.get_tournament_substate() == 0x07 then
			local results = get_results()
			if results.prize > 0 and results.totalbet > 0 then
				TwitchBotVars.Client:send("PRIVMSG #".. TwitchBotVars.Channel .." :".. results.winner .." wins! Distributing ".. results.prize .."/".. results.totalbet .." Zenny.\r\n")
			end
		end
	end
	counter = counter + 1
	emu.frameadvance()
end