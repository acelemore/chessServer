local getString = {}

function getString.stdMsg(str)
	local len = string.len(str)
	local res = string.format("%04d|%s",len+5,str)
	return res
end

return getString
