-- Deterministic daily rotation; midnight Argentina (UTC-3), manually claimed rewards.
return {
 DailyCount = 3, RotationStep = 3, SpinReward = 1,
 Order = { "wins", "knockdowns", "parries", "guards", "throws", "greatsword", "matches", "kills", "damage", "daggers", "kicks", "ringouts" },
 Data = {
 wins = { event = "Win", goal = 2, reward = 130 },
 knockdowns = { event = "Knockdown", goal = 5, reward = 110 },
 parries = { event = "Parry", goal = 3, reward = 100 },
 guards = { event = "GuardBreak", goal = 4, reward = 110 },
 throws = { event = "Throw", goal = 3, reward = 100 },
 greatsword = { event = "Match", weapon = "Greatsword", goal = 3, reward = 130 },
 matches = { event = "Match", goal = 3, reward = 100 },
 kills = { event = "Kill", goal = 4, reward = 120 },
 damage = { event = "Damage", goal = 800, reward = 120 },
 daggers = { event = "Match", weapon = "Dagger", goal = 3, reward = 130 },
 kicks = { event = "Kick", goal = 5, reward = 100 },
 ringouts = { event = "RingOut", goal = 3, reward = 120 },
 },
}
