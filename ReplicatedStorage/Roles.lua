-- Only server-configured IDs/names authorize a role. Empty privileged lists initially.
return {
 SecondsPerHour = 3600, ActionLength = 32, IdLength = 64, NewHours = 3, RefreshSeconds = 60, ResolveRetry = 60,
 Order = { "Owner", "Admin", "Mod", "Tester", "VIP", "Nuevo", "Player" },
 Data = {
  Owner = { priority = 100, color = Color3.fromRGB(255,210,100), ids = {}, names = {}, permissions = { Admin = true, Moderate = true, Debug = true, AllCosmetics = true } },
  Admin = { priority = 80, color = Color3.fromRGB(240,100,100), ids = {}, names = {}, permissions = { Admin = true, Moderate = true, Debug = true } },
  Mod = { priority = 60, color = Color3.fromRGB(110,180,240), ids = {}, names = {}, permissions = { Moderate = true } },
  Tester = { priority = 40, color = Color3.fromRGB(180,140,255), ids = {}, names = { "mateodoupa" }, permissions = { Debug = true } },
  VIP = { priority = 20, color = Color3.fromRGB(255,190,100), ids = {}, names = {}, permissions = {} },
  Nuevo = { priority = 10, color = Color3.fromRGB(120,220,150), ids = {}, names = {}, permissions = {} },
  Player = { priority = 0, color = Color3.fromRGB(220,220,220), ids = {}, names = {}, permissions = {} },
 },
 Admin = { Interval = 0.5, MaxCoins = 10000, MaxLevel = 100, HourCoins = 50000, HourActions = 100, AuditLimit = 200, Window = 3600, MuteSeconds = 600 },
}
