-- ModuleScript: ReplicatedStorage/LocaleGemini
-- Responsable: Gemini (etapa 8). Textos de interfaz nuevos, pantalla de carga, lemas de infusión y skins nuevas.
-- Las tres tablas (ES, EN, PT-BR) tienen exactamente las mismas claves y no repiten claves de LocaleES/EN/PT.

return {
	ES = {
		-- Skins nuevas (Fases 1 y 5)
		["skin.Requiem"] = "Réquiem Astado",
		["skinDesc.Requiem"] = "Acero fúnebre con guarda gótica de cuernos curvos y pomo en espina.",
		["skin.Maw02"] = "Vértebra del Abismo",
		["skinDesc.Maw02"] = "Maza de hueso ennegrecido y colmillos abiertos que rezuman brasa carmesí.",
		["skin.Maw03"] = "Fauces del Sepulcro",
		["skinDesc.Maw03"] = "Doble quijada de bestia ancestral atada con hierro de verdugo y vendas rúnicas.",
		["skin.Maw04"] = "Corona de Osario",
		["skinDesc.Maw04"] = "Cráneo astado y costillas petrificadas que aplastan cualquier escudo.",

		-- Pestañas y filtros de la Tienda (Fase 3)
		["ui.tab.Auras"] = "Auras",
		["ui.tab.Ranked"] = "Clasificatorias",
		["ui.aura.body"] = "Aura de cuerpo",
		["ui.aura.weapon"] = "Aura de arma",
		["ui.aura.unequip"] = "Quitar aura",
		["ui.aura.worldPreview"] = "Vista en vivo sobre el pedestal",
		["ui.filter.rarity"] = "Rareza: {value}",
		["ui.filter.ownership"] = "Estado: {value}",
		["ui.filter.auraKind"] = "Tipo: {value}",
		["ui.confirmBody"] = "Esta pieza se añadirá de inmediato a tu colección permanente.",
		["ui.gamepadHint"] = "A: Seleccionar · B: Volver",

		-- Lemas y afinidades para las tarjetas verticales de Infusiones (Agregado 9/11)
		["infusionMotto.Fire"] = "Furia Ígnea · Quema y quebranta el bloqueo",
		["infusionMotto.Lightning"] = "Tormenta · Velocidad y descargas que aturden",
		["infusionMotto.Ice"] = "Escarcha · Ralentiza y vuelve frágil al rival",
		["infusionMotto.Shadow"] = "Velo · Castigo letal desde las sombras",
		["ui.infusion.beats"] = "Ventaja contra: {target}",
		["ui.infusion.weak"] = "Débil contra: {target}",

		-- Clasificatorias (Próximamente)
		["ui.ranked.title"] = "CLASIFICATORIAS — PRÓXIMAMENTE",
		["ui.ranked.desc"] = "Las temporadas competitivas 1v1 y 2v2 con divisiones, emblemas y recompensas exclusivas llegarán en una próxima actualización.",
		["ui.ranked.rewards"] = "Divisiones de Hierro a Soberano del Ocaso · Recompensas de temporada",

		-- HUD y avisos de eliminaciones (Contrato C9)
		["ui.killfeed.kill"] = "{killer} eliminó a {victim}",
		["ui.killfeed.killSelf"] = "{victim} cayó al vacío",
		["ui.killfeed.knockdown"] = "{killer} derribó a {victim}",
		["ui.killfeed.knockdownSelf"] = "{victim} cayó derribado",

		-- Lobby, colas y misiones diarias (Contratos C3 y C8)
		["ui.queue.1v1"] = "Duelo 1v1",
		["ui.queue.2v2"] = "Arena 2v2",
		["ui.queue.leave"] = "Salir de la cola",
		["ui.queue.searching"] = "Buscando {mode} · {n}/{need}",
		["ui.lobby.missions"] = "Misiones",
		["ui.lobby.leaderboards"] = "Clasificación",
		["ui.lobby.ranked"] = "Clasificatorias",
		["ui.missions.title"] = "MISIONES DIARIAS",
		["ui.missions.resetIn"] = "Reinicio en {time}",
		["ui.missions.claim"] = "Reclamar",
		["ui.missions.claimed"] = "Reclamada",
		["ui.missions.inProgress"] = "En curso",
		["ui.missions.empty"] = "Cargando misiones diarias…",

		-- Tablas de clasificación (Contrato C7)
		["ui.board.Wins"] = "VICTORIAS",
		["ui.board.Kills"] = "ELIMINACIONES",
		["ui.board.Knockdowns"] = "DERRIBOS",
		["ui.board.Coins"] = "FORTUNA",
		["ui.board.empty"] = "Sin registros todavía",
		["ui.board.you"] = "TÚ",
		["ui.board.yourStats"] = "Tus totales: {wins} victorias · {kills} bajas · {knockdowns} derribos",

		-- Resumen de fin de partida (Contrato C9)
		["ui.match.victory"] = "¡VICTORIA!",
		["ui.match.defeat"] = "DERROTA",
		["ui.match.mode"] = "Modo {mode}",
		["ui.match.kills"] = "Eliminaciones",
		["ui.match.knockdowns"] = "Derribos",
		["ui.match.damage"] = "Daño infligido",
		["ui.match.coinsMatch"] = "Recompensa de partida",
		["ui.match.coinsMissions"] = "Misiones listas para reclamar",
		["ui.match.coinsTotal"] = "Total ganado",
		["ui.match.continue"] = "Continuar",

		-- Opciones y ajustes (Contrato C10)
		["ui.settings.tabAudio"] = "Audio y Vídeo",
		["ui.settings.tabControls"] = "Controles",
		["ui.settings.music"] = "Volumen de música",
		["ui.settings.sfx"] = "Efectos de sonido",
		["ui.settings.shake"] = "Sacudida de cámara",
		["ui.settings.uiScale"] = "Escala de interfaz",
		["ui.settings.saved"] = "Opciones aplicadas",

		-- Controles táctiles (Contrato C12)
		["ui.touch.attack"] = "ATAQUE",
		["ui.touch.heavy"] = "FUERTE",
		["ui.touch.block"] = "GUARDIA",
		["ui.touch.dodge"] = "ESQUIVA",
		["ui.touch.kick"] = "PATADA",
		["ui.touch.interact"] = "AGARRAR",
		["ui.touch.infuse"] = "INFUSIÓN",
		["ui.touch.lock"] = "FIJAR",
		["ui.touch.switch"] = "CAMBIAR",
		["ui.touch.menu"] = "ARMERÍA",

		-- Pantalla de carga (Contrato C13)
		["ui.loading.subtitle"] = "ARENA DE DUELOS Y FANTASÍA OSCURA",
		["ui.loading.preparing"] = "Forjando el acero… {pct}%",
		["ui.loading.ready"] = "Entrando a la ciudad…",
		["ui.loading.skip"] = "Omitir",
		["ui.loading.tip1"] = "CONSEJO: Un toque justo al bloquear ejecuta un Parry que abre la guardia rival.",
		["ui.loading.tip2"] = "CONSEJO: Cuando derribes a un enemigo, acércate y usa Agarrar para lanzarlo fuera de la arena.",
		["ui.loading.tip3"] = "CONSEJO: Las infusiones siguen un ciclo: Fuego vence a Rayo, Rayo a Hielo, Hielo a Sombra y Sombra a Fuego.",
		["ui.loading.tip4"] = "CONSEJO: Los ataques con destello rojo-dorado son imbloqueables: esquivá o respondé con un Parry preciso.",
	},

	EN = {
		-- Skins nuevas (Fases 1 y 5)
		["skin.Requiem"] = "Horned Requiem",
		["skinDesc.Requiem"] = "Funerary black steel with a curved-horn gothic guard and spiked pommel.",
		["skin.Maw02"] = "Abyssal Vertebra",
		["skinDesc.Maw02"] = "Blackened bone mace with gaping fangs that seep crimson embers.",
		["skin.Maw03"] = "Sepulcher Jaws",
		["skinDesc.Maw03"] = "Twin ancestral beast jaws bound in executioner iron and runic wraps.",
		["skin.Maw04"] = "Ossuary Crown",
		["skinDesc.Maw04"] = "Horned skull and petrified ribs forged to shatter any shield.",

		-- Pestañas y filtros de la Tienda (Fase 3)
		["ui.tab.Auras"] = "Auras",
		["ui.tab.Ranked"] = "Ranked",
		["ui.aura.body"] = "Body Aura",
		["ui.aura.weapon"] = "Weapon Aura",
		["ui.aura.unequip"] = "Unequip Aura",
		["ui.aura.worldPreview"] = "Live Pedestal Preview",
		["ui.filter.rarity"] = "Rarity: {value}",
		["ui.filter.ownership"] = "Status: {value}",
		["ui.filter.auraKind"] = "Type: {value}",
		["ui.confirmBody"] = "This piece will be immediately added to your permanent collection.",
		["ui.gamepadHint"] = "A: Select · B: Back",

		-- Lemas y afinidades para las tarjetas verticales de Infusiones (Agregado 9/11)
		["infusionMotto.Fire"] = "Fiery Wrath · Burns and pierces guard",
		["infusionMotto.Lightning"] = "Storm · Speed and stunning shocks",
		["infusionMotto.Ice"] = "Frost · Slows and shatters enemy resilience",
		["infusionMotto.Shadow"] = "Veil · Lethal strikes from the shadows",
		["ui.infusion.beats"] = "Strong vs: {target}",
		["ui.infusion.weak"] = "Weak vs: {target}",

		-- Clasificatorias (Próximamente)
		["ui.ranked.title"] = "RANKED — COMING SOON",
		["ui.ranked.desc"] = "Competitive 1v1 and 2v2 seasons with divisions, emblems, and exclusive rewards will arrive in an upcoming update.",
		["ui.ranked.rewards"] = "Iron to Dusk Sovereign Divisions · Seasonal Rewards",

		-- HUD y avisos de eliminaciones (Contrato C9)
		["ui.killfeed.kill"] = "{killer} eliminated {victim}",
		["ui.killfeed.killSelf"] = "{victim} fell into the void",
		["ui.killfeed.knockdown"] = "{killer} knocked down {victim}",
		["ui.killfeed.knockdownSelf"] = "{victim} was knocked down",

		-- Lobby, colas y misiones diarias (Contratos C3 y C8)
		["ui.queue.1v1"] = "1v1 Duel",
		["ui.queue.2v2"] = "2v2 Arena",
		["ui.queue.leave"] = "Leave Queue",
		["ui.queue.searching"] = "Searching {mode} · {n}/{need}",
		["ui.lobby.missions"] = "Missions",
		["ui.lobby.leaderboards"] = "Leaderboards",
		["ui.lobby.ranked"] = "Ranked",
		["ui.missions.title"] = "DAILY MISSIONS",
		["ui.missions.resetIn"] = "Resets in {time}",
		["ui.missions.claim"] = "Claim",
		["ui.missions.claimed"] = "Claimed",
		["ui.missions.inProgress"] = "In Progress",
		["ui.missions.empty"] = "Loading daily missions…",

		-- Tablas de clasificación (Contrato C7)
		["ui.board.Wins"] = "VICTORIES",
		["ui.board.Kills"] = "ELIMINATIONS",
		["ui.board.Knockdowns"] = "KNOCKDOWNS",
		["ui.board.Coins"] = "FORTUNE",
		["ui.board.empty"] = "No records yet",
		["ui.board.you"] = "YOU",
		["ui.board.yourStats"] = "Your totals: {wins} wins · {kills} kills · {knockdowns} knockdowns",

		-- Resumen de fin de partida (Contrato C9)
		["ui.match.victory"] = "VICTORY!",
		["ui.match.defeat"] = "DEFEAT",
		["ui.match.mode"] = "Mode {mode}",
		["ui.match.kills"] = "Eliminations",
		["ui.match.knockdowns"] = "Knockdowns",
		["ui.match.damage"] = "Damage Dealt",
		["ui.match.coinsMatch"] = "Match Reward",
		["ui.match.coinsMissions"] = "Missions Ready to Claim",
		["ui.match.coinsTotal"] = "Total Earned",
		["ui.match.continue"] = "Continue",

		-- Opciones y ajustes (Contrato C10)
		["ui.settings.tabAudio"] = "Audio & Video",
		["ui.settings.tabControls"] = "Controls",
		["ui.settings.music"] = "Music Volume",
		["ui.settings.sfx"] = "Sound Effects",
		["ui.settings.shake"] = "Camera Shake",
		["ui.settings.uiScale"] = "UI Scale",
		["ui.settings.saved"] = "Settings applied",

		-- Controles táctiles (Contrato C12)
		["ui.touch.attack"] = "ATTACK",
		["ui.touch.heavy"] = "HEAVY",
		["ui.touch.block"] = "GUARD",
		["ui.touch.dodge"] = "DODGE",
		["ui.touch.kick"] = "KICK",
		["ui.touch.interact"] = "GRAB",
		["ui.touch.infuse"] = "INFUSE",
		["ui.touch.lock"] = "LOCK",
		["ui.touch.switch"] = "TARGET",
		["ui.touch.menu"] = "ARMORY",

		-- Pantalla de carga (Contrato C13)
		["ui.loading.subtitle"] = "DARK FANTASY DUELING ARENA",
		["ui.loading.preparing"] = "Forging the steel… {pct}%",
		["ui.loading.ready"] = "Entering the city…",
		["ui.loading.skip"] = "Skip",
		["ui.loading.tip1"] = "TIP: Timing your block right before impact triggers a Parry that staggers the opponent.",
		["ui.loading.tip2"] = "TIP: When an enemy is knocked down, move in and Grab them to hurl them out of the arena.",
		["ui.loading.tip3"] = "TIP: Infusions follow a cycle: Fire beats Lightning, Lightning beats Ice, Ice beats Shadow, and Shadow beats Fire.",
		["ui.loading.tip4"] = "TIP: Attacks with a golden-red flash are unblockable—dodge away or answer with a precise Parry.",
	},

	["PT-BR"] = {
		-- Skins nuevas (Fases 1 y 5)
		["skin.Requiem"] = "Réquiem Cornudo",
		["skinDesc.Requiem"] = "Aço fúnebre com guarda gótica de chifres curvos e pomo em espinho.",
		["skin.Maw02"] = "Vértebra do Abismo",
		["skinDesc.Maw02"] = "Maça de osso enegrecido com presas abertas que exalam brasas carmesim.",
		["skin.Maw03"] = "Fauces do Sepulcro",
		["skinDesc.Maw03"] = "Dupla mandíbula de fera ancestral atada com ferro de carrasco e faixas rúnicas.",
		["skin.Maw04"] = "Coroa do Ossuário",
		["skinDesc.Maw04"] = "Crânio chifrudo e costelas petrificadas forjados para esmagar qualquer escudo.",

		-- Pestañas y filtros de la Tienda (Fase 3)
		["ui.tab.Auras"] = "Auras",
		["ui.tab.Ranked"] = "Ranqueadas",
		["ui.aura.body"] = "Aura de Corpo",
		["ui.aura.weapon"] = "Aura de Arma",
		["ui.aura.unequip"] = "Remover Aura",
		["ui.aura.worldPreview"] = "Prévia ao vivo no pedestal",
		["ui.filter.rarity"] = "Raridade: {value}",
		["ui.filter.ownership"] = "Estado: {value}",
		["ui.filter.auraKind"] = "Tipo: {value}",
		["ui.confirmBody"] = "Esta peça será adicionada imediatamente à sua coleção permanente.",
		["ui.gamepadHint"] = "A: Selecionar · B: Voltar",

		-- Lemas y afinidades para las tarjetas verticales de Infusiones (Agregado 9/11)
		["infusionMotto.Fire"] = "Fúria Ígnea · Queima e atravessa o bloqueio",
		["infusionMotto.Lightning"] = "Tempestade · Velocidade e descargas atordoantes",
		["infusionMotto.Ice"] = "Geada · Desacelera e torna o rival frágil",
		["infusionMotto.Shadow"] = "Véu · Punição letal a partir das sombras",
		["ui.infusion.beats"] = "Vantagem contra: {target}",
		["ui.infusion.weak"] = "Fraco contra: {target}",

		-- Clasificatorias (Próximamente)
		["ui.ranked.title"] = "RANQUEADAS — EM BREVE",
		["ui.ranked.desc"] = "As temporadas competitivas 1v1 e 2v2 com divisões, emblemas e recompensas exclusivas chegarão em uma próxima atualização.",
		["ui.ranked.rewards"] = "Divisões de Ferro a Soberano do Ocaso · Recompensas de Temporada",

		-- HUD y avisos de eliminaciones (Contrato C9)
		["ui.killfeed.kill"] = "{killer} eliminou {victim}",
		["ui.killfeed.killSelf"] = "{victim} caiu no vazio",
		["ui.killfeed.knockdown"] = "{killer} derrubou {victim}",
		["ui.killfeed.knockdownSelf"] = "{victim} caiu derrubado",

		-- Lobby, colas y misiones diarias (Contratos C3 y C8)
		["ui.queue.1v1"] = "Duelo 1v1",
		["ui.queue.2v2"] = "Arena 2v2",
		["ui.queue.leave"] = "Sair da Fila",
		["ui.queue.searching"] = "Procurando {mode} · {n}/{need}",
		["ui.lobby.missions"] = "Missões",
		["ui.lobby.leaderboards"] = "Classificação",
		["ui.lobby.ranked"] = "Ranqueadas",
		["ui.missions.title"] = "MISSÕES DIÁRIAS",
		["ui.missions.resetIn"] = "Reinicia em {time}",
		["ui.missions.claim"] = "Resgatar",
		["ui.missions.claimed"] = "Resgatada",
		["ui.missions.inProgress"] = "Em andamento",
		["ui.missions.empty"] = "Carregando missões diárias…",

		-- Tablas de clasificación (Contrato C7)
		["ui.board.Wins"] = "VITÓRIAS",
		["ui.board.Kills"] = "ELIMINAÇÕES",
		["ui.board.Knockdowns"] = "DERRUBADAS",
		["ui.board.Coins"] = "FORTUNA",
		["ui.board.empty"] = "Sem registros ainda",
		["ui.board.you"] = "VOCÊ",
		["ui.board.yourStats"] = "Seus totais: {wins} vitórias · {kills} abates · {knockdowns} derrubadas",

		-- Resumen de fin de partida (Contrato C9)
		["ui.match.victory"] = "VITÓRIA!",
		["ui.match.defeat"] = "DERROTA",
		["ui.match.mode"] = "Modo {mode}",
		["ui.match.kills"] = "Eliminações",
		["ui.match.knockdowns"] = "Derrubadas",
		["ui.match.damage"] = "Dano Causado",
		["ui.match.coinsMatch"] = "Recompensa da Partida",
		["ui.match.coinsMissions"] = "Missões Prontas para Resgatar",
		["ui.match.coinsTotal"] = "Total Ganho",
		["ui.match.continue"] = "Continuar",

		-- Opciones y ajustes (Contrato C10)
		["ui.settings.tabAudio"] = "Áudio e Vídeo",
		["ui.settings.tabControls"] = "Controles",
		["ui.settings.music"] = "Volume da Música",
		["ui.settings.sfx"] = "Efeitos Sonoros",
		["ui.settings.shake"] = "Tremor de Câmera",
		["ui.settings.uiScale"] = "Escala da Interface",
		["ui.settings.saved"] = "Opções aplicadas",

		-- Controles táctiles (Contrato C12)
		["ui.touch.attack"] = "ATAQUE",
		["ui.touch.heavy"] = "FORTE",
		["ui.touch.block"] = "GUARDA",
		["ui.touch.dodge"] = "ESQUIVA",
		["ui.touch.kick"] = "CHUTE",
		["ui.touch.interact"] = "AGARRAR",
		["ui.touch.infuse"] = "INFUSÃO",
		["ui.touch.lock"] = "MIRAR",
		["ui.touch.switch"] = "ALVO",
		["ui.touch.menu"] = "ARSENAL",

		-- Pantalla de carga (Contrato C13)
		["ui.loading.subtitle"] = "ARENA DE DUELOS E FANTASIA SOMBRIA",
		["ui.loading.preparing"] = "Forjando o aço… {pct}%",
		["ui.loading.ready"] = "Entrando na cidade…",
		["ui.loading.skip"] = "Pular",
		["ui.loading.tip1"] = "DICA: Bloquear no instante exato executa um Parry que abre a guarda rival.",
		["ui.loading.tip2"] = "DICA: Ao derrubar um inimigo, aproxime-se e use Agarrar para lançá-lo para fora da arena.",
		["ui.loading.tip3"] = "DICA: As infusões seguem um ciclo: Fogo vence Raio, Raio vence Gelo, Gelo vence Sombra e Sombra vence Fogo.",
		["ui.loading.tip4"] = "DICA: Ataques com brilho vermelho-dourado são indefensáveis: esquive ou responda com um Parry preciso.",
	},
}
