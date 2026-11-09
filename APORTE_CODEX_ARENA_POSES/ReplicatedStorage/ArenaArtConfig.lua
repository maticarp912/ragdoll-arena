-- Apariencia local: no modifica colisiones ni reglas del derrumbe.
return {
	Enabled = true,
	MaxDistance = 420,
	UpdateInterval = 1 / 30,
	MinimumDepth = 12,
	PeakDepth = 65,
	RockInset = 0.3,
	RockColor = Color3.fromRGB(40, 39, 45),
	RockVariation = 12,
	DustColor = Color3.fromRGB(114, 105, 94),
	DustCount = 12,
	DustLifetime = NumberRange.new(0.6, 1.2),
}
