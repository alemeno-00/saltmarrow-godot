class_name Lore
extends RefCounted
## Everything Thomas can find and read in the Sewers (design/quick-specs/room-contents-2026-10-30.md, part 2), kept
## here so the writing can be worked on in one place. Drafts, approved by Julian 2026-10-31 to go in; the letters are
## to be workshopped later.
##
## - **Ellen's letters**: pages she wrote and never sent, dropped as the Faithful led her down. Found in story order
##   across lives, worded for the life's backstory. The two versions differ in Ellen and Thomas's relationship, not in
##   anything about how he fights: Fury's Thomas is quick to anger and close to her; Shadow's came back from the war
##   quiet and far away, and she writes because he won't.
## - **The First Shift's tally tags**: Garrick's night shift, whom Mara still counts. The names never change; what Thomas
##   sees beside each body changes from life to life (the star rewriting things), one of two looks.
## - **From the chapel**: hymn sheets and notices of Sister Agathe's Chapel of the Lamp.

const LETTERS := {
	"fury": [
		"Tom — Sister Agathe says I may write as often as I like, so you'll be sick of me. The cough is gone. Gone, Tom, not better. I ran up the chapel steps this morning just to see if I could, and laughed at the top like a fool. You'd have scowled and told me to sit. I know you're still angry: about the war, the fever, all of it. Put it down for a minute. I'm well. — E.",
		"Tom — The dreams haven't stopped, they've only stopped frightening me. The cliff, the lift, the bell. Agathe says everyone who comes here had the same one, and that it's a calling, not a sickness. There's a girl from Holloway who dreamed it, and a fisherman's widow, and a boy called Pip who sweeps the chapel. We sing in the evenings. I sing, Tom. In front of people.",
		"We went down today, only a little way, through the old drains under Gutter Lane. Agathe carried her lamp and nobody slipped. It was cold and smelled of the sea and I wasn't afraid once, which isn't like me. The others hummed the long hymn so the dark wouldn't feel lonely. I could feel it under my feet, Tom. Something very big, being very patient.",
		"I keep starting these and not sending them. Agathe says letters are for people who are far away, and that soon nobody will be. I don't think she means it the way it sounds. My eyes look odd in the lamp now, a sort of shine. Don't come down here shouting. I know you: you'll make it a fight, because that's the only way you know how to be frightened. There's nothing to fight.",
		"The miners don't talk to us. They work the new seam and look through you. One had salt in his eyebrows like frost. I asked his name and he said he couldn't remember it, but he could remember mine, and then he said it. Tom, I hadn't told him.",
		"I'm writing this by its light now. You don't need a lamp below the third gate: it comes up through the water, soft, like sun through your eyelids. Everyone is so kind. I'm not ill, I'm not sad, I'm only very full. If you come, come gently. Leave your temper at the top. Bring the scarf; I want to see if I still remember knitting it. — E.",
	],
	"shadow": [
		"Tom — Sister Agathe says I may write as often as I like. I don't know if you read them. You never wrote back from the war either, and I used to tell myself that meant you were busy. The cough is gone. Gone, not better. I ran up the chapel steps this morning and laughed at the top like a fool. I wish you'd been there, even standing at the back the way you do. I'm well. — E.",
		"Tom — The dreams haven't stopped, they've only stopped frightening me. The cliff, the lift, the bell. Agathe says everyone who comes here dreamed it too. There's a girl from Holloway, a fisherman's widow, and a boy called Pip who sweeps the chapel. We sing in the evenings, and nobody asks what anyone did before. I think you'd like that part, if you let yourself.",
		"We went down today, only a little way, through the old drains under Gutter Lane. Agathe carried her lamp and nobody slipped. It was cold and smelled of the sea and I wasn't afraid once. The others hummed the long hymn so the dark wouldn't feel lonely. I thought of you, for some reason: how you used to sit up at night after you came home, not reading, not anything, just listening. I could feel it under my feet, Tom. Something very big, listening back.",
		"I keep starting these and not sending them. Agathe says letters are for people who are far away, and that soon nobody will be. I don't think she means it the way it sounds. My eyes look odd in the lamp now, a sort of shine. You'd notice. You notice everything and say nothing. Say something, this once, before you come. You don't have to tell me what happened over there. I only want to hear your voice.",
		"The miners don't talk to us. They work the new seam and look through you. One had salt in his eyebrows like frost. I asked his name and he said he couldn't remember it, but he could remember mine, and then he said it. Tom, I hadn't told him.",
		"I'm writing this by its light now. You don't need a lamp below the third gate: it comes up through the water, soft, like sun through your eyelids. Everyone is so kind. I'm not ill, I'm not sad, I'm only very full. Whatever you did over there, it doesn't matter down here. Nothing that was done matters. If you come, let me see your face. Bring the scarf; I want to see if I still remember knitting it. — E.",
	],
}

## Garrick's night shift. Each: tag number, name, and two looks (one is seen in any one life).
const TAGS := [
	[3, "Owen Treloar", [
		"Face down in the shallows, one boot gone. His hands are crusted white to the wrist.",
		"On his back in the shallows, both boots on, staring up. Salt has grown over his lips."]],
	[7, "Jory Pellow", [
		"Sitting against the wall as if he'd stopped to rest. His lamp is in his lap, cold. He is smiling.",
		"Sitting against the wall, his lamp in his lap. It is still lit, very faintly, though there is no oil in it."]],
	[11, "Sam Hocking", [
		"Curled up small, a child's carved bird in one fist.",
		"Curled up small, his fist closed on nothing. A child's carved bird lies just out of reach."]],
	[12, "Ned Pascoe", [
		"Half in the water. The water around him is very still, very clear, and faintly lit.",
		"Half in the water. Where his hand trails in, the water has turned to salt."]],
	[15, "Will Trevan", [
		"His pick lies beside him, the haft worn pale where the hands go. Someone has closed his eyes with salt.",
		"His pick is gone. His hands still hold the shape of it."]],
	[19, "Kit Penrose", [
		"The youngest of them. The tag hangs from a new cord; the old one wore through.",
		"The youngest of them. The tag hangs from a cord of red wool, unravelled from a scarf."]],
]

## id -> [title, text]
const CHAPEL := {
	"lift_hymn": ["Hymn sheet: The Lift Hymn", "Lower me, lower me, gentle and slow,\ndown where the bells of the deep water go.\nLight that was falling has come here to stay;\nlower me, Mother, I'll find my own way."],
	"bell_below": ["Hymn sheet: The Bell Below", "There is a bell beneath the sea\nthat never has been rung.\nIt waits for every one of me\nto learn its silent tongue."],
	"handbill": ["A handbill", "THE CHAPEL OF THE LAMP, SALTMARROW.\nAll who dream of the cliff are welcome. The sick are healed without charge. Evening song at the ninth bell.\n— Sr. Agathe"],
	"pump_note": ["A note pinned to a pump", "Children — the water below the third gate is not cold, only new. Do not be afraid of it. Go down in pairs, and sing. I will come back for the ones who are slow. — A."],
}

## Lines of hymn heard through the walls (the room event): from the hymns above, so what Thomas overhears is what he
## later reads.
const HEARD := [
	"Through the stone, faintly:  \"...lower me, lower me, gentle and slow...\"",
	"Singing beyond the wall:  \"...down where the bells of the deep water go...\"",
	"Many voices, one breath:  \"...there is a bell beneath the sea that never has been rung...\"",
	"Through the stone:  \"...it waits for every one of me...\"",
]


## Every id that can be found, by kind ("letter", "tag", "chapel"), in the order they are meant to be found.
static func ids(kind: String) -> Array[String]:
	var out: Array[String] = []
	match kind:
		"letter":
			for i in LETTERS.fury.size():
				out.append("letter_%d" % (i + 1))
		"tag":
			for t in TAGS:
				out.append("tag_%d" % t[0])
		"chapel":
			for k in CHAPEL:
				out.append("chapel_" + k)
	return out


## The kind of an id: "letter", "tag" or "chapel".
static func kind_of(id: String) -> String:
	return id.get_slice("_", 0)


## What a find says, as Thomas reads it in this life: [title, text]. Letters are worded for the backstory; a miner's
## look is one of two, fixed for the life (`life_seed`).
static func page(id: String, backstory: String, life_seed: int) -> Array:
	var rest := id.substr(id.find("_") + 1)
	match kind_of(id):
		"letter":
			var n := int(rest)
			var set: Array = LETTERS.get(backstory, LETTERS.fury)
			return ["Ellen's letter (%d of %d)" % [n, set.size()], set[n - 1]]
		"tag":
			for t in TAGS:
				if t[0] == int(rest):
					var look: String = t[2][tag_look(t[0], life_seed)]
					return ["A dead miner: No. %d, %s" % [t[0], t[1]], "SALTMARROW LIFT · NIGHT SHIFT · No. %d · %s\n\n%s" % [t[0], t[1].to_upper(), look]]
		"chapel":
			return CHAPEL[rest]
	return ["", ""]


## Which of a miner's two looks this life shows.
static func tag_look(no: int, life_seed: int) -> int:
	return absi(hash([life_seed, "tag", no])) % 2


## What the thing on the floor is called, for the hover label and the menu.
static func floor_name(id: String) -> String:
	match kind_of(id):
		"letter":
			return "A letter, in Ellen's hand"
		"tag":
			return "A dead miner"
		"chapel":
			return {"lift_hymn": "A hymn sheet", "bell_below": "A hymn sheet", "handbill": "A handbill", "pump_note": "A note"}.get(id.substr(7), "A paper")
	return ""
