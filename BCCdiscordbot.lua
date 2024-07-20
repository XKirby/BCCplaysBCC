-- Twitch Bot Variables
TwitchBotVars = {}

loadfile("settings.txt")()

socket = require("socket.core")
ram = require("RAM")
database = require("data")
utils = require("utils")

function bot_commands(usr, txt)
	local msg = txt
	local result = 0
	if msg then
		m, l = string.find(msg, "!banlist")
		if m then
			SQL.opendatabase("db/database.db")
			local val = string.sub(msg, l+2, string.len(msg))
			for i=1,#TwitchBotVars.BanLists do
				if tonumber(val) == i then
					TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[i]
					result = "Active Banlist set to " .. TwitchBotVars.ActiveBanList[1] .. "."
					SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
					return result
				end
			end
			result = "Active Banlist set to " .. TwitchBotVars.ActiveBanList[1] .. "."
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
		end
		
		m, l = string.find(msg, "!turncount")
		if m then
			SQL.opendatabase("db/database.db")
			local val = string.sub(msg, l+2, string.len(msg))
			if ram.get_state() == 0x12 then
				result = "Tournament in progress."
				SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
				return result
			else
				if tonumber(val) ~= nil then
					val = tonumber(val)
					if val > 99 then val = 99 end
					TwitchBotVars.TurnCount = val
					result = "Turn Count set to " .. val .. "."
					SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
				end
			end
		end
		
		m, l = string.find(msg, "!balance")
		if m then
			SQL.opendatabase("db/database.db")
			local twitchName = usr
			local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
			if tbl == "No rows found" then
				SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
				tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
			end
			result = twitchName.." has "..tbl["zenny 0"].." Zenny."
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
		end
		
		m, l = string.find(msg, "!left")
		if m then
			SQL.opendatabase("db/database.db")
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = usr
				val = math.floor(tonumber(val))
				
				if val ~= nil and type(val) == "number" then
					local viewers = SQL.readcommand("SELECT * FROM viewers WHERE twitchName=\""..twitchName.."\"")
					if viewers == "No rows found" then
						SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
					end
					if val > 0 then
						local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
						if val > tbl["zenny 0"] then val = tbl["zenny 0"] end
						SQL.writecommand("UPDATE viewers SET betValue = "..val..", betTarget = \"l\" WHERE twitchName = \""..twitchName.."\"")
						result = "Bet accepted."
						SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
						return result
					end
				end
			end
			result = "Match not in progress."
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
		end
		
		m, l = string.find(msg, "!right")
		if m then
			SQL.opendatabase("db/database.db")
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = usr
				val = math.floor(tonumber(val))
				
				if val ~= nil and type(val) == "number" then
					local viewers = SQL.readcommand("SELECT * FROM viewers WHERE twitchName=\""..twitchName.."\"")
					if viewers == "No rows found" then
						SQL.writecommand("INSERT INTO viewers VALUES (\""..twitchName.."\", 100, 0, \"n\")")
					end
					if val > 0 then
						local tbl = SQL.readcommand("SELECT zenny FROM viewers WHERE twitchName=\""..twitchName.."\"")
						if val > tbl["zenny 0"] then val = tbl["zenny 0"] end
						SQL.writecommand("UPDATE viewers SET betValue = "..val..", betTarget = \"r\" WHERE twitchName = \""..twitchName.."\"")
						result = "Bet accepted."
						SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
						return result
					end
				end
			end
			result = "Match not in progress."
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
		end
		
		m, l = string.find(msg, "!random")
		if m then
			SQL.opendatabase("db/database.db")
			if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.is_fastforward() == 0x00 then
				local val = string.sub(msg, l+2, string.len(msg))
				local twitchName = usr
				val = math.floor(tonumber(val))
				
				if val ~= nil and type(val) == "number" then
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
						result = "Bet accepted."
						SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
						return result
					end
				end
			end
			result = "Match not in progress."
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
		end
		
		m, l = string.find(msg, "!fight")
		if m then
			SQL.opendatabase("db/database.db")
			local newmsg = string.sub(msg, l+2, string.len(msg))
			if ram.get_state() == 0x12 then
				result = "Tournament in progress."
				SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
				return result
			else
				local username = string.sub(newmsg, 0, string.find(newmsg, ",")-1)
				local codeName = string.sub(newmsg, string.find(newmsg, ",")+1, string.len(newmsg))
				local code = string.sub(codeName, string.find(codeName, ",")+1, string.len(newmsg))
				local twitchName = usr
				codeName = string.sub(codeName, 0, string.find(codeName, ",")-1)
				code = string.sub(code, 0, string.len(code))
				code = string.upper(code)
				
				if username ~= nil and codeName ~= nil and code ~= nil then
					if string.len(codeName) <= 4 and string.len(code) == 29 then
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
							result = "Bad code detected."
							SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
							return result
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
								result = "Banned Chips Detected! (".. banned ..")"
								SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
								return result
							end
							
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
									result = username.." submitted!"
									if count >= 15 then
										joypad.set({A=true,B=true,Start=true,Select=true})
										if #TwitchBotVars.ActiveBanList > 0 then
											TwitchBotVars.ActiveBanList = {}
											print("Active Ban List reset.")
										end
										result = result .. "\r\nStarting Tournament!"
										SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
										return result
									end
									SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
									return result
								else
									result = "Duplicate Entry found."
									SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
									return result
								end
							else
								result = "Tournament's full!"
								SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
								return result
							end
						end
					end
				end
			end
			result = "???"
			SQL.writecommand("UPDATE commands SET result = \"" .. result .. "\" WHERE cmd =\"" .. txt .. "\" AND user = \"" .. usr .. "\"")
			return result
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

function loadUser(id)
	lineindex = 1
    local file = assert(io.open("db/navicodes.csv", "r"))
    for line in file:lines() do
		if lineindex == id then
			user = line
			break
		end
		lineindex = lineindex + 1
    end
    file:close()
	return user
end

SQL.opendatabase("db/database.db")
SQL.writecommand("CREATE TABLE oldcodes (username varChar(255), twitchName varChar(255), code varChar(4), codeName varChar(32), wins int NOT null, totalGames int NOT null)")
SQL.writecommand("CREATE TABLE navicodes (username varChar(255), twitchName varChar(255), code varChar(4), codeName varChar(32), wins int NOT null, totalGames int NOT null)")
SQL.writecommand("CREATE TABLE viewers (twitchName varChar(255), zenny int NOT null, betValue int NOT null, betTarget varChar(8))")
SQL.writecommand("CREATE TABLE commands (user varChar(255), userid varChar(255), cmd varChar(512), result varChar(512))")

while true do
	if #TwitchBotVars.ActiveBanList < 1 and #TwitchBotVars.BanLists > 0 then
		TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[math.random(1, #TwitchBotVars.BanLists)]
		print("Active Ban List set to ".. TwitchBotVars.ActiveBanList[1] ..".")
	end
	local tbl = SQL.readcommand("SELECT * FROM commands WHERE result IS NULL")
	if tbl ~= "No rows found" then
		for i=0,#tbl do
			if tbl["result" .. i] == nil then
				tbl["result" .. i] = bot_commands(tbl["user " .. i], tbl["cmd " .. i])
				print(tbl["result" .. i])
			end
		end
	end
	if TwitchBotVars.TurnCount > 0 then
		if TwitchBotVars.TurnCount > 0 then
			if TwitchBotVars.TurnCount > 99 then TwitchBotVars.TurnCount = 99 end
			memory.write_u8(0x0308AE, TwitchBotVars.TurnCount, "ROM")
		end
		if ram.get_tournament_state() == 0x04 and ram.get_tournament_substate() == 0x07 then
			local results = get_results()
			print(results.winner .." wins!\r\n")
		end
	end
	emu.frameadvance()
end