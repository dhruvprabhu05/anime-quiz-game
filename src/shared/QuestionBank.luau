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
