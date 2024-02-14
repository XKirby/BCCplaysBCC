local data = require("data")
local utils = require("utils")

local u8_chipID = 0x0200B79A
local u8_chipSelected = 0x0200B79B
local u8_menuID = 0x0200B789
local u8_submenuID = 0x0200B7A7
local u8_chipList = 0x02004A34
local u8_chipList2 = 0x02004CA4
local u8_currentFolder = 0x0200761C
local folderChips = 0x02007468
local saveName = 0x02008810
local navicode = 0x02004878

local pressed = {L = false, R = false, Select = false}
local netOps = {
	[0x32] = "Lan",
	[0x33] = "Mayl",
	[0x34] = "Dex",
	[0x35] = "Chaud",
	[0x36] = "Kai",
	[0x37] = "Mary",
	[0x38] = "Bass"
}

while true do
	gui.clearGraphics()
	if memory.read_u8(u8_menuID) == 0x1 and memory.read_u8(u8_submenuID) == 0x1 then
		local chip = memory.read_u8(u8_chipList + memory.read_u8(u8_chipID)*4)
		local netOp = memory.read_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x4)
		local netOpNavi = memory.read_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x5)
		if joypad.get().L and not pressed.L then
			if memory.read_u8(u8_chipID) + 0x40 == memory.read_u8(u8_chipSelected) then
				if joypad.get().A then
					chip = chip - 10
				else
					chip = chip - 1
				end
				if chip < 0 and memory.read_u8(u8_chipID) > 0 then chip = 190 end
				if chip < 200 and memory.read_u8(u8_chipID) == 0 then chip = 248 end
				while chip >= 191 and chip <= 199 do chip = chip - 1 end
				memory.write_u8(u8_chipList + memory.read_u8(u8_chipID)*4, chip)
				memory.write_u8(u8_chipList2 + memory.read_u8(u8_chipID)*2, chip)
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x18 + (memory.read_u8(u8_chipID))*4, chip)
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x19 + (memory.read_u8(u8_chipID))*4, memory.read_u8(u8_chipID))
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x6 + memory.read_u8(u8_chipID), memory.read_u8(u8_chipID))
			elseif memory.read_u8(u8_chipSelected) == 0x0 then
				netOp = netOp - 1
				if netOp < 0x32 then netOp = 0x38 end
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x4, netOp)
			end
		end
		if joypad.get().R and not pressed.R then
			if memory.read_u8(u8_chipID) + 0x40 == memory.read_u8(u8_chipSelected) then
				if joypad.get().A then
					chip = chip + 10
				else
					chip = chip + 1
				end
				if chip > 190 and memory.read_u8(u8_chipID) > 0 then chip = 0 end
				if chip > 248 and memory.read_u8(u8_chipID) == 0 then chip = 200 end
				while chip >= 191 and chip <= 199 do chip = chip + 1 end
				memory.write_u8(u8_chipList + memory.read_u8(u8_chipID)*4, chip)
				memory.write_u8(u8_chipList2 + memory.read_u8(u8_chipID)*2, chip)
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x18 + (memory.read_u8(u8_chipID))*4, chip)
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x19 + (memory.read_u8(u8_chipID))*4, memory.read_u8(u8_chipID))
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x6 + memory.read_u8(u8_chipID), memory.read_u8(u8_chipID))
			elseif memory.read_u8(u8_chipSelected) == 0x0 then
				netOp = netOp + 1
				if netOp > 0x38 then netOp = 0x32 end
				memory.write_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x4, netOp)
			end
		end
		pressed.L = joypad.get().L
		pressed.R = joypad.get().R
        local n = data.lookup_tbl[memory.read_u8(saveName + 0)] .. data.lookup_tbl[memory.read_u8(saveName + 2)] .. data.lookup_tbl[memory.read_u8(saveName + 4)] .. data.lookup_tbl[memory.read_u8(saveName + 6)]
		local l = {}
        for i=0,13 do
            if i == 0 then l[i] = memory.read_u8(folderChips + memory.read_u8(u8_currentFolder) * 0x90 + 0x4) end
            if i == 13 then l[13] = 1 end
			if i > 0 and i < 13 then l[i] = memory.read_u8(u8_chipList + (i-1)*4) end
        end
        gui.pixelText(0,0,"Name: "..n)
		local c = utils.encode_navicode(n, l)
		if #c == 29 then
			gui.pixelText(0,24,"Code: " .. c)
			if joypad.get().Select and not pressed.Select then
				local file = io.open("folders.txt", "a")
				file:write(n..","..c.."\n")
				io.close(file)
			end
		end
		pressed.Select = joypad.get().Select
		gui.pixelText(0,8,"NetOp: "..netOps[netOp])
		gui.pixelText(0,16,"Chip: "..data.lookup_chips[chip])
	elseif memory.read_u8(u8_menuID) == 0x4 and memory.read_u8(u8_submenuID) == 0x4 then
		local letterID = nil
		if joypad.get().Up then letterID = 0 end
		if joypad.get().Right then letterID = 1 end
		if joypad.get().Down then letterID = 2 end
		if joypad.get().Left then letterID = 3 end
		if letterID ~= nil then
			for key,bool in pairs(input.get()) do
				local found = false
				for i=0, #data.lookup_tbl do
					if letterID > 0 and (key == "Backspace" or key == "Space") then key = " " end
					if data.lookup_tbl[i] == key and found == false then
						found = true
					end
				end
				if found == true then
					if data.tbl[key] < 0x0B or (data.tbl[key] > 0x5D and data.tbl[key] < 0x78) then
						memory.write_u8(saveName + letterID*2, data.tbl[key])
					end
				end
			end
		end
		local n = data.lookup_tbl[memory.read_u8(saveName + 0)] .. data.lookup_tbl[memory.read_u8(saveName + 2)] .. data.lookup_tbl[memory.read_u8(saveName + 4)] .. data.lookup_tbl[memory.read_u8(saveName + 6)]
		local c = ""
		for i=0,23 do
			local look = memory.read_u8(navicode + i*2)
			if (look >= 0x0 and look < 0x10) or (look > 0x5D and look < 0x78) then
				if look == 0xB then look = 0x5E end
				if look == 0xC then look = 0x66 end
				if look == 0xD then look = 0x72 end
				if look == 0xE then look = 0x62 end
				if look == 0xF then look = 0x6C end
				c = c .. data.lookup_tbl[look]
			else
				c = c .. "~"
			end
			if i % 4 == 3 and i < 23 then c = c .. "-" end
		end
		gui.pixelText(0,0,"Name: "..n)
		gui.pixelText(0,8,"Code: "..c)
		if #c == 29 then
			if joypad.get().Select and not pressed.Select then
				local file = io.open("folders.txt", "a")
				file:write(n..","..c.."\n")
				io.close(file)
			end
		end
		pressed.Select = joypad.get().Select
	end
	emu.frameadvance()
end