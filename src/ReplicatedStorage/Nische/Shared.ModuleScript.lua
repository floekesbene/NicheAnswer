-- Gemeinsame Konfiguration für Server und Client
local Shared = {}

Shared.Config = {
	ROUNDS = 5,               -- Prompts pro Match
	ROUND_TIME = 25,          -- Sekunden pro Prompt
	HARD_ROUND_TIME = 20,     -- Sekunden im Schweren Modus
	WRONG_PENALTY = 3,        -- Sekunden Abzug bei falscher Antwort
	REVEAL_TIME = 6,          -- Sekunden Auflösung nach jeder Runde
	START_COUNTDOWN = 4,      -- Countdown wenn Tisch voll ist
	HARD_REQUIRED_WINS = 10,  -- Siege für den Schweren Modus
	COINS_WIN = 70,
	COINS_LOSS = 30,
	COINS_DRAW = 50,
	SOLO_AIR = 45,            -- Start-Luft im Solo-Modus
	SOLO_WRONG = 2,           -- Luftabzug bei falscher Antwort (Solo)
	SOLO_SKIP = 5,            -- Luftabzug beim Überspringen (Solo)
	METERS_PER_POINT = 4,
	-- Schwierigkeit pro Runde (1 leicht, 2 mittel, 3 schwer)
	MATCH_DIFFICULTY = { 1, 1, 2, 2, 3 },
	HARD_DIFFICULTY  = { 2, 3, 3, 3, 3 },
	PARTY_DIFFICULTY = { 1, 2, 2, 3, 3 },
}

-- Seltenheitsstufen
Shared.Tiers = {
	[1] = { de = "PLANKTON",    en = "PLANKTON",   points = 10,  iq = -1, air = 8,  color = Color3.fromRGB(150, 170, 190) },
	[2] = { de = "ZU CLEVER",   en = "TOO CLEVER", points = 15,  iq = 1,  air = 9,  color = Color3.fromRGB(120, 230, 170) },
	[3] = { de = "SCHWARM",     en = "SCHOOL",     points = 30,  iq = 2,  air = 10, color = Color3.fromRGB(96, 200, 255) },
	[4] = { de = "SELTEN",      en = "RARE",       points = 60,  iq = 4,  air = 11, color = Color3.fromRGB(190, 130, 255) },
	[5] = { de = "TIEFSEE",     en = "DEEP CUT",   points = 85,  iq = 6,  air = 12, color = Color3.fromRGB(255, 150, 70) },
	[6] = { de = "DIE NISCHE!", en = "THE NICHE!", points = 100, iq = 10, air = 16, color = Color3.fromRGB(255, 214, 70) },
}

Shared.Difficulty = {
	[1] = { de = "LEICHT", en = "EASY",   color = Color3.fromRGB(110, 240, 150) },
	[2] = { de = "MITTEL", en = "MEDIUM", color = Color3.fromRGB(255, 200, 80) },
	[3] = { de = "SCHWER", en = "HARD",   color = Color3.fromRGB(255, 84, 132) },
}

Shared.Categories = {
	alles = { de = "Alles",       en = "Everything",  color = Color3.fromRGB(235, 240, 250) },
	geo   = { de = "Geographie",  en = "Geography",   color = Color3.fromRGB(90, 230, 140) },
	tiere = { de = "Tiere",       en = "Animals",     color = Color3.fromRGB(255, 200, 70) },
	essen = { de = "Essen",       en = "Food",        color = Color3.fromRGB(255, 110, 110) },
	games = { de = "Videospiele", en = "Video Games", color = Color3.fromRGB(110, 200, 255) },
	sport = { de = "Sport",       en = "Sports",      color = Color3.fromRGB(255, 150, 60) },
}

-- Tiefenzonen (Deko am Rand beim Tauchen)
Shared.Zones = {
	{ m = 40,    de = "das Licht wird schwächer",          en = "light begins to fade" },
	{ m = 200,   de = "hier endet das meiste Sonnenlicht", en = "most sunlight stops here" },
	{ m = 332,   de = "tiefster Tauchgang mit Flasche",     en = "deepest scuba dive ever" },
	{ m = 1000,  de = "Mitternachtszone – kein Licht mehr", en = "midnight zone – no light left" },
	{ m = 2000,  de = "Pottwale jagen hier unten",          en = "sperm whales hunt down here" },
	{ m = 3800,  de = "Wrack der Titanic",                  en = "wreck of the Titanic" },
	{ m = 6000,  de = "Beginn der Tiefseegräben",           en = "the trenches begin" },
	{ m = 10935, de = "Marianengraben – ganz unten",        en = "Mariana Trench – the bottom" },
}

Shared.Text = {
	de = {
		quickPlay = "QUICK PLAY", soloPlay = "SOLO PLAY",
		quickSub = "1 gegen 1 · 5 Prompts", soloSub = "endloser Tauchgang",
		coins = "COINS", wins = "SIEGE", iq = "IQ", streak = "SERIE",
		depth = "TIEFE", score = "PUNKTE", record = "REKORD", air = "LUFT", opponent = "GEGNER", you = "DU",
		promptOf = "PROMPT %d VON %d", promptN = "PROMPT %d",
		sinkHint = "▼  seltene Antworten sinken tiefer  ▼",
		typeHere = "eine Antwort eintippen…", dive = "TAUCHEN",
		wrong = "×  nicht in der Liste   −%ds", waitingOthers = "warte auf die anderen…", answered = "%s hat geantwortet",
		noAnswer = "— keine Antwort —", nicheWas = "◆  Die Nische war:  %s", results = "RUNDE %d - ERGEBNIS",
		win = "GEWONNEN!", lose = "VERLOREN", draw = "UNENTSCHIEDEN", soloOver = "LUFT LEER!",
		continue = "WEITER", starting = "MATCH STARTET", newRecord = "NEUER REKORD!", ranking = "RANGLISTE",
		coinsGain = "+%d Coins", iqGain = "IQ %+d",
		busy = "Du bist gerade in einem Spiel.", noTable = "Kein freier Tisch gefunden.",
		hardLocked = "Du brauchst %d Siege für den Schweren Modus!",
		leaveHint = "Springen = Tisch verlassen", hardMode = "SCHWERER MODUS", forfeit = "%s hat aufgegeben",
		skip = "überspringen  −%ds", vs = "gegen %s",
	},
	en = {
		quickPlay = "QUICK PLAY", soloPlay = "SOLO PLAY",
		quickSub = "1 vs 1 · 5 prompts", soloSub = "endless dive",
		coins = "COINS", wins = "WINS", iq = "IQ", streak = "STREAK",
		depth = "DEPTH", score = "SCORE", record = "BEST", air = "AIR", opponent = "OPPONENT", you = "YOU",
		promptOf = "PROMPT %d OF %d", promptN = "PROMPT %d",
		sinkHint = "▼  rarer answers sink deeper  ▼",
		typeHere = "type one answer…", dive = "DIVE",
		wrong = "×  not on the list   −%ds", waitingOthers = "waiting for the others…", answered = "%s answered",
		noAnswer = "— no answer —", nicheWas = "◆  The niche was:  %s", results = "ROUND %d - RESULTS",
		win = "YOU WIN!", lose = "YOU LOSE", draw = "DRAW", soloOver = "OUT OF AIR!",
		continue = "CONTINUE", starting = "MATCH STARTS", newRecord = "NEW RECORD!", ranking = "RANKING",
		coinsGain = "+%d Coins", iqGain = "IQ %+d",
		busy = "You are already in a game.", noTable = "No free table found.",
		hardLocked = "You need %d wins for Hard Mode!",
		leaveHint = "Jump = leave table", hardMode = "HARD MODE", forfeit = "%s forfeited",
		skip = "skip  −%ds", vs = "vs %s",
	},
}

-- Sprache aus der Roblox-Sprache des Spielers (de oder en, alles andere -> en)
function Shared.langOf(player)
	local id = string.lower(player and player.LocaleId or "en")
	if string.sub(id, 1, 2) == "de" then return "de" end
	return "en"
end

function Shared.t(lang, key, ...)
	local tbl = Shared.Text[lang] or Shared.Text.en
	local s = tbl[key] or Shared.Text.en[key] or key
	if select("#", ...) > 0 then return string.format(s, ...) end
	return s
end

return Shared
