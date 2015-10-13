local status = { [3] = false, [4] = false, [5] = false, [6] = false }
local x = { a = 1, b = 2, c = 3 }
print(status)
-- local k, v
for k in pairs(status) do
	local g
	print (k)
	if (k == 3) then
		g = k + 1
		print(g)
		break
	end

	
end

for k in pairs(x) do
	print (k)
end