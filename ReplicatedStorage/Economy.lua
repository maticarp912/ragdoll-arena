-- Stage 8 server/data configuration. Ranked progression is reserved for a future stage.
return {
 SessionTTL = 180, Autosave = 60, RetryDelay = 1, ReceiptLimit = 256,
 LoadAttempts = 5, LoadRetryDelay = 2, -- Claude: hasta ~20 s de reintentos al cargar el perfil antes de expulsar
 SaveDebounce = 6, -- Claude: opciones, idioma y auras se agrupan en un solo guardado cada 6 s (evita saturar el DataStore)
 Zero = 0, One = 1, DebugAmounts = { Small = 1000, Large = 10000 },
 Options = { MusicVolume = { default = 1, min = 0, max = 1, attr = "OptMusic" }, SfxVolume = { default = 1, min = 0, max = 1, attr = "OptSfx" }, CameraShake = { default = 1, min = 0, max = 1, attr = "OptShake" }, UiScale = { default = 1, min = 0.8, max = 1.2, attr = "OptUiScale" } },
 DaySeconds = 86400, LeaderboardInterval = 60, LeaderboardSize = 10,
 Match = { Win = 220, Lose = 65, Kill = 15, Knockdown = 5, CombatCap = 60, FirstWin = 120 },
 DebugUI = { Width = 0.5, Height = 34 },
}
