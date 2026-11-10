-- Initial 0.2 tuning; XP is the progress inside the current level.
local P = {
 Schema = 1, MaxLevel = 100, EarlyLevels = 5, EarlyXP = 150, BaseXP = 150, LinearXP = 35, QuadraticXP = 2,
 Sources = { Match = 150, Win = 75, Kill = 25, Mission = 75 },
 EveryCoins = 5, EveryBox = 10, LevelCoins = 250, EarlyCoins = 50,
 Titles = { [25] = "cx.title.25", [50] = "cx.title.50", [75] = "cx.title.75", [100] = "cx.title.100" },
 Tick = 1, MaxGrant = 100000, MaxMultiplier = 3, MaxBoostSeconds = 86400,
 Mastery = {
  MaxLevel = 20, XPPerLevel = 200, MatchXP = 60, WinXP = 30, KillXP = 10,
  FinishLevel = 5, TrailLevel = 10, TitleLevel = 20,
  Finishes = { Sword = "Charcoal", Greatsword = "Frost", Dagger = "Gold", Rapier = "Charcoal", Mace = "Frost" },
  Trails = { Sword = "WeepingBlade", Greatsword = "BlackEmbers", Dagger = "BloodOath", Rapier = "PaleFracture", Mace = "BlackEmbers" },
 },
}
function P.required(level)
 if level >= P.MaxLevel then return 0 end
 if level < P.EarlyLevels then return P.EarlyXP end
 local step = level - P.EarlyLevels
 return P.BaseXP + step * P.LinearXP + step * step * P.QuadraticXP
end
return P
