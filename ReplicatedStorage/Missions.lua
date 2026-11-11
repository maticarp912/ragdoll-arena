-- Deterministic daily rotation; midnight Argentina (UTC-3), manually claimed rewards.
return {
 GemReward = 50, -- 11/11: respaldo; cada misión trae su gems (50 las fáciles, 100 las difíciles) DailyCount = 3, RotationStep = 3, SpinReward = 1,
 Order = { "wins", "knockdowns", "parries", "guards", "throws", "greatsword", "matches", "kills", "damage", "daggers", "kicks", "ringouts" },
 Data = {
 wins = { event = "Win", goal = 2, reward = 130, gems = 100 },
 knockdowns = { event = "Knockdown", goal = 5, reward = 110, gems = 50 },
 parries = { event = "Parry", goal = 3, reward = 100, gems = 50 },
 guards = { event = "GuardBreak", goal = 4, reward = 110, gems = 50 },
 throws = { event = "Throw", goal = 3, reward = 100, gems = 50 },
 greatsword = { event = "Match", weapon = "Greatsword", goal = 3, reward = 130, gems = 50 },
 matches = { event = "Match", goal = 3, reward = 100, gems = 50 },
 kills = { event = "Kill", goal = 4, reward = 120, gems = 100 },
 damage = { event = "Damage", goal = 800, reward = 120, gems = 100 },
 daggers = { event = "Match", weapon = "Dagger", goal = 3, reward = 130, gems = 50 },
 kicks = { event = "Kick", goal = 5, reward = 100, gems = 50 },
 ringouts = { event = "RingOut", goal = 3, reward = 120, gems = 100 },
 },
}
