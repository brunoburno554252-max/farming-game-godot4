# 🌾 Farming Game — Godot 4

Jogo de fazenda estilo Stardew Valley com arquitetura profissional, escalável e otimizada para mobile Android.

## Como Rodar

1. **Godot 4.3+** instalado
2. Instalar addon [godot-sqlite](https://github.com/2shady4u/godot-sqlite) (copiar para `addons/`)
3. Abrir o projeto no Godot
4. Rodar (F5) — abre na tela de título

## Arquitetura

Baseada na análise do código-fonte real do Stardew Valley (descompilado), adaptada para Godot 4 com GDScript.

### Sistemas Autoload (11 singletons)

| Sistema | Descrição |
|---------|-----------|
| `EventBus` | Barramento de sinais centralizado (~56 sinais) |
| `GameManager` | Orquestrador central, state management, save/load |
| `TimeSystem` | Ciclo de dia 20h (6AM-2AM), estações, calendário |
| `WeatherSystem` | Clima diário com probabilidades por estação |
| `LocationManager` | Carregamento de locations com cache |
| `SceneTransition` | Fade in/out, warp points, transições de dia |
| `InventorySystem` | Itens com qualidade, stacks, hotbar, gold |
| `UIManager` | Stack de menus com pause automático |
| `AudioManager` | Pool de SFX, crossfade de música, música por location/estação |
| `DialogueManager` | Diálogos com choices, tokens dinâmicos |
| `DatabaseManager` | SQLite com 12 tabelas, WAL mode |

### Classes Core

| Classe | Tipo | Descrição |
|--------|------|-----------|
| `Constants` | Enums | 12 enums, 30+ constantes |
| `StateMachine` | Engine | Máquina de estados genérica |
| `State` | Engine | Classe base para estados |
| `GameLocation` | World | Base de todas as locations |
| `TerrainFeature` | World | Objeto no chão (base) |
| `HoeDirt` | Farming | Solo arado com crop |
| `Crop` | Farming | Planta com fases de crescimento |
| `PlayerController` | Player | Movimento, ferramentas, interação |
| `ToolSystem` | Player | Uso de ferramentas no mundo |
| `ItemData` | Data | Resource de item |
| `CropData` | Data | Resource de crop |
| `ItemDatabase` | Data | Registro de todos os itens (63 itens, 14 crops) |

### UI System

| Componente | Descrição |
|------------|-----------|
| `HUD` | Hotbar (12 slots), barra de energia, relógio, gold, clima |
| `InventoryMenu` | Grid 4x12 com swap, info do item, separação hotbar/mochila |
| `ShopMenu` | Comprar/vender com tabs, quantidade, detalhes |
| `PauseMenu` | Continuar, inventário, salvar, configurações, sair |
| `DialogueBox` | Typewriter text, choices, indicador de continuar |
| `DayEndSummary` | Resumo de itens shipped e ganhos |
| `TitleScreen` | Novo jogo, carregar, sair |
| `VirtualJoystick` | Joystick dinâmico touch (mobile) |
| `MobileActionButtons` | Botões A/B/INV/PAUSE touch |

## Conteúdo Incluído

### Itens (63)
- **7 Ferramentas**: Enxada, Regador, Machado, Picareta, Foice, Vara de Pesca, Espada
- **14 Sementes**: 5 Primavera, 5 Verão, 4 Outono
- **14 Colheitas**: Correspondentes às sementes
- **13 Recursos**: Madeira, Pedra, Fibra, Minérios, Barras, etc.
- **5 Comidas**: Com restauração de energia
- **6 Itens de Coleta** (forage)
- **9 Craftáveis**: Baú, Irrigadores, Espantalho, Fornalha, etc.

### Crops (14)
Cada crop tem fases de crescimento, estações válidas, chance de regrow, XP de colheita.

## Banco de Dados (SQLite)

12 tabelas: game_state, player, inventory, equipment, terrain_features, crops, placed_objects, npc_friendship, skills, unlocked_recipes, completed_events, shipping_log.

## Estrutura de Pastas

```
farming_game/
├── autoloads/          # 11 Singletons globais
├── classes/            # Constants, StateMachine, State
├── data/
│   ├── items/          # ItemData + ItemDatabase
│   └── crops/          # CropData
├── locations/
│   ├── farm/           # Farm (.gd + .tscn)
│   ├── house/          # Farmhouse (.gd + .tscn)
│   ├── town/           # Town, Beach, Mountain, Forest, Saloon (.tscn)
│   ├── shop/           # General Store, Blacksmith (.tscn)
│   ├── mine/           # Mine (.tscn)
│   └── game_location.gd
├── player/
│   ├── player_controller.gd
│   ├── tool_system.gd
│   └── states/         # Idle, Walk, Tool, Interact
├── terrain_features/   # TerrainFeature, HoeDirt, Crop
├── ui/
│   ├── hud/            # HUD principal
│   ├── menus/          # Inventory, Pause, Shop, Title, DayEnd
│   ├── dialogue/       # DialogueBox
│   └── components/     # VirtualJoystick, MobileActionButtons
├── scenes/             # main.tscn (entry point)
├── audio/              # music/, sfx/
├── effects/
├── objects/
└── shaders/
```

## Licença

Projeto privado.
