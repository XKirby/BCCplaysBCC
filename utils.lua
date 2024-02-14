local utils = {}

local data = require("data")

function utils.decode_navicode(code_name, code)
    local name_bytes = {0, 0, 0, 0}

    for i = 1, #code_name do
        local c = code_name:sub(i,i)
        name_bytes[i] = data.char_table[c]
    end

    code = code:gsub("-", "")

    local pass_bytes = {}
    for i = 1, 24 do
        pass_bytes[i] = data.pass_chars:find(code:sub(i,i)) - 1
    end

    local dat = {}
    for i = 14, 0, -1 do
        local b = 0
        for j = 24, 1, -1 do
            local v = pass_bytes[j] + b * 36
            pass_bytes[j] = v >> 8
            b = v & 0xFF
        end
        dat[i] = b
    end
	
	local sum = 0
	for i = 0,13 do
		sum = sum + dat[i]
	end
	if sum ~= dat[14] then return nil end

    for i = 0, 13 do
        dat[i] = dat[i] ~ name_bytes[(i & 3) + 1]
    end
    dat = utils.shift(dat, name_bytes[2] + name_bytes[4])

    for i = 0, 13 do
        dat[i] = dat[i] ~ name_bytes[(i & 3) + 1]
    end
    dat = utils.unshift(dat, name_bytes[1] + name_bytes[3])

    return dat
end

function utils.encode_navicode(code_name, deck)
	if deck == nil or code_name == nil then return nil end
	local name_bytes = {0, 0, 0, 0}

    for i = 1, #code_name do
        local c = code_name:sub(i,i)
        name_bytes[i] = data.char_table[c]
    end
	
	local dat = {}
	for i = 0,13 do dat[i] = tonumber(deck[i]) end
	
	dat = utils.shift(dat, name_bytes[1] + name_bytes[3])
	for i = 0,13 do
		dat[i] = dat[i] ~ name_bytes[(i & 3) + 1]
	end
	dat = utils.unshift(dat, name_bytes[2] + name_bytes[4])
	
	local sum = 0
	dat[14] = 0
	
	for i = 0,13 do
		sum = sum + dat[i]
	end
	dat[14] = -sum & 0xFF
	
	for i = 0,13 do
		dat[i] = dat[i] ~ name_bytes[(i & 3) + 1]
	end
	
	local pass_bytes = {}
	for i = 1,24 do
		local b = 0
        for j = 0,14 do
			local v = dat[j] | (b << 8)
			dat[j] = math.floor(v / 36)
			b = v % 36
        end
		pass_bytes[i] = b
    end
	
	local code = ""
	for i = 1, 24 do
		for v = 0,#data.pass_chars do
			if v == pass_bytes[i] then
				code = code .. data.pass_chars:sub(v+1,v+1)
				if i % 4 == 0 and i < 24 then code = code .. "-" end
				break
			end
		end
    end
	
	return code
end

function utils.shift(dat, bits)
    local u = (bits >> 3) & 0xF
    local l = bits & 0x7

    local r = {}
    for i = 0, 13 do
        local magic1 = (dat[(i + u ) % 14] << l) & 0xFF
        local magic2 = (dat[(i + u + 1) % 14] >> (8 - l)) & 0xFF
        r[i] = magic1 | magic2
    end

    return r
end

function utils.unshift(dat, bits)
    if bits ~= 0 then
        local data2 = {}
        for i = 0, 13 do
            data2[(i + 2) % 14] = dat[i]
        end
        dat = data2
    end
    return utils.shift(dat, -1 * bits)
end

return utils