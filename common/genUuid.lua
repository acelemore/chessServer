local uuid = {}

function uuid.gen()
	local template ="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	d = io.open("/dev/urandom", "r"):read(4)
	math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
	return string.gsub(template, "x", function (c)
      	local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
		end)
end

return uuid
