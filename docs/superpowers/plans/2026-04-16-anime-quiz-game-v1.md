# Anime Personality Quiz Game — V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a UI-driven Roblox quiz game that matches players to one of 10 anime personality archetypes through 24 weighted questions, with timer-gated results, monetization, persistent collections, and social features.

**Architecture:** Rojo-managed project synced to Roblox Studio. Client handles all UI rendering and screen transitions. Server owns scoring, persistence, monetization, and leaderboard state. Shared ModuleScripts in ReplicatedStorage hold question/archetype data. RemoteEvents bridge client-server communication.

**Tech Stack:** Luau (Roblox), Rojo (file sync), Roblox DataStoreService, MarketplaceService, AdService

**Important:** This project uses Rojo for filesystem-based development. After writing files, you sync them into Roblox Studio using `rojo serve` and the Rojo Studio plugin. Asset IDs for images and sounds must be uploaded via Roblox Studio or Creator Dashboard and their IDs pasted into the code where indicated with `ASSET_ID_HERE` placeholders — these cannot be created from code.

---

## File Structure

```
anime-quiz-game/
├── default.project.json              -- Rojo project config
├── src/
│   ├── shared/                        -- ReplicatedStorage
│   │   ├── Archetypes.luau            -- 10 archetype definitions
│   │   ├── QuestionBank.luau          -- 24 questions with weight mappings
│   │   └── Remotes.luau               -- RemoteEvent/Function declarations
│   ├── server/                        -- ServerScriptService
│   │   ├── QuizServer.server.luau     -- Scoring engine + answer handling
│   │   ├── DataStoreManager.luau      -- Player data save/load module
│   │   ├── MonetizationHandler.server.luau -- DevProduct + GamePass + Ad processing
│   │   └── LeaderboardManager.server.luau  -- Server archetype tracking + overhead tags
│   └── client/                        -- StarterPlayerScripts
│       ├── UIController.client.luau   -- Screen transitions + main UI orchestrator
│       ├── QuizUI.luau                -- Quiz screen rendering + answer input
│       ├── TimerUI.luau               -- Timer screen + skip buttons
│       ├── ResultsUI.luau             -- Shareable result card
│       ├── CollectionUI.luau          -- Archetype collection grid
│       ├── LeaderboardUI.luau         -- Server leaderboard side panel
├── docs/
│   └── superpowers/
│       ├── specs/
│       │   └── 2026-04-15-anime-quiz-game-design.md
│       └── plans/
│           └── 2026-04-16-anime-quiz-game-v1.md
```

---

## Task 1: Project Setup & Rojo Config

**Files:**
- Create: `default.project.json`
- Create: `src/shared/Remotes.luau`

- [ ] **Step 1: Initialize git repo**

```bash
cd /c/Users/dhruv/projects/anime-quiz-game
git init
git add docs/
git commit -m "docs: add design spec and implementation plan"
```

- [ ] **Step 2: Create Rojo project config**

Create `default.project.json`:

```json
{
  "name": "AnimeQuizGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": {
          "$path": "src/client"
        }
      }
    }
  }
}
```

- [ ] **Step 3: Create Remotes module**

Create `src/shared/Remotes.luau`:

```luau
-- Declares all RemoteEvents and RemoteFunctions used for client-server communication.
-- Both client and server require this module to get references by name.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local remoteEvents = {
	"SubmitAnswer",       -- Client -> Server: player picked an answer
	"QuizResult",         -- Server -> Client: final archetype result
	"TimerSkipGranted",   -- Server -> Client: 5 minutes removed from timer
	"LeaderboardUpdate",  -- Server -> Client: updated archetype list for all players
	"RequestLeaderboard", -- Client -> Server: ask for current leaderboard state
}

local remoteFunctions = {
	"LoadPlayerData",     -- Client -> Server: get saved collection + current archetype
	"StartQuiz",          -- Client -> Server: get shuffled question order, returns question indices
	"CheckGamePass",      -- Client -> Server: check if player owns Instant Unlock
}

function Remotes.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	for _, name in remoteEvents do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	for _, name in remoteFunctions do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
end

function Remotes.get(name: string): Instance
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name)
end

return Remotes
```

- [ ] **Step 4: Create directory structure**

```bash
mkdir -p src/shared src/server src/client
```

- [ ] **Step 5: Verify Rojo can read the project**

```bash
rojo serve
```

Expected: Rojo starts and prints the project name "AnimeQuizGame". Stop the server after confirming. If `rojo` is not installed, install with: `aftman add rojo-rbx/rojo` or download from the Rojo GitHub releases page.

- [ ] **Step 6: Commit**

```bash
git add default.project.json src/shared/Remotes.luau
git commit -m "feat: project setup with Rojo config and remote declarations"
```

---

## Task 2: Archetype Definitions

**Files:**
- Create: `src/shared/Archetypes.luau`

- [ ] **Step 1: Create Archetypes module**

Create `src/shared/Archetypes.luau`:

```luau
export type Archetype = {
	id: string,
	name: string,
	description: string,
	examples: { string },
}

local Archetypes: { Archetype } = {
	{
		id = "hot_headed_hero",
		name = "The Hot-Headed Hero",
		description = "You charge in headfirst and figure it out along the way. Your passion is your greatest weapon — when you believe in something, nothing can stop you. You might be reckless, but your fire inspires everyone around you.",
		examples = { "Naruto", "Goku", "Asta" },
	},
	{
		id = "cool_strategist",
		name = "The Cool Strategist",
		description = "You see ten moves ahead while everyone else is stuck on one. Calm under pressure, you prefer brains over brawn. People might mistake your composure for coldness, but you care deeply — you just show it through action.",
		examples = { "Lelouch", "Shikamaru", "Light" },
	},
	{
		id = "lone_wolf",
		name = "The Lone Wolf",
		description = "You walk your own path and don't need anyone's approval. Independent and self-reliant, you've learned to depend on yourself. Behind the tough exterior, there's someone who protects what matters most — silently.",
		examples = { "Sasuke", "Levi", "Guts" },
	},
	{
		id = "gentle_protector",
		name = "The Gentle Protector",
		description = "Your kindness isn't weakness — it's your greatest strength. You fight not because you love battle, but because you love the people behind you. You see the good in everyone, even your enemies.",
		examples = { "Tanjiro", "Deku", "Tohru" },
	},
	{
		id = "chaotic_wildcard",
		name = "The Chaotic Wildcard",
		description = "Nobody can predict your next move — not even you sometimes. You live for excitement and thrive in chaos. Your unpredictability makes you dangerous, but also endlessly entertaining.",
		examples = { "Gojo", "Hisoka", "Denji" },
	},
	{
		id = "silent_powerhouse",
		name = "The Silent Powerhouse",
		description = "You don't talk about what you can do — you just do it. Your strength speaks for itself. While others boast, you stay quiet, and when you finally act, everyone watches in awe.",
		examples = { "Saitama", "Jotaro", "Mob" },
	},
	{
		id = "loyal_companion",
		name = "The Loyal Companion",
		description = "You'd walk through fire for the people you care about. Loyalty isn't just a word to you — it's your defining trait. You might doubt yourself, but when your friends need you, you become unstoppable.",
		examples = { "Killua", "Zenitsu", "Chopper" },
	},
	{
		id = "wise_mentor",
		name = "The Wise Mentor",
		description = "You've seen things, learned things, and now you guide others with quiet confidence. You're laid-back on the surface but carry deep knowledge and experience. People come to you for answers — and you always deliver.",
		examples = { "Kakashi", "Urahara", "Shanks" },
	},
	{
		id = "rebel_with_a_cause",
		name = "The Rebel With a Cause",
		description = "You refuse to accept the world as it is. Rules that don't make sense? You break them. Systems that are unjust? You tear them down. Your rebellion isn't random — it's fueled by a vision only you can see.",
		examples = { "Eren", "Lelouch", "Vegeta" },
	},
	{
		id = "cheerful_optimist",
		name = "The Cheerful Optimist",
		description = "Your energy is infectious and your smile is a weapon. No matter how dark things get, you refuse to give up. You lift everyone around you just by being yourself — and that's your true superpower.",
		examples = { "Luffy", "Anya", "Hinata Shoyo" },
	},
}

local ArchetypesModule = {}

ArchetypesModule.list = Archetypes

function ArchetypesModule.getById(id: string): Archetype?
	for _, archetype in Archetypes do
		if archetype.id == id then
			return archetype
		end
	end
	return nil
end

function ArchetypesModule.getIds(): { string }
	local ids = {}
	for _, archetype in Archetypes do
		table.insert(ids, archetype.id)
	end
	return ids
end

return ArchetypesModule
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/Archetypes.luau
git commit -m "feat: add 10 anime archetype definitions"
```

---

## Task 3: Question Bank

**Files:**
- Create: `src/shared/QuestionBank.luau`

- [ ] **Step 1: Create QuestionBank module**

Create `src/shared/QuestionBank.luau`. Each question has 4 answers, and each answer maps to weighted archetype scores. Weights are sparse — only archetypes relevant to that answer are listed.

```luau
-- Archetype ID shorthand used in weights:
-- hh = hot_headed_hero, cs = cool_strategist, lw = lone_wolf,
-- gp = gentle_protector, cw = chaotic_wildcard, sp = silent_powerhouse,
-- lc = loyal_companion, wm = wise_mentor, rc = rebel_with_a_cause,
-- co = cheerful_optimist

export type Answer = {
	text: string,
	weights: { [string]: number },
}

export type Question = {
	text: string,
	kind: "scenario" | "preference",
	answers: { Answer },
}

local Questions: { Question } = {
	-- SCENARIO QUESTIONS (1-12)
	{
		text = "You see a friend being bullied. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Rush in and confront the bully immediately", weights = { hot_headed_hero = 3, rebel_with_a_cause = 1 } },
			{ text = "Step in calmly and defuse the situation with words", weights = { wise_mentor = 3, gentle_protector = 1 } },
			{ text = "Stand beside your friend silently — your presence alone is enough", weights = { silent_powerhouse = 2, loyal_companion = 2 } },
			{ text = "Come up with a plan to get the bully in trouble later", weights = { cool_strategist = 3, rebel_with_a_cause = 1 } },
		},
	},
	{
		text = "You're lost in an unfamiliar city at night. What's your move?",
		kind = "scenario",
		answers = {
			{ text = "Explore! This is an adventure!", weights = { cheerful_optimist = 3, chaotic_wildcard = 1 } },
			{ text = "Find a quiet spot and figure out a route on your own", weights = { lone_wolf = 3, cool_strategist = 1 } },
			{ text = "Ask a stranger for directions with a smile", weights = { gentle_protector = 2, cheerful_optimist = 2 } },
			{ text = "Doesn't matter — you'll handle whatever comes", weights = { silent_powerhouse = 3, hot_headed_hero = 1 } },
		},
	},
	{
		text = "Your team is losing badly in a competition. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Fire everyone up with a passionate speech", weights = { hot_headed_hero = 2, cheerful_optimist = 2 } },
			{ text = "Quietly analyze what's going wrong and adjust your strategy", weights = { cool_strategist = 3, wise_mentor = 1 } },
			{ text = "Take matters into your own hands and carry the team", weights = { silent_powerhouse = 2, lone_wolf = 2 } },
			{ text = "Do something completely unexpected to throw off the opponents", weights = { chaotic_wildcard = 3, rebel_with_a_cause = 1 } },
		},
	},
	{
		text = "A stranger asks you for a huge favor. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Help them without hesitation — everyone deserves kindness", weights = { gentle_protector = 3, cheerful_optimist = 1 } },
			{ text = "Figure out their real motive first", weights = { cool_strategist = 2, wise_mentor = 2 } },
			{ text = "Help only if your gut says they're genuine", weights = { loyal_companion = 2, wise_mentor = 1, silent_powerhouse = 1 } },
			{ text = "Ignore them — you've got your own problems", weights = { lone_wolf = 3, rebel_with_a_cause = 1 } },
		},
	},
	{
		text = "You discover a rule at school/work that's completely unfair. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Break the rule publicly and dare them to stop you", weights = { rebel_with_a_cause = 3, hot_headed_hero = 1 } },
			{ text = "Organize others to push back against it together", weights = { wise_mentor = 2, rebel_with_a_cause = 2 } },
			{ text = "Ignore it and do your own thing anyway", weights = { lone_wolf = 2, chaotic_wildcard = 2 } },
			{ text = "Follow it for now but look for a clever way around it", weights = { cool_strategist = 3, silent_powerhouse = 1 } },
		},
	},
	{
		text = "Your best friend betrays your trust. How do you react?",
		kind = "scenario",
		answers = {
			{ text = "Confront them immediately — you need answers NOW", weights = { hot_headed_hero = 3, loyal_companion = 1 } },
			{ text = "Walk away silently. They're dead to you.", weights = { lone_wolf = 3, silent_powerhouse = 1 } },
			{ text = "Try to understand why they did it before judging", weights = { gentle_protector = 2, wise_mentor = 2 } },
			{ text = "You're hurt, but you'd still help them if they needed it", weights = { loyal_companion = 3, cheerful_optimist = 1 } },
		},
	},
	{
		text = "You find a mysterious door that says 'DO NOT OPEN.' What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Open it immediately. Obviously.", weights = { chaotic_wildcard = 3, hot_headed_hero = 1 } },
			{ text = "Investigate the door — check for traps, listen for sounds", weights = { cool_strategist = 3, wise_mentor = 1 } },
			{ text = "Walk away. Not your problem.", weights = { lone_wolf = 2, silent_powerhouse = 2 } },
			{ text = "Find someone to open it with you — safety in numbers", weights = { loyal_companion = 2, gentle_protector = 2 } },
		},
	},
	{
		text = "You witness an argument between two friends. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Jump in and try to mediate — you hate seeing friends fight", weights = { gentle_protector = 3, loyal_companion = 1 } },
			{ text = "Let them work it out. They're adults.", weights = { lone_wolf = 2, wise_mentor = 2 } },
			{ text = "Pick a side — someone's clearly wrong here", weights = { hot_headed_hero = 2, rebel_with_a_cause = 2 } },
			{ text = "Crack a joke to break the tension", weights = { cheerful_optimist = 3, chaotic_wildcard = 1 } },
		},
	},
	{
		text = "You're given a leadership role you didn't ask for. How do you handle it?",
		kind = "scenario",
		answers = {
			{ text = "Step up and lead with everything you've got", weights = { hot_headed_hero = 2, rebel_with_a_cause = 2 } },
			{ text = "Lead quietly from behind — guide without commanding", weights = { wise_mentor = 3, silent_powerhouse = 1 } },
			{ text = "Delegate and build the best team possible", weights = { cool_strategist = 2, loyal_companion = 2 } },
			{ text = "Make it fun — if everyone's enjoying it, they'll follow naturally", weights = { cheerful_optimist = 3, chaotic_wildcard = 1 } },
		},
	},
	{
		text = "You have one day left before a huge deadline and you're behind. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Pull an all-nighter fueled by pure determination", weights = { hot_headed_hero = 2, loyal_companion = 2 } },
			{ text = "Prioritize ruthlessly — cut what doesn't matter", weights = { cool_strategist = 3, wise_mentor = 1 } },
			{ text = "Stay calm. You'll get done what you get done.", weights = { silent_powerhouse = 3, lone_wolf = 1 } },
			{ text = "Throw out the plan and improvise something creative", weights = { chaotic_wildcard = 3, cheerful_optimist = 1 } },
		},
	},
	{
		text = "Someone you barely know is crying alone. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Sit next to them quietly — just being there is enough", weights = { gentle_protector = 3, silent_powerhouse = 1 } },
			{ text = "Ask what's wrong and try to cheer them up", weights = { cheerful_optimist = 3, loyal_companion = 1 } },
			{ text = "Give them space — crying is personal", weights = { lone_wolf = 2, wise_mentor = 2 } },
			{ text = "Find out who made them cry and handle it", weights = { hot_headed_hero = 2, rebel_with_a_cause = 2 } },
		},
	},
	{
		text = "You gain a superpower but must keep it secret. What do you do?",
		kind = "scenario",
		answers = {
			{ text = "Use it secretly to help people whenever you can", weights = { gentle_protector = 2, silent_powerhouse = 2 } },
			{ text = "Test its limits — you need to know exactly what you can do", weights = { cool_strategist = 2, chaotic_wildcard = 2 } },
			{ text = "Tell your closest friend — you can't keep this alone", weights = { loyal_companion = 3, cheerful_optimist = 1 } },
			{ text = "Use it to change the things that are broken in the world", weights = { rebel_with_a_cause = 3, wise_mentor = 1 } },
		},
	},

	-- PREFERENCE QUESTIONS (13-24)
	{
		text = "Pick your ideal weapon:",
		kind = "preference",
		answers = {
			{ text = "A massive flaming sword", weights = { hot_headed_hero = 3, chaotic_wildcard = 1 } },
			{ text = "A precise sniper rifle", weights = { cool_strategist = 2, lone_wolf = 2 } },
			{ text = "Your bare fists", weights = { silent_powerhouse = 3, hot_headed_hero = 1 } },
			{ text = "A shield that protects everyone around you", weights = { gentle_protector = 3, loyal_companion = 1 } },
		},
	},
	{
		text = "Choose your element:",
		kind = "preference",
		answers = {
			{ text = "Fire — raw power and passion", weights = { hot_headed_hero = 3, rebel_with_a_cause = 1 } },
			{ text = "Shadow — mystery and precision", weights = { lone_wolf = 2, cool_strategist = 2 } },
			{ text = "Lightning — speed and unpredictability", weights = { chaotic_wildcard = 3, silent_powerhouse = 1 } },
			{ text = "Light — hope and warmth", weights = { cheerful_optimist = 2, gentle_protector = 2 } },
		},
	},
	{
		text = "What's your role in a friend group?",
		kind = "preference",
		answers = {
			{ text = "The one who plans everything", weights = { cool_strategist = 3, wise_mentor = 1 } },
			{ text = "The one who hypes everyone up", weights = { cheerful_optimist = 3, hot_headed_hero = 1 } },
			{ text = "The one who shows up when it matters most", weights = { loyal_companion = 2, silent_powerhouse = 2 } },
			{ text = "The wildcard no one can predict", weights = { chaotic_wildcard = 3, rebel_with_a_cause = 1 } },
		},
	},
	{
		text = "Pick a place to live:",
		kind = "preference",
		answers = {
			{ text = "A mountain cabin — alone with nature", weights = { lone_wolf = 3, silent_powerhouse = 1 } },
			{ text = "A busy city full of people and energy", weights = { cheerful_optimist = 2, chaotic_wildcard = 2 } },
			{ text = "A cozy house with your closest friends nearby", weights = { loyal_companion = 3, gentle_protector = 1 } },
			{ text = "A hidden base where you run operations", weights = { cool_strategist = 2, rebel_with_a_cause = 2 } },
		},
	},
	{
		text = "What matters most to you?",
		kind = "preference",
		answers = {
			{ text = "Protecting the people I love", weights = { gentle_protector = 2, loyal_companion = 2 } },
			{ text = "Freedom to live on my own terms", weights = { rebel_with_a_cause = 2, lone_wolf = 2 } },
			{ text = "Getting stronger every single day", weights = { silent_powerhouse = 2, hot_headed_hero = 2 } },
			{ text = "Understanding the truth of the world", weights = { wise_mentor = 3, cool_strategist = 1 } },
		},
	},
	{
		text = "Pick your anime power-up moment:",
		kind = "preference",
		answers = {
			{ text = "Screaming as a new transformation unlocks", weights = { hot_headed_hero = 3, cheerful_optimist = 1 } },
			{ text = "A quiet glare as you reveal you were holding back the whole time", weights = { silent_powerhouse = 3, lone_wolf = 1 } },
			{ text = "Outsmarting the villain with a plan they never saw coming", weights = { cool_strategist = 3, wise_mentor = 1 } },
			{ text = "Going berserk to protect someone you love", weights = { loyal_companion = 2, gentle_protector = 2 } },
		},
	},
	{
		text = "Choose your fatal flaw:",
		kind = "preference",
		answers = {
			{ text = "Too stubborn — you never back down, even when you should", weights = { hot_headed_hero = 2, rebel_with_a_cause = 2 } },
			{ text = "Too distant — you push people away to protect yourself", weights = { lone_wolf = 3, silent_powerhouse = 1 } },
			{ text = "Too trusting — you see the best in everyone, even enemies", weights = { gentle_protector = 2, cheerful_optimist = 2 } },
			{ text = "Too reckless — you act before thinking", weights = { chaotic_wildcard = 3, hot_headed_hero = 1 } },
		},
	},
	{
		text = "What kind of anime would your life be?",
		kind = "preference",
		answers = {
			{ text = "Shonen — epic battles and endless training arcs", weights = { hot_headed_hero = 2, silent_powerhouse = 2 } },
			{ text = "Psychological thriller — mind games and plot twists", weights = { cool_strategist = 3, rebel_with_a_cause = 1 } },
			{ text = "Slice of life — wholesome moments with friends", weights = { cheerful_optimist = 2, loyal_companion = 2 } },
			{ text = "Dark fantasy — gritty world, high stakes, moral gray areas", weights = { lone_wolf = 2, chaotic_wildcard = 2 } },
		},
	},
	{
		text = "Pick a quote that resonates with you:",
		kind = "preference",
		answers = {
			{ text = "\"I'll surpass my limits right here, right now!\"", weights = { hot_headed_hero = 2, cheerful_optimist = 2 } },
			{ text = "\"The only one who can beat me is me.\"", weights = { silent_powerhouse = 2, lone_wolf = 2 } },
			{ text = "\"I will keep moving forward.\"", weights = { rebel_with_a_cause = 3, cool_strategist = 1 } },
			{ text = "\"If you don't take risks, you can't create a future.\"", weights = { chaotic_wildcard = 2, wise_mentor = 2 } },
		},
	},
	{
		text = "How do you handle fear?",
		kind = "preference",
		answers = {
			{ text = "I charge through it — fear is just fuel", weights = { hot_headed_hero = 3, rebel_with_a_cause = 1 } },
			{ text = "I analyze it — fear means I'm missing information", weights = { cool_strategist = 2, wise_mentor = 2 } },
			{ text = "I sit with it — everyone feels fear, it's okay", weights = { gentle_protector = 2, wise_mentor = 2 } },
			{ text = "I laugh at it — life's too short to be scared", weights = { chaotic_wildcard = 2, cheerful_optimist = 2 } },
		},
	},
	{
		text = "What's your training style?",
		kind = "preference",
		answers = {
			{ text = "Solo — push your limits alone in silence", weights = { lone_wolf = 2, silent_powerhouse = 2 } },
			{ text = "With a rival — competition makes you sharper", weights = { hot_headed_hero = 2, rebel_with_a_cause = 2 } },
			{ text = "With a mentor — learn from someone who's been there", weights = { wise_mentor = 3, loyal_companion = 1 } },
			{ text = "With friends — the journey is better together", weights = { cheerful_optimist = 2, loyal_companion = 2 } },
		},
	},
	{
		text = "Pick your victory celebration:",
		kind = "preference",
		answers = {
			{ text = "A massive party with everyone you know", weights = { cheerful_optimist = 3, loyal_companion = 1 } },
			{ text = "A quiet nod. The win speaks for itself.", weights = { silent_powerhouse = 3, lone_wolf = 1 } },
			{ text = "Share the credit with your team — you couldn't have done it alone", weights = { gentle_protector = 2, loyal_companion = 2 } },
			{ text = "Already thinking about the next challenge", weights = { cool_strategist = 2, rebel_with_a_cause = 2 } },
		},
	},
}

local QuestionBank = {}

QuestionBank.questions = Questions

function QuestionBank.getShuffledIndices(): { number }
	local indices = {}
	for i = 1, #Questions do
		table.insert(indices, i)
	end
	-- Fisher-Yates shuffle
	for i = #indices, 2, -1 do
		local j = math.random(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end
	return indices
end

function QuestionBank.getQuestion(index: number): Question
	return Questions[index]
end

function QuestionBank.getTotalQuestions(): number
	return #Questions
end

return QuestionBank
```

- [ ] **Step 2: Commit**

```bash
git add src/shared/QuestionBank.luau
git commit -m "feat: add 24-question bank with archetype weight mappings"
```

---

## Task 4: Server-Side Quiz Scoring

**Files:**
- Create: `src/server/QuizServer.server.luau`

- [ ] **Step 1: Create the quiz scoring server script**

Create `src/server/QuizServer.server.luau`:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

-- Initialize remotes (only one server script should call this)
Remotes.init()

-- Track each player's active quiz session
-- Key: Player, Value: { questionOrder: {number}, answers: {number}, expectedIndex: number }
local activeSessions: { [Player]: { questionOrder: { number }, answers: { number }, expectedIndex: number } } = {}

-- Handle StartQuiz: create a new session with shuffled question order
local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
startQuizRemote.OnServerInvoke = function(player: Player)
	local order = QuestionBank.getShuffledIndices()
	activeSessions[player] = {
		questionOrder = order,
		answers = {},
		expectedIndex = 1,
	}
	return order
end

-- Handle SubmitAnswer: record the player's answer for the current question
local submitAnswerRemote = Remotes.get("SubmitAnswer") :: RemoteEvent
submitAnswerRemote.OnServerEvent:Connect(function(player: Player, answerIndex: number)
	local session = activeSessions[player]
	if not session then
		return
	end

	-- Validate answer index (1-4)
	if type(answerIndex) ~= "number" or answerIndex < 1 or answerIndex > 4 or answerIndex ~= math.floor(answerIndex) then
		return
	end

	-- Only accept the next expected answer (prevents duplicate/out-of-order submissions)
	if session.expectedIndex > QuestionBank.getTotalQuestions() then
		return
	end

	table.insert(session.answers, answerIndex)
	session.expectedIndex += 1

	-- If all questions answered, calculate result
	if #session.answers == QuestionBank.getTotalQuestions() then
		local result = calculateResult(session)
		activeSessions[player] = nil

		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
	end
end)

function calculateResult(session: { questionOrder: { number }, answers: { number } }): string
	-- Accumulate scores for each archetype
	local scores: { [string]: number } = {}
	for _, id in Archetypes.getIds() do
		scores[id] = 0
	end

	for i, questionIndex in session.questionOrder do
		local answerIndex = session.answers[i]
		if not answerIndex then
			break
		end

		local question = QuestionBank.getQuestion(questionIndex)
		local answer = question.answers[answerIndex]

		for archetypeId, weight in answer.weights do
			scores[archetypeId] = (scores[archetypeId] or 0) + weight
		end
	end

	-- Find the highest scoring archetype
	local bestId = ""
	local bestScore = -1
	for id, score in scores do
		if score > bestScore then
			bestScore = score
			bestId = id
		end
	end

	return bestId
end

-- Clean up when a player leaves
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
end)
```

- [ ] **Step 2: Test in Roblox Studio**

Sync with Rojo (`rojo serve`), open Studio, run a Play test. Verify:
- No errors in the Output console on startup
- Remotes folder appears in ReplicatedStorage with all events/functions

- [ ] **Step 3: Commit**

```bash
git add src/server/QuizServer.server.luau
git commit -m "feat: server-side quiz scoring engine with session tracking"
```

---

## Task 5: DataStore Manager (Player Persistence)

**Files:**
- Create: `src/server/DataStoreManager.luau`

- [ ] **Step 1: Create DataStoreManager module**

Create `src/server/DataStoreManager.luau`:

```luau
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local playerStore = DataStoreService:GetDataStore("PlayerArchetypeData_v1")

export type PlayerData = {
	currentArchetype: string,       -- archetype id or "" if none
	unlockedArchetypes: { string }, -- list of archetype ids
}

local DEFAULT_DATA: PlayerData = {
	currentArchetype = "",
	unlockedArchetypes = {},
}

local DataStoreManager = {}

-- In-memory cache of loaded player data
local cache: { [number]: PlayerData } = {}

function DataStoreManager.load(player: Player): PlayerData
	local userId = player.UserId
	local success, data = pcall(function()
		return playerStore:GetAsync("player_" .. userId)
	end)

	if success and data then
		-- Ensure all fields exist (migration safety)
		data.currentArchetype = data.currentArchetype or ""
		data.unlockedArchetypes = data.unlockedArchetypes or {}
		cache[userId] = data
		return data
	end

	-- New player or load failure — use defaults
	local newData = {
		currentArchetype = DEFAULT_DATA.currentArchetype,
		unlockedArchetypes = {},
	}
	cache[userId] = newData
	return newData
end

function DataStoreManager.save(player: Player): boolean
	local userId = player.UserId
	local data = cache[userId]
	if not data then
		return false
	end

	local success, err = pcall(function()
		playerStore:SetAsync("player_" .. userId, data)
	end)

	if not success then
		warn("[DataStoreManager] Failed to save for " .. player.Name .. ": " .. tostring(err))
	end
	return success
end

function DataStoreManager.getCached(player: Player): PlayerData?
	return cache[player.UserId]
end

function DataStoreManager.setArchetype(player: Player, archetypeId: string)
	local data = cache[player.UserId]
	if not data then
		return
	end

	data.currentArchetype = archetypeId

	-- Add to unlocked set if not already there
	local found = false
	for _, id in data.unlockedArchetypes do
		if id == archetypeId then
			found = true
			break
		end
	end
	if not found then
		table.insert(data.unlockedArchetypes, archetypeId)
	end
end

function DataStoreManager.clearCache(player: Player)
	cache[player.UserId] = nil
end

return DataStoreManager
```

- [ ] **Step 2: Wire DataStore into QuizServer**

Add the following to the **top** of `src/server/QuizServer.server.luau`, after the existing requires:

```luau
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
```

Add the following **after** the `Remotes.init()` line:

```luau
-- Load player data on join
game:GetService("Players").PlayerAdded:Connect(function(player: Player)
	DataStoreManager.load(player)
end)

-- Load data for players already in the game (in case script loads late)
for _, player in game:GetService("Players"):GetPlayers() do
	task.spawn(function()
		DataStoreManager.load(player)
	end)
end

-- Handle LoadPlayerData request from client
local loadPlayerDataRemote = Remotes.get("LoadPlayerData") :: RemoteFunction
loadPlayerDataRemote.OnServerInvoke = function(player: Player)
	local data = DataStoreManager.getCached(player)
	if not data then
		data = DataStoreManager.load(player)
	end
	return data
end
```

Update the `QuizResult` fire section inside the `SubmitAnswer` handler. Replace this block:

```luau
		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
```

With:

```luau
		-- Save result to DataStore
		DataStoreManager.setArchetype(player, result)
		DataStoreManager.save(player)

		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
```

Update the `PlayerRemoving` handler at the bottom. Replace:

```luau
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
end)
```

With:

```luau
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	activeSessions[player] = nil
	DataStoreManager.save(player)
	DataStoreManager.clearCache(player)
end)
```

- [ ] **Step 3: Test in Roblox Studio**

Enable Studio API access: Game Settings > Security > Enable Studio Access to API Services.

Play test and check:
- No DataStore errors in Output
- `LoadPlayerData` returns default data for a new player

- [ ] **Step 4: Commit**

```bash
git add src/server/DataStoreManager.luau src/server/QuizServer.server.luau
git commit -m "feat: player data persistence with DataStoreService"
```

---

## Task 6: Monetization Handler

**Files:**
- Create: `src/server/MonetizationHandler.server.luau`

**Prerequisites:** Before this code works, you must create the following in the Roblox Creator Dashboard for your game:
1. A **Developer Product** named "Skip 5 Minutes" priced at 5 Robux. Note its Product ID.
2. A **GamePass** named "Instant Unlock" priced at 49 Robux. Note its GamePass ID.

- [ ] **Step 1: Create MonetizationHandler**

Create `src/server/MonetizationHandler.server.luau`:

```luau
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

-- IMPORTANT: Replace these with real IDs from Roblox Creator Dashboard
local SKIP_5MIN_PRODUCT_ID = 0      -- Developer Product ID for "Skip 5 Minutes"
local INSTANT_UNLOCK_GAMEPASS_ID = 0 -- GamePass ID for "Instant Unlock"

-- Handle Developer Product purchases (timer skip)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == SKIP_5MIN_PRODUCT_ID then
		local timerSkipRemote = Remotes.get("TimerSkipGranted") :: RemoteEvent
		timerSkipRemote:FireClient(player, 300) -- 300 seconds = 5 minutes
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Handle GamePass check from client
local checkGamePassRemote = Remotes.get("CheckGamePass") :: RemoteFunction
checkGamePassRemote.OnServerInvoke = function(player: Player)
	local success, ownsPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, INSTANT_UNLOCK_GAMEPASS_ID)
	end)
	if success then
		return ownsPass
	end
	return false
end

-- Expose product/gamepass IDs so client can prompt purchases
-- Client needs these to call MarketplaceService:PromptProductPurchase / PromptGamePassPurchase
local idsFolder = Instance.new("Folder")
idsFolder.Name = "MonetizationIds"
idsFolder.Parent = ReplicatedStorage

local skipProductValue = Instance.new("IntValue")
skipProductValue.Name = "SkipProductId"
skipProductValue.Value = SKIP_5MIN_PRODUCT_ID
skipProductValue.Parent = idsFolder

local gamePassValue = Instance.new("IntValue")
gamePassValue.Name = "GamePassId"
gamePassValue.Value = INSTANT_UNLOCK_GAMEPASS_ID
gamePassValue.Parent = idsFolder
```

- [ ] **Step 2: Commit**

```bash
git add src/server/MonetizationHandler.server.luau
git commit -m "feat: monetization handler for timer skip and instant unlock GamePass"
```

---

## Task 7: Leaderboard Manager (Server + Overhead Tags)

**Files:**
- Create: `src/server/LeaderboardManager.server.luau`

- [ ] **Step 1: Create LeaderboardManager**

Create `src/server/LeaderboardManager.server.luau`:

```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Tracks current archetype for every player in the server
-- Key: Player.UserId, Value: { name: string, archetypeId: string }
local serverArchetypes: { [number]: { name: string, archetypeId: string } } = {}

local function getLeaderboardData(): { { name: string, archetypeId: string, archetypeName: string } }
	local entries = {}
	for _, entry in serverArchetypes do
		if entry.archetypeId ~= "" then
			local archetype = Archetypes.getById(entry.archetypeId)
			table.insert(entries, {
				name = entry.name,
				archetypeId = entry.archetypeId,
				archetypeName = if archetype then archetype.name else "Unknown",
			})
		end
	end
	return entries
end

local function broadcastLeaderboard()
	local data = getLeaderboardData()
	local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
	leaderboardRemote:FireAllClients(data)
end

local function setOverheadTag(player: Player, archetypeId: string)
	local archetype = Archetypes.getById(archetypeId)
	if not archetype then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	-- Remove existing tag if present
	local existingGui = head:FindFirstChild("ArchetypeTag")
	if existingGui then
		existingGui:Destroy()
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ArchetypeTag"
	billboardGui.Size = UDim2.new(4, 0, 0.8, 0)
	billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = head

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "[" .. archetype.name .. "]"
	textLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboardGui
end

-- When a player joins, load their archetype and register them
Players.PlayerAdded:Connect(function(player: Player)
	-- Wait for DataStore to load (handled by QuizServer)
	task.wait(1)
	local data = DataStoreManager.getCached(player)
	local archetypeId = if data then data.currentArchetype else ""

	serverArchetypes[player.UserId] = {
		name = player.Name,
		archetypeId = archetypeId,
	}

	-- Set overhead tag when character spawns
	if archetypeId ~= "" then
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- Wait for head to load
			setOverheadTag(player, archetypeId)
		end)
		if player.Character then
			setOverheadTag(player, archetypeId)
		end
	end

	broadcastLeaderboard()
end)

-- Listen for quiz results to update leaderboard and overhead tag
local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
quizResultRemote.OnServerEvent:Connect(function() end) -- dummy, we listen from server side differently

-- We need to hook into the result being set. Add a bindable event approach:
-- Instead, we'll poll the DataStore cache after QuizResult fires.
-- Better approach: listen to the QuizResult event on the server by wrapping the fire.

-- Since QuizServer fires QuizResult to client, we also update leaderboard here
-- by listening to a custom BindableEvent. But simpler: just expose a function.

-- Expose an update function that QuizServer calls after setting a result
local LeaderboardManager = {}

function LeaderboardManager.onPlayerResult(player: Player, archetypeId: string)
	serverArchetypes[player.UserId] = {
		name = player.Name,
		archetypeId = archetypeId,
	}

	-- Update overhead tag
	setOverheadTag(player, archetypeId)

	-- Re-set tag on future respawns
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		setOverheadTag(player, archetypeId)
	end)

	broadcastLeaderboard()
end

-- Handle client requesting current leaderboard
local requestLeaderboardRemote = Remotes.get("RequestLeaderboard") :: RemoteEvent
requestLeaderboardRemote.OnServerEvent:Connect(function(player: Player)
	local data = getLeaderboardData()
	local leaderboardRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
	leaderboardRemote:FireClient(player, data)
end)

-- Clean up on leave
Players.PlayerRemoving:Connect(function(player: Player)
	serverArchetypes[player.UserId] = nil
	broadcastLeaderboard()
end)

-- Make this a ModuleScript-style return so QuizServer can call onPlayerResult
-- But since this is a .server.luau, we need a different approach.
-- Solution: use a BindableEvent to communicate between server scripts.

local resultBindable = Instance.new("BindableEvent")
resultBindable.Name = "PlayerResultEvent"
resultBindable.Parent = game:GetService("ServerScriptService")

resultBindable.Event:Connect(function(player: Player, archetypeId: string)
	LeaderboardManager.onPlayerResult(player, archetypeId)
end)
```

- [ ] **Step 2: Update QuizServer to notify LeaderboardManager**

In `src/server/QuizServer.server.luau`, add at the top after other service references:

```luau
local ServerScriptService = game:GetService("ServerScriptService")
```

Then replace this block in the `SubmitAnswer` handler:

```luau
		-- Save result to DataStore
		DataStoreManager.setArchetype(player, result)
		DataStoreManager.save(player)

		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
```

With:

```luau
		-- Save result to DataStore
		DataStoreManager.setArchetype(player, result)
		DataStoreManager.save(player)

		-- Notify leaderboard manager
		local resultBindable = ServerScriptService:WaitForChild("PlayerResultEvent")
		resultBindable:Fire(player, result)

		local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
		quizResultRemote:FireClient(player, result)
```

- [ ] **Step 3: Commit**

```bash
git add src/server/LeaderboardManager.server.luau src/server/QuizServer.server.luau
git commit -m "feat: leaderboard manager with overhead archetype tags"
```

---

## Task 8: Client UI Controller (Screen Manager)

**Files:**
- Create: `src/client/UIController.client.luau`

- [ ] **Step 1: Create UIController — the main client orchestrator**

Create `src/client/UIController.client.luau`:

```luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuizGameUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Require UI modules
local QuizUI = require(script.Parent:WaitForChild("QuizUI"))
local TimerUI = require(script.Parent:WaitForChild("TimerUI"))
local ResultsUI = require(script.Parent:WaitForChild("ResultsUI"))
local CollectionUI = require(script.Parent:WaitForChild("CollectionUI"))
local LeaderboardUI = require(script.Parent:WaitForChild("LeaderboardUI"))

-- State
local currentScreen: string = "none"

-- Screen management: hide all, then show one
local function hideAllScreens()
	for _, child in screenGui:GetChildren() do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
end

local function showScreen(name: string)
	hideAllScreens()
	currentScreen = name

	if name == "welcome" then
		local frame = screenGui:FindFirstChild("WelcomeFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "quiz" then
		local frame = screenGui:FindFirstChild("QuizFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "timer" then
		local frame = screenGui:FindFirstChild("TimerFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "results" then
		local frame = screenGui:FindFirstChild("ResultsFrame")
		if frame then
			frame.Visible = true
		end
	elseif name == "collection" then
		local frame = screenGui:FindFirstChild("CollectionFrame")
		if frame then
			frame.Visible = true
		end
	end
end

-- Build Welcome Screen
local function buildWelcomeScreen()
	local frame = Instance.new("Frame")
	frame.Name = "WelcomeFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0.15, 0)
	title.Position = UDim2.new(0.1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "Which Anime Character Are You?"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0.6, 0, 0.06, 0)
	subtitle.Position = UDim2.new(0.2, 0, 0.32, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Answer 24 questions to discover your anime personality archetype!"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 220)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = frame

	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.Size = UDim2.new(0.3, 0, 0.08, 0)
	startButton.Position = UDim2.new(0.35, 0, 0.5, 0)
	startButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	startButton.Text = "Start Quiz"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.GothamBold
	startButton.Parent = frame

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 12)
	corner1.Parent = startButton

	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0.3, 0, 0.08, 0)
	collectionButton.Position = UDim2.new(0.35, 0, 0.62, 0)
	collectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
	collectionButton.Text = "My Collection"
	collectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectionButton.TextScaled = true
	collectionButton.Font = Enum.Font.GothamBold
	collectionButton.Parent = frame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 12)
	corner2.Parent = collectionButton

	startButton.MouseButton1Click:Connect(function()
		onStartQuiz()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		showCollectionScreen(true) -- true = came from welcome, show back button
	end)
end

-- Flow handlers
local currentQuizOrder: { number } = {}
local currentQuizIndex: number = 1
local pendingResult: string = ""

function onStartQuiz()
	local startQuizRemote = Remotes.get("StartQuiz") :: RemoteFunction
	local order = startQuizRemote:InvokeServer()
	currentQuizOrder = order
	currentQuizIndex = 1
	QuizUI.build(screenGui)
	showScreen("quiz")
	showNextQuestion()
end

function showNextQuestion()
	if currentQuizIndex > #currentQuizOrder then
		return -- All answered, waiting for server result
	end

	QuizUI.showQuestion(currentQuizOrder[currentQuizIndex], currentQuizIndex, #currentQuizOrder, onAnswerSelected)
end

function onAnswerSelected(answerIndex: number)
	local submitRemote = Remotes.get("SubmitAnswer") :: RemoteEvent
	submitRemote:FireServer(answerIndex)
	currentQuizIndex += 1

	if currentQuizIndex > #currentQuizOrder then
		-- Wait for server to send result
		QuizUI.showWaiting()
	else
		showNextQuestion()
	end
end

function showCollectionScreen(fromWelcome: boolean)
	local loadRemote = Remotes.get("LoadPlayerData") :: RemoteFunction
	local data = loadRemote:InvokeServer()
	CollectionUI.build(screenGui, data.unlockedArchetypes, function()
		if fromWelcome then
			showScreen("welcome")
		else
			showScreen("results")
		end
	end)
	showScreen("collection")
end

-- Listen for quiz result from server
local quizResultRemote = Remotes.get("QuizResult") :: RemoteEvent
quizResultRemote.OnClientEvent:Connect(function(archetypeId: string)
	pendingResult = archetypeId

	-- Check GamePass — if owned, skip timer
	local checkGamePassRemote = Remotes.get("CheckGamePass") :: RemoteFunction
	local ownsGamePass = checkGamePassRemote:InvokeServer()

	if ownsGamePass then
		showResults(archetypeId)
	else
		TimerUI.build(screenGui, function()
			-- Timer finished or fully skipped
			showResults(archetypeId)
		end)
		showScreen("timer")
	end
end)

function showResults(archetypeId: string)
	ResultsUI.build(screenGui, archetypeId, function()
		-- Retake
		onStartQuiz()
	end, function()
		-- View collection
		showCollectionScreen(false)
	end)
	showScreen("results")
end

-- Listen for timer skip granted
local timerSkipRemote = Remotes.get("TimerSkipGranted") :: RemoteEvent
timerSkipRemote.OnClientEvent:Connect(function(secondsRemoved: number)
	TimerUI.onSkipGranted(secondsRemoved)
end)

-- Initialize leaderboard (always visible as toggleable panel)
LeaderboardUI.build(screenGui)

-- Listen for leaderboard updates
local leaderboardUpdateRemote = Remotes.get("LeaderboardUpdate") :: RemoteEvent
leaderboardUpdateRemote.OnClientEvent:Connect(function(data)
	LeaderboardUI.update(data)
end)

-- Request initial leaderboard data
local requestLeaderboardRemote = Remotes.get("RequestLeaderboard") :: RemoteEvent
requestLeaderboardRemote:FireServer()

-- Build and show welcome screen
buildWelcomeScreen()
showScreen("welcome")
```

- [ ] **Step 2: Commit**

```bash
git add src/client/UIController.client.luau
git commit -m "feat: client UI controller with screen management and game flow"
```

---

## Task 9: Quiz UI Screen

**Files:**
- Create: `src/client/QuizUI.luau`

- [ ] **Step 1: Create QuizUI module**

Create `src/client/QuizUI.luau`:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestionBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestionBank"))

local QuizUI = {}

local frame: Frame? = nil

function QuizUI.build(screenGui: ScreenGui)
	-- Remove old frame if rebuilding
	local existing = screenGui:FindFirstChild("QuizFrame")
	if existing then
		existing:Destroy()
	end

	local newFrame = Instance.new("Frame")
	newFrame.Name = "QuizFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0.6, 0, 0.02, 0)
	progressBg.Position = UDim2.new(0.2, 0, 0.08, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = newFrame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Question counter
	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.Size = UDim2.new(0.2, 0, 0.04, 0)
	counter.Position = UDim2.new(0.4, 0, 0.12, 0)
	counter.BackgroundTransparency = 1
	counter.Text = "1/24"
	counter.TextColor3 = Color3.fromRGB(150, 150, 170)
	counter.TextScaled = true
	counter.Font = Enum.Font.Gotham
	counter.Parent = newFrame

	-- Question text
	local questionLabel = Instance.new("TextLabel")
	questionLabel.Name = "QuestionLabel"
	questionLabel.Size = UDim2.new(0.7, 0, 0.15, 0)
	questionLabel.Position = UDim2.new(0.15, 0, 0.2, 0)
	questionLabel.BackgroundTransparency = 1
	questionLabel.Text = ""
	questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	questionLabel.TextScaled = true
	questionLabel.TextWrapped = true
	questionLabel.Font = Enum.Font.GothamBold
	questionLabel.Parent = newFrame

	-- Answer buttons (4)
	local answerColors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(80, 200, 120),
		Color3.fromRGB(255, 180, 50),
	}

	for i = 1, 4 do
		local row = math.ceil(i / 2) -- 1 or 2
		local col = ((i - 1) % 2) + 1 -- 1 or 2

		local button = Instance.new("TextButton")
		button.Name = "Answer" .. i
		button.Size = UDim2.new(0.35, 0, 0.12, 0)
		button.Position = UDim2.new(if col == 1 then 0.1 else 0.55, 0, if row == 1 then 0.45 else 0.62, 0)
		button.BackgroundColor3 = answerColors[i]
		button.Text = ""
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.TextWrapped = true
		button.Font = Enum.Font.GothamBold
		button.Parent = newFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		-- Padding so text doesn't touch edges
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0.05, 0)
		padding.PaddingRight = UDim.new(0.05, 0)
		padding.PaddingTop = UDim.new(0.1, 0)
		padding.PaddingBottom = UDim.new(0.1, 0)
		padding.Parent = button
	end

	-- Waiting label (hidden by default)
	local waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
	waitingLabel.Position = UDim2.new(0.2, 0, 0.45, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Text = "Calculating your archetype..."
	waitingLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	waitingLabel.TextScaled = true
	waitingLabel.Font = Enum.Font.GothamBold
	waitingLabel.Visible = false
	waitingLabel.Parent = newFrame

	frame = newFrame
end

function QuizUI.showQuestion(questionIndex: number, currentNum: number, totalQuestions: number, onAnswer: (number) -> ())
	if not frame then
		return
	end

	local question = QuestionBank.getQuestion(questionIndex)

	-- Update progress bar
	local progressFill = frame:FindFirstChild("ProgressBg"):FindFirstChild("ProgressFill") :: Frame
	progressFill.Size = UDim2.new((currentNum - 1) / totalQuestions, 0, 1, 0)

	-- Update counter
	local counter = frame:FindFirstChild("Counter") :: TextLabel
	counter.Text = currentNum .. "/" .. totalQuestions

	-- Update question text
	local questionLabel = frame:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.Text = question.text

	-- Update answer buttons
	for i = 1, 4 do
		local button = frame:FindFirstChild("Answer" .. i) :: TextButton
		button.Visible = true
		button.Text = question.answers[i].text

		-- Disconnect previous connections by recreating the connection
		-- (simple approach: use a BindableEvent pattern or just reconnect)
		-- For simplicity, we'll use a click flag
		button.MouseButton1Click:Connect(function()
			if frame and frame:FindFirstChild("Answer1").Visible then
				-- Hide buttons to prevent double-click
				for j = 1, 4 do
					local btn = frame:FindFirstChild("Answer" .. j) :: TextButton
					btn.Visible = false
				end
				onAnswer(i)
			end
		end)
	end

	-- Hide waiting label
	local waitingLabel = frame:FindFirstChild("WaitingLabel") :: TextLabel
	waitingLabel.Visible = false
end

function QuizUI.showWaiting()
	if not frame then
		return
	end

	for i = 1, 4 do
		local button = frame:FindFirstChild("Answer" .. i) :: TextButton
		button.Visible = false
	end

	local questionLabel = frame:FindFirstChild("QuestionLabel") :: TextLabel
	questionLabel.Text = ""

	local waitingLabel = frame:FindFirstChild("WaitingLabel") :: TextLabel
	waitingLabel.Visible = true
end

return QuizUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/QuizUI.luau
git commit -m "feat: quiz UI screen with progress bar and answer buttons"
```

---

## Task 10: Timer UI Screen

**Files:**
- Create: `src/client/TimerUI.luau`

- [ ] **Step 1: Create TimerUI module**

Create `src/client/TimerUI.luau`:

```luau
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local TimerUI = {}

local frame: Frame? = nil
local timerConnection: RBXScriptConnection? = nil
local remainingSeconds: number = 0
local onTimerComplete: (() -> ())? = nil

function TimerUI.build(screenGui: ScreenGui, onComplete: () -> ())
	onTimerComplete = onComplete
	remainingSeconds = 15 * 60 -- 15 minutes in seconds

	-- Remove old frame if rebuilding
	local existing = screenGui:FindFirstChild("TimerFrame")
	if existing then
		existing:Destroy()
	end

	local newFrame = Instance.new("Frame")
	newFrame.Name = "TimerFrame"
	newFrame.Size = UDim2.new(1, 0, 1, 0)
	newFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	newFrame.BorderSizePixel = 0
	newFrame.Visible = false
	newFrame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.6, 0, 0.08, 0)
	title.Position = UDim2.new(0.2, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text = "Your result is ready!"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = newFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0.4, 0, 0.15, 0)
	timerLabel.Position = UDim2.new(0.3, 0, 0.28, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "15:00"
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.Code
	timerLabel.Parent = newFrame

	-- Skip with Robux button
	local idsFolder = ReplicatedStorage:WaitForChild("MonetizationIds")
	local skipProductId = idsFolder:WaitForChild("SkipProductId").Value
	local gamePassId = idsFolder:WaitForChild("GamePassId").Value

	local skipRobuxButton = Instance.new("TextButton")
	skipRobuxButton.Name = "SkipRobuxButton"
	skipRobuxButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	skipRobuxButton.Position = UDim2.new(0.3, 0, 0.5, 0)
	skipRobuxButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	skipRobuxButton.Text = "Skip 5 Minutes (5 Robux)"
	skipRobuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipRobuxButton.TextScaled = true
	skipRobuxButton.Font = Enum.Font.GothamBold
	skipRobuxButton.Parent = newFrame

	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 12)
	corner1.Parent = skipRobuxButton

	-- Watch ad button
	local watchAdButton = Instance.new("TextButton")
	watchAdButton.Name = "WatchAdButton"
	watchAdButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	watchAdButton.Position = UDim2.new(0.3, 0, 0.61, 0)
	watchAdButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
	watchAdButton.Text = "Watch Ad to Skip 5 Min (Free)"
	watchAdButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	watchAdButton.TextScaled = true
	watchAdButton.Font = Enum.Font.GothamBold
	watchAdButton.Parent = newFrame

	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 12)
	corner2.Parent = watchAdButton

	-- Instant unlock GamePass button
	local gamePassButton = Instance.new("TextButton")
	gamePassButton.Name = "GamePassButton"
	gamePassButton.Size = UDim2.new(0.4, 0, 0.08, 0)
	gamePassButton.Position = UDim2.new(0.3, 0, 0.72, 0)
	gamePassButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
	gamePassButton.Text = "Instant Unlock - Never Wait Again (49 Robux)"
	gamePassButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gamePassButton.TextScaled = true
	gamePassButton.Font = Enum.Font.GothamBold
	gamePassButton.Parent = newFrame

	local corner3 = Instance.new("UICorner")
	corner3.CornerRadius = UDim.new(0, 12)
	corner3.Parent = gamePassButton

	-- Button handlers
	skipRobuxButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, skipProductId)
	end)

	watchAdButton.MouseButton1Click:Connect(function()
		-- Roblox AdService rewarded video ad
		-- Note: AdService requires the game to be approved for ads on Roblox
		local success, err = pcall(function()
			local AdService = game:GetService("AdService")
			AdService:ShowRewardedAd()
		end)
		if not success then
			warn("[TimerUI] Ad not available: " .. tostring(err))
		end
	end)

	gamePassButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, gamePassId)
	end)

	-- Listen for GamePass purchase completion
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasePlayer, purchasedGamePassId, wasPurchased)
		if purchasePlayer == player and purchasedGamePassId == gamePassId and wasPurchased then
			-- They bought the GamePass — skip immediately
			stopTimer()
			if onTimerComplete then
				onTimerComplete()
			end
		end
	end)

	frame = newFrame
	startTimer()
end

function startTimer()
	if timerConnection then
		timerConnection:Disconnect()
	end

	local lastTick = tick()
	timerConnection = RunService.Heartbeat:Connect(function()
		local now = tick()
		local delta = now - lastTick
		lastTick = now

		remainingSeconds -= delta
		if remainingSeconds <= 0 then
			remainingSeconds = 0
			stopTimer()
			if onTimerComplete then
				onTimerComplete()
			end
			return
		end

		updateTimerDisplay()
	end)
end

function stopTimer()
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
end

function updateTimerDisplay()
	if not frame then
		return
	end
	local timerLabel = frame:FindFirstChild("TimerLabel") :: TextLabel
	if not timerLabel then
		return
	end

	local minutes = math.floor(remainingSeconds / 60)
	local seconds = math.floor(remainingSeconds % 60)
	timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
end

function TimerUI.onSkipGranted(secondsRemoved: number)
	remainingSeconds -= secondsRemoved
	if remainingSeconds <= 0 then
		remainingSeconds = 0
		stopTimer()
		if onTimerComplete then
			onTimerComplete()
		end
	end
end

return TimerUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/TimerUI.luau
git commit -m "feat: timer UI with Robux skip, ad skip, and GamePass instant unlock"
```

---

## Task 11: Results UI Screen (Shareable Card)

**Files:**
- Create: `src/client/ResultsUI.luau`

- [ ] **Step 1: Create ResultsUI module**

Create `src/client/ResultsUI.luau`:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local ResultsUI = {}

function ResultsUI.build(screenGui: ScreenGui, archetypeId: string, onRetake: () -> (), onCollection: () -> ())
	local existing = screenGui:FindFirstChild("ResultsFrame")
	if existing then
		existing:Destroy()
	end

	local archetype = Archetypes.getById(archetypeId)
	if not archetype then
		return
	end

	local frame = Instance.new("Frame")
	frame.Name = "ResultsFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	-- Result card container
	local card = Instance.new("Frame")
	card.Name = "ResultCard"
	card.Size = UDim2.new(0.5, 0, 0.65, 0)
	card.Position = UDim2.new(0.25, 0, 0.05, 0)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
	card.BorderSizePixel = 0
	card.Parent = frame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(255, 200, 50)
	cardStroke.Thickness = 2
	cardStroke.Parent = card

	-- "Your archetype is..." label
	local yourLabel = Instance.new("TextLabel")
	yourLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
	yourLabel.Position = UDim2.new(0.1, 0, 0.05, 0)
	yourLabel.BackgroundTransparency = 1
	yourLabel.Text = "Your anime archetype is..."
	yourLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	yourLabel.TextScaled = true
	yourLabel.Font = Enum.Font.Gotham
	yourLabel.Parent = card

	-- Archetype name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ArchetypeName"
	nameLabel.Size = UDim2.new(0.8, 0, 0.12, 0)
	nameLabel.Position = UDim2.new(0.1, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = archetype.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	descLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = archetype.description
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = card

	-- Example characters
	local examplesLabel = Instance.new("TextLabel")
	examplesLabel.Name = "Examples"
	examplesLabel.Size = UDim2.new(0.8, 0, 0.06, 0)
	examplesLabel.Position = UDim2.new(0.1, 0, 0.63, 0)
	examplesLabel.BackgroundTransparency = 1
	examplesLabel.Text = "Like: " .. table.concat(archetype.examples, ", ")
	examplesLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
	examplesLabel.TextScaled = true
	examplesLabel.Font = Enum.Font.GothamBold
	examplesLabel.Parent = card

	-- Screenshot hint
	local screenshotHint = Instance.new("TextLabel")
	screenshotHint.Size = UDim2.new(0.8, 0, 0.05, 0)
	screenshotHint.Position = UDim2.new(0.1, 0, 0.75, 0)
	screenshotHint.BackgroundTransparency = 1
	screenshotHint.Text = "Screenshot to share with friends!"
	screenshotHint.TextColor3 = Color3.fromRGB(120, 120, 150)
	screenshotHint.TextScaled = true
	screenshotHint.Font = Enum.Font.Gotham
	screenshotHint.Parent = card

	-- Watermark
	local watermark = Instance.new("TextLabel")
	watermark.Size = UDim2.new(0.8, 0, 0.05, 0)
	watermark.Position = UDim2.new(0.1, 0, 0.85, 0)
	watermark.BackgroundTransparency = 1
	watermark.Text = "AnimeQuizGame on Roblox"
	watermark.TextColor3 = Color3.fromRGB(80, 80, 100)
	watermark.TextScaled = true
	watermark.Font = Enum.Font.Gotham
	watermark.Parent = card

	-- Retake button
	local retakeButton = Instance.new("TextButton")
	retakeButton.Name = "RetakeButton"
	retakeButton.Size = UDim2.new(0.22, 0, 0.07, 0)
	retakeButton.Position = UDim2.new(0.15, 0, 0.82, 0)
	retakeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	retakeButton.Text = "Retake Quiz"
	retakeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	retakeButton.TextScaled = true
	retakeButton.Font = Enum.Font.GothamBold
	retakeButton.Parent = frame

	local retakeCorner = Instance.new("UICorner")
	retakeCorner.CornerRadius = UDim.new(0, 12)
	retakeCorner.Parent = retakeButton

	-- Collection button
	local collectionButton = Instance.new("TextButton")
	collectionButton.Name = "CollectionButton"
	collectionButton.Size = UDim2.new(0.22, 0, 0.07, 0)
	collectionButton.Position = UDim2.new(0.63, 0, 0.82, 0)
	collectionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
	collectionButton.Text = "View Collection"
	collectionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectionButton.TextScaled = true
	collectionButton.Font = Enum.Font.GothamBold
	collectionButton.Parent = frame

	local collectionCorner = Instance.new("UICorner")
	collectionCorner.CornerRadius = UDim.new(0, 12)
	collectionCorner.Parent = collectionButton

	retakeButton.MouseButton1Click:Connect(function()
		onRetake()
	end)

	collectionButton.MouseButton1Click:Connect(function()
		onCollection()
	end)
end

return ResultsUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/ResultsUI.luau
git commit -m "feat: results UI with shareable archetype card"
```

---

## Task 12: Collection UI Screen

**Files:**
- Create: `src/client/CollectionUI.luau`

- [ ] **Step 1: Create CollectionUI module**

Create `src/client/CollectionUI.luau`:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Archetypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Archetypes"))

local CollectionUI = {}

function CollectionUI.build(screenGui: ScreenGui, unlockedIds: { string }, onBack: () -> ())
	local existing = screenGui:FindFirstChild("CollectionFrame")
	if existing then
		existing:Destroy()
	end

	-- Build a set for fast lookup
	local unlockedSet: { [string]: boolean } = {}
	for _, id in unlockedIds do
		unlockedSet[id] = true
	end

	local frame = Instance.new("Frame")
	frame.Name = "CollectionFrame"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.6, 0, 0.08, 0)
	title.Position = UDim2.new(0.2, 0, 0.03, 0)
	title.BackgroundTransparency = 1
	title.Text = "My Collection"
	title.TextColor3 = Color3.fromRGB(255, 200, 50)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Progress counter
	local unlockedCount = 0
	for _ in unlockedSet do
		unlockedCount += 1
	end

	local progressLabel = Instance.new("TextLabel")
	progressLabel.Size = UDim2.new(0.3, 0, 0.04, 0)
	progressLabel.Position = UDim2.new(0.35, 0, 0.11, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = unlockedCount .. "/" .. #Archetypes.list .. " Collected"
	progressLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	progressLabel.TextScaled = true
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Parent = frame

	-- Grid of archetype cards (2 columns, 5 rows)
	local allArchetypes = Archetypes.list
	for i, archetype in allArchetypes do
		local row = math.ceil(i / 2)
		local col = ((i - 1) % 2) + 1
		local isUnlocked = unlockedSet[archetype.id] == true

		local cardX = if col == 1 then 0.08 else 0.52
		local cardY = 0.16 + (row - 1) * 0.155

		local card = Instance.new("Frame")
		card.Name = "Card_" .. archetype.id
		card.Size = UDim2.new(0.4, 0, 0.14, 0)
		card.Position = UDim2.new(cardX, 0, cardY, 0)
		card.BackgroundColor3 = if isUnlocked then Color3.fromRGB(30, 30, 55) else Color3.fromRGB(20, 20, 30)
		card.BorderSizePixel = 0
		card.Parent = frame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = if isUnlocked then Color3.fromRGB(255, 200, 50) else Color3.fromRGB(50, 50, 70)
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.9, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if isUnlocked then archetype.name else "???"
		nameLabel.TextColor3 = if isUnlocked then Color3.fromRGB(255, 200, 50) else Color3.fromRGB(80, 80, 100)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
		descLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = if isUnlocked then archetype.description else "Take the quiz to unlock!"
		descLabel.TextColor3 = if isUnlocked then Color3.fromRGB(180, 180, 200) else Color3.fromRGB(60, 60, 80)
		descLabel.TextScaled = true
		descLabel.TextWrapped = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = card
	end

	-- Back button
	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0.15, 0, 0.06, 0)
	backButton.Position = UDim2.new(0.425, 0, 0.93, 0)
	backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	backButton.Text = "Back"
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.TextScaled = true
	backButton.Font = Enum.Font.GothamBold
	backButton.Parent = frame

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 12)
	backCorner.Parent = backButton

	backButton.MouseButton1Click:Connect(function()
		onBack()
	end)
end

return CollectionUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/CollectionUI.luau
git commit -m "feat: collection UI grid with locked/unlocked archetype cards"
```

---

## Task 13: Leaderboard UI (Side Panel)

**Files:**
- Create: `src/client/LeaderboardUI.luau`

- [ ] **Step 1: Create LeaderboardUI module**

Create `src/client/LeaderboardUI.luau`:

```luau
local LeaderboardUI = {}

local panel: Frame? = nil
local contentFrame: Frame? = nil
local isOpen: boolean = false

function LeaderboardUI.build(screenGui: ScreenGui)
	local existing = screenGui:FindFirstChild("LeaderboardPanel")
	if existing then
		existing:Destroy()
	end

	-- Toggle button (always visible)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "LeaderboardToggle"
	toggleButton.Size = UDim2.new(0, 120, 0, 35)
	toggleButton.Position = UDim2.new(1, -130, 0, 10)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	toggleButton.Text = "Leaderboard"
	toggleButton.TextColor3 = Color3.fromRGB(255, 200, 50)
	toggleButton.TextScaled = true
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.ZIndex = 10
	toggleButton.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Side panel
	local newPanel = Instance.new("Frame")
	newPanel.Name = "LeaderboardPanel"
	newPanel.Size = UDim2.new(0.25, 0, 0.7, 0)
	newPanel.Position = UDim2.new(0.74, 0, 0.06, 0)
	newPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	newPanel.BorderSizePixel = 0
	newPanel.Visible = false
	newPanel.ZIndex = 9
	newPanel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = newPanel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(60, 60, 100)
	panelStroke.Thickness = 1
	panelStroke.Parent = newPanel

	-- Panel title
	local panelTitle = Instance.new("TextLabel")
	panelTitle.Size = UDim2.new(0.9, 0, 0.06, 0)
	panelTitle.Position = UDim2.new(0.05, 0, 0.02, 0)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Text = "Server Archetypes"
	panelTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
	panelTitle.TextScaled = true
	panelTitle.Font = Enum.Font.GothamBold
	panelTitle.Parent = newPanel

	-- Top archetype label
	local topLabel = Instance.new("TextLabel")
	topLabel.Name = "TopArchetype"
	topLabel.Size = UDim2.new(0.9, 0, 0.05, 0)
	topLabel.Position = UDim2.new(0.05, 0, 0.09, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = "No results yet"
	topLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	topLabel.TextScaled = true
	topLabel.Font = Enum.Font.Gotham
	topLabel.Parent = newPanel

	-- Scrolling content area for player entries
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
	scrollFrame.Position = UDim2.new(0.05, 0, 0.16, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = newPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scrollFrame

	panel = newPanel
	contentFrame = scrollFrame

	toggleButton.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		newPanel.Visible = isOpen
	end)
end

function LeaderboardUI.update(data: { { name: string, archetypeId: string, archetypeName: string } })
	if not panel or not contentFrame then
		return
	end

	-- Clear existing entries
	for _, child in contentFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Find most common archetype
	local counts: { [string]: number } = {}
	for _, entry in data do
		counts[entry.archetypeName] = (counts[entry.archetypeName] or 0) + 1
	end

	local topName = "None"
	local topCount = 0
	for name, count in counts do
		if count > topCount then
			topCount = count
			topName = name
		end
	end

	local topLabel = panel:FindFirstChild("TopArchetype") :: TextLabel
	if topLabel then
		if #data > 0 then
			topLabel.Text = "Top: " .. topName .. " (" .. topCount .. " players)"
		else
			topLabel.Text = "No results yet"
		end
	end

	-- Add player entries
	for i, entry in data do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 28)
		label.BackgroundTransparency = 1
		label.Text = entry.name .. " - " .. entry.archetypeName
		label.TextColor3 = Color3.fromRGB(200, 200, 220)
		label.TextScaled = true
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = i
		label.Parent = contentFrame
	end

	-- Update canvas size
	local listLayout = contentFrame:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end
end

return LeaderboardUI
```

- [ ] **Step 2: Commit**

```bash
git add src/client/LeaderboardUI.luau
git commit -m "feat: toggleable leaderboard side panel with server archetype rankings"
```

---

## Task 14: Integration Testing in Roblox Studio

**Files:**
- No new files. This task verifies everything works together.

- [ ] **Step 1: Sync project to Studio**

```bash
rojo serve
```

Open Roblox Studio, connect via the Rojo plugin. Verify the Explorer shows:
- `ReplicatedStorage > Shared` with Archetypes, QuestionBank, Remotes modules
- `ServerScriptService > Server` with QuizServer, DataStoreManager, MonetizationHandler, LeaderboardManager
- `StarterPlayer > StarterPlayerScripts > Client` with all UI modules

- [ ] **Step 2: Enable Studio API access**

Game Settings > Security > Enable Studio Access to API Services (needed for DataStoreService).

- [ ] **Step 3: Play test — Welcome Screen**

Click Play. Verify:
- Welcome screen appears with title, Start Quiz button, My Collection button
- Leaderboard toggle button visible in top-right corner
- No errors in Output console

- [ ] **Step 4: Play test — Quiz Flow**

Click "Start Quiz". Verify:
- Quiz screen shows with question text, 4 answer buttons, progress bar, counter
- Clicking an answer advances to the next question
- Progress bar fills as you answer
- After all 24 questions, "Calculating your archetype..." appears briefly

- [ ] **Step 5: Play test — Timer Screen**

After quiz completes, verify:
- Timer screen shows with 15:00 countdown
- Timer counts down in real time
- "Skip 5 Minutes" button is present (won't actually charge in Studio)
- "Watch Ad" button is present
- "Instant Unlock" button is present

- [ ] **Step 6: Play test — Results Screen**

Wait for timer or skip. Verify:
- Result card shows with archetype name, description, example characters
- "Retake Quiz" and "View Collection" buttons work
- Card looks good enough to screenshot

- [ ] **Step 7: Play test — Collection Screen**

Click "View Collection". Verify:
- Grid shows 10 archetype cards
- The one you just got is unlocked (colored, shows name + description)
- Others are locked (greyed, show "???")
- Back button returns to previous screen

- [ ] **Step 8: Play test — Leaderboard**

Click the leaderboard toggle. Verify:
- Side panel opens
- Shows your name and archetype
- Top archetype displays correctly
- Overhead tag appears above your character's head

- [ ] **Step 9: Fix any issues found during testing**

If any errors appear in the Output console or UI elements are misaligned, fix them before proceeding.

- [ ] **Step 10: Commit any fixes**

```bash
git add -A
git commit -m "fix: integration test fixes"
```

---

## Task 15: Configure Monetization IDs

**Files:**
- Modify: `src/server/MonetizationHandler.server.luau` (replace product/gamepass IDs)

- [ ] **Step 1: Create Developer Product and GamePass**

In the Roblox Creator Dashboard for your game:
1. Create Developer Product: "Skip 5 Minutes" — 5 Robux. Note the Product ID.
2. Create GamePass: "Instant Unlock" — 49 Robux. Note the GamePass ID.

- [ ] **Step 2: Update MonetizationHandler with real IDs**

In `src/server/MonetizationHandler.server.luau`, replace:

```luau
local SKIP_5MIN_PRODUCT_ID = 0
local INSTANT_UNLOCK_GAMEPASS_ID = 0
```

With the real IDs from step 1.

- [ ] **Step 3: Commit**

```bash
git add src/server/MonetizationHandler.server.luau
git commit -m "feat: add monetization product IDs"
```

---

## Task 16: Final Verification & Publish

- [ ] **Step 1: Full playthrough test**

Do a complete playthrough in Studio: Welcome > Quiz (all 24 questions) > Timer > Results > Collection > Leaderboard. Verify everything works end-to-end.

- [ ] **Step 2: Test persistence**

Play, complete the quiz, stop. Play again. Verify:
- Collection shows previously unlocked archetype
- Overhead tag appears on spawn

- [ ] **Step 3: Publish to Roblox**

In Studio: File > Publish to Roblox. Configure game settings (name, description, icon, thumbnail).

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: anime quiz game v1 complete and published"
```
