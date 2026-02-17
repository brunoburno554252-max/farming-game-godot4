## data/npcs/npc_database.gd
## NPCDatabase — Registro central de todos os NPCs.
## Carrega de .tres e/ou registra defaults programaticamente.
class_name NPCDatabase
extends RefCounted


static var _npcs: Dictionary = {}
static var _initialized: bool = false


static func initialize() -> void:
	if _initialized:
		return
	
	_load_from_directory("res://data/npcs/")
	
	if _npcs.is_empty():
		_register_default_npcs()
	
	_initialized = true
	print("[NPCDatabase] Carregados %d NPCs." % _npcs.size())


static func _load_from_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res is NPCData:
				_npcs[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


static func get_npc(npc_id: String) -> NPCData:
	return _npcs.get(npc_id, null)

static func has_npc(npc_id: String) -> bool:
	return _npcs.has(npc_id)

static func get_all_npcs() -> Array:
	return _npcs.values()

static func get_all_npc_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _npcs.keys():
		ids.append(key)
	return ids


# =============================================================================
# DEFAULT NPCs — 8 personagens iniciais
# =============================================================================

static func _register_default_npcs() -> void:
	_reg_npc("pierre", "Pierre", "Dono da loja geral. Trabalha duro para competir.", "town",
		Vector2i(8, 12), false, Constants.Season.SPRING, 26,
		{"cauliflower": Constants.GiftTaste.LOVE, "fried_egg": Constants.GiftTaste.LIKE, "stone": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["Bem-vindo à minha loja! Precisa de sementes?", "A primavera é a melhor estação para começar a plantar!"],
			Constants.Season.SUMMER: ["O calor é bom para os negócios.", "Já experimentou plantar melões? Vendem bem!"],
			Constants.Season.FALL: ["O outono traz as melhores colheitas.", "As abóboras estão fazendo sucesso este ano."],
			Constants.Season.WINTER: ["O inverno é mais tranquilo na loja.", "Aproveite para planejar a próxima estação."],
		},
		[
			{"hour": 9, "location": "general_store", "tile": Vector2i(4, 5), "facing": 2},
			{"hour": 17, "location": "town", "tile": Vector2i(8, 12), "facing": 2},
			{"hour": 21, "location": "town", "tile": Vector2i(8, 12), "facing": 2},
		])

	_reg_npc("emily", "Emily", "Trabalha no bar. Adora cristais e roupas coloridas.", "town",
		Vector2i(15, 10), true, Constants.Season.SPRING, 27,
		{"melon": Constants.GiftTaste.LOVE, "daffodil": Constants.GiftTaste.LOVE, "copper_ore": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["As flores estão lindas! Adoro a primavera.", "Você gosta de costura? Eu faço minhas próprias roupas!"],
			Constants.Season.SUMMER: ["O verão me dá tanta energia!", "Já viu o pôr do sol na praia? É mágico."],
			Constants.Season.FALL: ["As cores do outono são inspiradoras.", "Estou trabalhando num vestido novo."],
			Constants.Season.WINTER: ["O inverno é perfeito para meditar.", "Os cristais brilham mais no frio."],
		},
		[
			{"hour": 10, "location": "town", "tile": Vector2i(15, 10), "facing": 2},
			{"hour": 16, "location": "saloon", "tile": Vector2i(5, 8), "facing": 0},
			{"hour": 24, "location": "town", "tile": Vector2i(15, 10), "facing": 2},
		])

	_reg_npc("clint", "Clint", "O ferreiro da cidade. Tímido mas habilidoso.", "town",
		Vector2i(20, 14), false, Constants.Season.WINTER, 26,
		{"gold_bar": Constants.GiftTaste.LOVE, "copper_bar": Constants.GiftTaste.LIKE, "flower": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["Traga seus minérios, eu faço barras.", "A fornalha está sempre quente aqui."],
			Constants.Season.SUMMER: ["Esse calor... e eu trabalho perto de uma fornalha.", "Precisa melhorar suas ferramentas?"],
			Constants.Season.FALL: ["O outono é bom pra minerar.", "Encontrou algum minério raro?"],
			Constants.Season.WINTER: ["...Pelo menos o fogo da fornalha aquece.", "Tenho desconto em upgrades essa semana."],
		},
		[
			{"hour": 9, "location": "blacksmith", "tile": Vector2i(3, 4), "facing": 0},
			{"hour": 18, "location": "saloon", "tile": Vector2i(8, 6), "facing": 2},
			{"hour": 23, "location": "town", "tile": Vector2i(20, 14), "facing": 2},
		])

	_reg_npc("linus", "Linus", "Vive na natureza. Sábio e gentil.", "mountain",
		Vector2i(5, 3), false, Constants.Season.WINTER, 3,
		{"wild_horseradish": Constants.GiftTaste.LOVE, "common_mushroom": Constants.GiftTaste.LOVE, "gold_bar": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["A natureza está despertando. Sinto a energia.", "Já experimentou pescar no lago da montanha?"],
			Constants.Season.SUMMER: ["As noites de verão são perfeitas para observar estrelas.", "Encontrei cogumelos hoje cedo."],
			Constants.Season.FALL: ["O outono traz os melhores sabores da floresta.", "A natureza se prepara para descansar."],
			Constants.Season.WINTER: ["O frio é difícil, mas a fogueira me aquece.", "Já pensou em como a natureza é resiliente?"],
		},
		[
			{"hour": 6, "location": "mountain", "tile": Vector2i(5, 3), "facing": 2},
			{"hour": 12, "location": "mountain", "tile": Vector2i(10, 8), "facing": 2},
			{"hour": 20, "location": "mountain", "tile": Vector2i(5, 3), "facing": 2},
		])

	_reg_npc("gus", "Gus", "Dono do bar. Cozinheiro talentoso.", "town",
		Vector2i(12, 8), false, Constants.Season.SUMMER, 8,
		{"hot_pepper": Constants.GiftTaste.LOVE, "bread": Constants.GiftTaste.LIKE, "clay": Constants.GiftTaste.HATE},
		{
			Constants.Season.SPRING: ["O bar está aberto! Sirvo o melhor café da região.", "A primavera me inspira receitas novas."],
			Constants.Season.SUMMER: ["Calor pede bebida gelada! Vem pro bar.", "Meus pratos de verão são os melhores."],
			Constants.Season.FALL: ["Sopa quente no outono, nada melhor.", "A colheita traz ingredientes incríveis."],
			Constants.Season.WINTER: ["Chocolate quente? Só aqui no bar.", "O inverno é a época perfeita pra cozinhar."],
		},
		[
			{"hour": 11, "location": "saloon", "tile": Vector2i(3, 3), "facing": 2},
			{"hour": 24, "location": "town", "tile": Vector2i(12, 8), "facing": 2},
		])

	_reg_npc("abigail", "Abigail", "Aventureira e misteriosa. Adora videogames.", "town",
		Vector2i(9, 14), true, Constants.Season.FALL, 13,
		{"pumpkin": Constants.GiftTaste.LOVE, "blueberry": Constants.GiftTaste.LIKE, "clay": Constants.GiftTaste.HATE},
		{
			Constants.Season.SPRING: ["Tô jogando um jogo novo. Quer jogar comigo?", "Às vezes eu vou até a mina explorar."],
			Constants.Season.SUMMER: ["O verão é meio entediante...", "Queria que tivesse mais aventura por aqui."],
			Constants.Season.FALL: ["Outono! Minha estação favorita. Abóboras por todo lado!", "Eu adoro o Halloween. Pena que não temos aqui."],
			Constants.Season.WINTER: ["A neve é bonita, mas quero fazer algo emocionante.", "Vamos explorar a mina juntos?"],
		},
		[
			{"hour": 9, "location": "town", "tile": Vector2i(9, 14), "facing": 2},
			{"hour": 14, "location": "mountain", "tile": Vector2i(12, 5), "facing": 2},
			{"hour": 19, "location": "town", "tile": Vector2i(9, 14), "facing": 2},
		])

	_reg_npc("sam", "Sam", "Músico e skatista. Sempre animado.", "town",
		Vector2i(18, 8), true, Constants.Season.SUMMER, 17,
		{"corn": Constants.GiftTaste.LOVE, "salad": Constants.GiftTaste.LIKE, "leek": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["Tô compondo uma música nova! Quer ouvir?", "A banda vai tocar no festival da primavera!"],
			Constants.Season.SUMMER: ["Verão! Praia, skate e música. O que mais precisa?", "Vamos na praia depois?"],
			Constants.Season.FALL: ["O som das folhas caindo... inspira músicas.", "Tô ensaiando pro show de outono."],
			Constants.Season.WINTER: ["Neve! Hora de guerra de bolas de neve!", "Não dá pra andar de skate na neve..."],
		},
		[
			{"hour": 10, "location": "town", "tile": Vector2i(18, 8), "facing": 2},
			{"hour": 15, "location": "beach", "tile": Vector2i(8, 5), "facing": 2},
			{"hour": 20, "location": "saloon", "tile": Vector2i(10, 7), "facing": 0},
			{"hour": 24, "location": "town", "tile": Vector2i(18, 8), "facing": 2},
		])

	_reg_npc("robin", "Robin", "Carpinteira. Constrói e reforma edifícios.", "mountain",
		Vector2i(15, 2), false, Constants.Season.FALL, 21,
		{"hardwood": Constants.GiftTaste.LOVE, "iron_bar": Constants.GiftTaste.LIKE, "coal": Constants.GiftTaste.DISLIKE},
		{
			Constants.Season.SPRING: ["Precisa de uma construção? Estou aqui!", "A madeira da primavera é a melhor pra trabalhar."],
			Constants.Season.SUMMER: ["Construí uma varanda nova pra minha casa.", "Quer expandir o celeiro? Me procure!"],
			Constants.Season.FALL: ["Preciso estocar madeira pro inverno.", "Gosto de trabalhar com madeira de lei."],
			Constants.Season.WINTER: ["Reformas internas são ideais pro inverno.", "Traga madeira e pedra, eu construo o que precisar."],
		},
		[
			{"hour": 9, "location": "mountain", "tile": Vector2i(15, 2), "facing": 2},
			{"hour": 17, "location": "town", "tile": Vector2i(5, 5), "facing": 2},
			{"hour": 21, "location": "mountain", "tile": Vector2i(15, 2), "facing": 2},
		])


static func _reg_npc(
	id: String, display: String, desc: String, home: String, home_t: Vector2i,
	romanceable: bool, b_season: Constants.Season, b_day: int,
	gifts: Dictionary, dialogues: Dictionary, schedule: Array
) -> void:
	var npc := NPCData.new()
	npc.id = id
	npc.display_name = display
	npc.description = desc
	npc.home_location = home
	npc.home_tile = home_t
	npc.is_romanceable = romanceable
	npc.birthday_season = b_season
	npc.birthday_day = b_day
	npc.gift_preferences = gifts
	npc.seasonal_dialogue = dialogues
	npc.default_schedule = []
	for entry in schedule:
		npc.default_schedule.append(entry)
	_npcs[id] = npc
