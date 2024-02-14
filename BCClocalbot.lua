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

function bot_commands(txt)
	local msg = txt
	if msg then
		m, l = string.find(msg, "banlist")
		if m then
			local val = string.sub(msg, l+2, string.len(msg))
			for i=1,#TwitchBotVars.BanLists do
				if tonumber(val) == i then
					TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[i]
					print("Active Ban List set to \"".. TwitchBotVars.ActiveBanList[1] .."\".")
					return
				end
			end
			return
		end
		
		m, l = string.find(msg, "turncount")
		if m then
			local val = string.sub(msg, l+2, string.len(msg))
			if ram.get_state() == 0x12 then
				print("Tournament in progress.")
				return
			else
				if tonumber(val) ~= nil then
					val = tonumber(val)
					if val > 99 then val = 99 end
					memory.write_u8(0x0802894C, val & 0xFF)
					print("Turn Count set to " .. val .. ".")
				end
			end
		end
		
		m, l = string.find(msg, "fight")
		if m then
			local newmsg = string.sub(msg, l+2, string.len(msg))
			if ram.get_state() == 0x12 then
				print("Tournament in progress.")
				return
			else
				local username = string.sub(newmsg, 0, string.find(newmsg, ",")-1)
				local codeName = string.sub(newmsg, string.find(newmsg, ",")+1, string.len(newmsg))
				local code = string.sub(codeName, string.find(codeName, ",")+1, string.len(newmsg))
				local twitchName = string.sub(code, string.find(code, ",")+1, string.len(newmsg))
				codeName = string.sub(codeName, 0, string.find(codeName, ",")-1)
				code = string.sub(code, 0, string.find(code, ",")-1)
				code = string.upper(code)
				print("[USER DATA]\n" .. username .. "\n" .. codeName .. "\n" .. code .. "\n" .. twitchName)
				
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
							print(twitchName..": Bad code detected.")
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
								print(twitchName..": Banned Chips Detected! (".. banned ..")")
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
									print(username.." submitted!")
									if count >= 15 then
										joypad.set({A=true,B=true,Start=true,Select=true})
										if #TwitchBotVars.ActiveBanList > 0 then
											TwitchBotVars.ActiveBanList = {}
											print("Active Ban List reset.")
										end
										print("Starting Tournament!")
										return
									end
								else
									print("Duplicate Entry found.")
									return
								end
							else
								print("Tournament's full!")
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
command_string = ""
input_current = nil
input_previous = nil
while true do
	if #TwitchBotVars.ActiveBanList < 1 and #TwitchBotVars.BanLists > 0 then
		TwitchBotVars.ActiveBanList = TwitchBotVars.BanLists[math.random(1, #TwitchBotVars.BanLists)]
		print("Active Ban List set to ".. TwitchBotVars.ActiveBanList[1] ..".")
	end
	input_current = input.get()
	if input_previous == nil then input_previous = input_current end
	for k,v in pairs(input_current) do
		if k == "Shift" then
			if string.len(command_string) > 0 and input_previous[k] ~= v and tonumber(command_string) ~= nil then
				bot_commands("banlist " .. command_string)
				command_string = ""
				break
			end
		end
		if k == "Tab" then
			if string.len(command_string) > 0 and input_previous[k] ~= v and tonumber(command_string) ~= nil then
				bot_commands("turncount " .. command_string)
				command_string = ""
				break
			end
		end
		if k == "Enter" then
			if string.len(command_string) > 0 and input_previous[k] ~= v and tonumber(command_string) ~= nil then
				local usr = loadUser(tonumber(command_string))
				bot_commands("fight " .. usr)
				command_string = ""
				break
			end
		end
		if k == "Backspace" and string.len(command_string) > 0 and input_previous[k] ~= v then
			command_string = string.sub(command_string,0, string.len(command_string)-1)
			break
		end
		if (string.find(k, "Number") ~= nil or string.find(k, "Keypad") ~= nil) and input_previous[k] ~= v then
			k = string.sub(k,string.len(k),string.len(k))
			command_string = command_string .. k
			break
		end
	end
	input_previous = input.get()
	if ram.get_state() == 0x12 and ram.get_tournament_state() == 0x04 and ram.get_tournament_substate() == 0x07 then
		local results = get_results()
		print(results.winner .." wins!\r\n")
	elseif ram.get_tournament_substate() ~= 0x05 then
		gui.clearGraphics()
		gui.pixelText(0, 154, command_string)
	end
	emu.frameadvance()
end