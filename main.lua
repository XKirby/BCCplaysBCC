local ram = require("RAM")
local data = require("data")
local parser = require("parser")
local sql_tournament_generator = require("generators/sql_tournament_generator")

local tournament = {}
local tournament_generator = sql_tournament_generator.new("db/database.db")

local function get_left_navi()
    return tournament[ram.get_left_navi_index()]
end

local function get_right_navi()
    return tournament[ram.get_right_navi_index()]
end

local function get_results()
	if ram.did_left_win() then
        return {
            winner = get_left_navi(),
            loser = get_right_navi()
        }
    else
        return {
            loser = get_left_navi(),
            winner = get_right_navi()
        }
    end
end

local function parse_name(name)
    -- shorten the name down to 11 characters or less by removing vowels
    if string.len(name) > 11 then
        return name:gsub("[AEIOUaeiou]", "")
    end
    return name
end

local function write_names_interrupt()
    local left_player = get_left_navi()
    local right_player = get_right_navi()
    ram.write_left_name(parse_name(left_player.username), left_player.navi[1])
    ram.write_right_name(parse_name(right_player.username), right_player.navi[1])

    -- Set background
    local bg = math.random(0x00, 0x1F)
    ram.set_background(bg)

    -- Set max name length to 11
    emu.setregister("R4", 11)
end

local function randomize_music_interrupt()
    -- only randomize the music if in battle
    if ram.get_tournament_substate() == 0x04 then
        local music = nil

        -- certain tracks are just silence
        repeat
            music = math.random(0, 18)
        until (music ~= nil and music ~= 0 and music ~= 1 and music ~= 2 and music ~= 15)

        emu.setregister("R0", music)
    end
end

chipnames_l = {}
chipnames_r = {}
local function draw_hud()
    -- only draw the name HUD if in battle
    if ram.get_tournament_substate() == 0x05 then
        local left_player_name = get_left_navi().display_name
		local left_player_username = get_left_navi().username
        gui.pixelText(0, 41, left_player_name)
        gui.pixelText(0, 48, left_player_username)

        local right_player_name = get_right_navi().display_name
		local right_player_username = get_right_navi().username
        local right_name_offset = (240 - (right_player_name:len() * 4)) - 1
        local right_username_offset = (240 - (right_player_username:len() * 4)) - 1
        gui.pixelText(right_name_offset, 41, right_player_name)
		gui.pixelText(right_username_offset, 48, right_player_username)

		if #chipnames_l == 0 and #chipnames_r == 0 then
			for i = 1, 12 do -- Chip Names
				local chipname_l = data.lookup_chips[get_left_navi().navi[i]]
				local chipname_r = data.lookup_chips[get_right_navi().navi[i]]
				table.insert(chipnames_l,chipname_l)
				table.insert(chipnames_r,chipname_r)
			end
		end
		if #chipnames_l > 0 and #chipnames_r > 0 and ram.is_fastforward() == 0x00 then
			for i = 1, 12 do -- Chip Names
				local chipname_pos_y = 48 + i*7 + 7
				gui.pixelText(0,chipname_pos_y,chipnames_l[i])
				gui.pixelText((240 - (chipnames_r[i]:len()*4))-1,chipname_pos_y,chipnames_r[i])
			end
		end
    else
		chipnames_l = {}
		chipnames_r = {}
		match_start = true
        gui.clearGraphics()
    end
end

local function register_events()
    -- why multiple interrupts lol?
    for _, addr in pairs(ram.addr.name_interrupts) do
        event.onmemoryexecute(write_names_interrupt, addr - 4, "write_names_interrupt")
    end
    event.onmemoryexecute(randomize_music_interrupt, ram.addr.music_interrupt - 4, "randomize_music_interrupt")
    event.onframeend(draw_hud, "draw_hud")
    -- event.onframeend(parser.run, "parse")
end

local function unregister_events()
    local exists = false
    repeat
        exists = event.unregisterbyname("write_write_names_interruptnames")
    until (not exists)
    event.unregisterbyname("randomize_music_interrupt")
    event.unregisterbyname("draw_hud")
    -- event.unregisterbyname("parse")
end

-- basic setup
math.randomseed(os.time())
unregister_events()
register_events()

-- ASM patch to fix the game forcibly using the players deck in the tournament registration
memory.write_u16_le(0x08026614, 0xE002) -- 0x08026614: bne 0x0802661C -> b 0x0802661C
match_start = true

-- main loop
while true do
    local state = ram.get_state()
    local substate = ram.get_substate()
	
	if state == 0x08 and substate == 0x02 then
		joypad.set({A=not (joypad.get()["A"])})
	end

    -- On state switch to CompanyIntro (i.e. game start)
    if(state == 0x13 and substate == 0x01) then
        memory.write_u16_le(0x020070F8, math.random(0xFFFF))    -- reseed rng

        -- Set current state to StateSwitch
        ram.set_state(0x13)
        -- Set target state to Tournament
        ram.set_substate(0x12)

        memory.write_u32_le(0x020070B8, 0x02008790)             -- pointer to deck indexes
        memory.writebyte(0x020070BE, 0x10)                      -- # of decks

        console.log("Starting tournament")
    -- tournament state
    elseif (state == 0x12) then
        -- tournament setup
        if (ram.get_tournament_state() == 0x00) then
            for i = 1, 16 do
                -- writes the deck indexes into the tournament registration
                -- uses decks 1 - 16
                -- i think registering deck #0 makes it use the player's deck, which we don't want
                memory.writebyte(0x02008790 + (i - 1), i)
                -- sets the "enable" and "watch battle" flag for all entrants
                memory.writebyte(0x0200B6B4 + (i - 1), 0x81)
            end
            tournament = tournament_generator.generate()
            ram.write_navis(tournament)

            -- switch the tournament states to do setup
            ram.set_tournament_state(0x02)
            ram.set_tournament_substate(0x07)
        -- in-battle tournament state
        elseif (ram.get_tournament_state() == 0x04) then
            -- press B at the start of battle for auto text skipping
            if (ram.is_fastforward() == 0x00) then
				for i=1, 60*60 do
					if match_start == false then break end
					if joypad.get().A or joypad.get().B then break end
					emu.frameadvance()
				end
				match_start = false
                joypad.set({B=true})
                emu.frameadvance()
            elseif (ram.get_tournament_substate() == 0x07) then
                local results = get_results()
                console.log("Battle results: " .. results.winner.username .. " beat " .. results.loser.username)
                tournament_generator.record_results(results)
            -- show the post match result for 5 sec before moving to the next match
            elseif (ram.get_tournament_substate() == 0x0B) then
                for i=1, 300 do
                    emu.frameadvance()
                end
				match_start = true
                joypad.set({B=true})
            end
        -- scroll down the post tournament results then restart the tournament
        elseif (ram.get_tournament_state() == 0x05 and ram.get_tournament_substate() == 0x05) then
            for i=1, 600 do
                if i % 100 == 0 then
                    joypad.set({R=true})
                end
                emu.frameadvance()
            end
			joypad.set({B=true})
			SQL.writecommand("DROP TABLE navicodes")
			SQL.writecommand("CREATE TABLE navicodes (username varChar(255), twitchName varChar(255), code varChar(4), codeName varChar(32), wins int NOT null, totalGames int NOT null)")
			emu.frameadvance()
			--[[
            -- Set current state to StateSwitch
            ram.set_state(0x13)
            -- Set target state to Tournament
            ram.set_substate(0x12)

            ram.set_tournament_state(0x00)
            ram.set_tournament_substate(0x00)

            console.log("Restarting new tournament")
			]]
        end
    end

    emu.frameadvance()
end