-- ModuleScript: ReplicatedStorage/Format
-- 11/11/2026: formato de números para la interfaz.
-- Format.percent(fraccion, idioma) → probabilidad con 3 cifras como máximo y sin ceros a la derecha:
--   0.005 → "0,5 %" · 0.032 → "3,2 %" · 0.125 → "12,5 %" · 0.3333 → "33,3 %" · 1 → "100 %"
--   En inglés usa punto ("3.2%"). Nunca muestra "0 %" para algo posible: lo mínimo es "<0,01 %".

local Format = {}

local function strip(s)
	if string.find(s, "%.") then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, "%.$", "")
	end
	return s
end

function Format.number3(v)
	if v ~= v or v == math.huge then return "0" end
	if v == 0 then return "0" end
	local intDigits = math.floor(math.log10(math.abs(v))) + 1
	local decimals = math.clamp(3 - intDigits, 0, 4)
	return strip(string.format("%." .. decimals .. "f", v))
end

function Format.percent(fraction, lang)
	local v = (tonumber(fraction) or 0) * 100
	local text
	if v <= 0 then
		text = "0"
	elseif v < 0.01 then
		text = "<0.01"
	else
		text = Format.number3(v)
	end
	if lang == "EN" then return text .. "%" end
	return string.gsub(text, "%.", ",") .. " %"
end

return Format
