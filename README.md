# 🌾 Farming Game — Godot 4

Jogo de fazenda estilo Stardew Valley com arquitetura profissional, escalável e otimizada para mobile Android.

## Arquitetura

Baseada na análise do código-fonte real do Stardew Valley (descompilado), adaptada para Godot 4 com GDScript.

### Sistemas (Autoloads)

| Sistema | Descrição | Status |
|---------|-----------|--------|
| `EventBus` | Barramento de sinais centralizado (~50 sinais) | ✅ Fase 1 |
| `GameManager` | Orquestrador central, state management, save/load | ✅ Fase 1 |
| `TimeSystem` | Ciclo de dia 20h, estações, calendário | ✅ Fase 1 |
| `WeatherSystem` | Clima diário (sunny, rain, storm, snow, wind) | ✅ Fase 1 |
| `LocationManager` | Carregamento de cenas/locations com cache | ✅ Fase 1 |
| `InventorySystem` | Itens, hotbar, stacks, gold | ✅ Fase 1 |
| `DatabaseManager` | SQLite com 12 tabelas, WAL mode | ✅ Fase 1 |
| `UIManager` | Stack de menus, pause automático | ✅ Fase 1 |
| `AudioManager` | Pool de SFX, música por location | ✅ Fase 1 |
| `DialogueManager` | Diálogos com choices | ✅ Fase 1 |

### Classes Core

- `StateMachine` — Máquina de estados genérica reutilizável
- `State` — Classe base para estados
- `Constants` — Todos os enums e constantes do jogo

## Plano de Implementação

### Fase 1 — Core Engine ✅
Estrutura do projeto, GameManager, StateMachine, EventBus, DatabaseManager, todos os Autoloads base.

### Fase 2 — World Systems
TimeSystem completo, WeatherSystem completo, SceneTransitionManager com fade.

### Fase 3 — Farming Core
HoeDirt, Crop system, Object Placement, InventorySystem completo, Tool System.

### Fase 4 — Player
PlayerController com StateMachine, energia, animações, joystick virtual.

### Fase 5 — UI
UIManager completo, HUD, Inventory UI, Dialogue UI, Shop UI.

### Fase 6 — NPCs
NPCManager, Schedule/Pathfinding, Friendship, DialogueSystem completo.

### Fase 7 — Content Systems
CraftingSystem, Fishing, Mine/Combat, AudioManager completo.

### Fase 8 — Polish & Integration
Save/Load completo, Event/Cutscene system, otimizações mobile.

## Requisitos

- **Godot 4.3+**
- **Addon**: [godot-sqlite](https://github.com/2shady4u/godot-sqlite) (para DatabaseManager)

## Estrutura de Pastas

```
farming_game/
├── autoloads/          # Singletons globais (10 sistemas)
├── classes/            # Classes base (StateMachine, State, Constants)
├── data/               # Resources (items, crops, npcs, recipes, events, schedules)
├── locations/          # Cenas de cada location (farm, town, mine, shop, house)
├── player/             # PlayerController + estados
├── npcs/               # NPCController + estados
├── terrain_features/   # HoeDirt, Tree, Grass, etc.
├── objects/            # Objetos colocáveis (sprinklers, chests, machines)
├── ui/                 # HUD, menus, diálogos, componentes
├── audio/              # Música e SFX
├── effects/            # Partículas e efeitos visuais
├── scenes/             # Cenas utilitárias (main, transitions)
└── shaders/            # Shaders customizados
```

## Banco de Dados (SQLite)

12 tabelas cobrindo: game_state, player, inventory, equipment, terrain_features, crops, placed_objects, npc_friendship, skills, unlocked_recipes, completed_events, shipping_log.

## Licença

Projeto privado.
