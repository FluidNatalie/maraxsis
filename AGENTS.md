# AGENTS.md

Guidance for agents (and humans) working in this repository.

## What this is

**Maraxsis** is a Factorio 2.1 *Space Age* mod (`info.json`: `factorio_version = "2.1"`, version
`1.39.22`, required deps `base >= 2.1.22`, `space-age`, `quality`, `PlanetsLib >= 1.20.3`,
`SpidertronPatrols >= 2.7.0`, `FluidMustFlow >= 1.5.0`). It adds a flooded ocean planet
(`maraxsis`) with submarines, pressure domes, a hydro plant, and a deep-sea trench
(`maraxsis-trench`).

**There is no build step.** The repository *is* the mod directory. Editing a file and reloading the
game is the build. `info.json` version bumps are handled by semantic-release, not by hand.

## Ground rules

1. **Validate before claiming success.** A change to any `data*.lua` / `prototypes/` file must
   survive `factorio --dump-data` with exit code 0 and no new warnings. A change to `control.lua`
   or `scripts/` must at least load (`--create`) and ideally be ticked (`--benchmark`). See
   [Validation workflow](#validation-workflow).
2. **Do not remove or rename a prototype that has shipped** without adding a migration under
   `migrations/` (see [Prototype conventions](#prototype-conventions)).
3. **Preserve the user's manual edits.** Several prototypes are hand-tuned (e.g. `selection_box`
   on `maraxsis-core-lava-cliff`). Read before you overwrite.
4. **Mirror vanilla.** New items/recipes/fluids are written field-for-field from their vanilla
   counterpart, with a comment naming the counterpart. Placeholder graphics reuse vanilla assets
   and say so in a comment.
5. Keep indentation at **4 spaces** (dominant in every directory; a handful of older files under
   `lib/` and `scripts/map-gen/` use tabs — match the file you are editing).

## Load-stage entry points

Each stage is a file in the mod root; require order inside them matters.

| File | Purpose |
| --- | --- |
| `data.lua` | Defines everything: `prototypes.mod-data.control-constants` → `scripts.constants` → `lib.lib` → entities → technologies → recipes → planet/tiles → compat. |
| `data-updates.lua` | Modifies *other* mods / base prototypes, item weight, item sounds, barrel fuel, factoriopedia text. Per-`compat.*` files live here and in `data-final-fixes.lua`. |
| `data-final-fixes.lua` | Collision masks (`collision-mask-util`), cross-mod conflict resolution, validation `error()`s. Runs after all other mods' `data-updates`. |
| `settings.lua` / `settings-updates.lua` | Startup settings; `settings-updates` locks/finalises other mods' settings. |
| `control.lua` | Requires every runtime script, then **must end with `maraxsis.finalize_events()`**. |

Put a change in `data-updates`/`data-final-fixes` (not `data.lua`) when it modifies prototypes
owned by base or another mod.

## Shared libraries (`lib/`)

* `lib/lib.lua` is the dispatcher. It inspects the environment and sets `maraxsis.stage` to
  `"settings" | "data" | "control"`, then requires `lib/data-stage.lua` or `lib/control-stage.lua`
  accordingly. So one helper file can serve both stages.
* `_G.maraxsis` is created in both `data.lua` and `control.lua`; helpers hang off it
  (`maraxsis.merge`, `maraxsis.on_event`, `maraxsis.shuffled_pairs`, ...).
* `_G.maraxsis_constants` is the `prototypes/mod-data/control-constants.lua` payload
  (`maraxsis_constants.TRENCH_SURFACE_NAME`, `.MARAXSIS_SURFACES`, ...). It is read in the data
  stage as `data.raw["mod-data"]["maraxsis-constants"].data`, and in the control stage as
  `prototypes.mod_data["maraxsis-constants"].data`. Constants live in the prototype so other mods
  can configure them.
* `lib/events.lua` provides `maraxsis.on_event(event, fn)` (multi-handler, unlike
  `script.on_event`), `maraxsis.on_nth_tick(n, fn)`, and the sentinel groups
  `maraxsis.events.on_init()`, `on_built()`, `on_destroyed()`. Everything is flushed by
  `maraxsis.finalize_events()` at the end of `control.lua`. `on_init` also runs on
  `on_configuration_changed`.
* `lib/data-stage.lua` has `maraxsis.merge(old, new)`: deep-copies `old`, applies `new`; the
  string `"nil"` **deletes** a key. This is the idiomatic way to fork a vanilla prototype.
* `lib/table.lua` is a module, **not** a global. Files that want it must do
  `local table = require("lib.table")` (this shadows the builtin `table`). It adds
  `Table.map`, `Table.find`, `Table.any`, ... — these are *not* Factorio builtins and are not
  available in other mods' files. **`Table.find` returns `value, key`** (value first, key second),
  which is why call sites read `local _, index = table.find(...)`.
* `PlanetsLib.rro` (`remove-replace-object`) is used for order-safe insertion/removal in shared
  lists (`rro.contains`, `rro.soft_insert`).

## Prototype conventions

* Recipes/items/fluids that are Maraxsis' own are prefixed `maraxsis-`; items that read like
  vanilla base materials (`nickel-plate`, `stainless-steel`, `nickel-ore`) are *not* prefixed.
* Maraxsis prototypes are grouped with other Maraxsis prototypes. Items, recipes and fluids that
  Maraxsis owns are placed in the mod's own `maraxsis-*` subgroups in
  `prototypes/item-subgroups.lua` (`make_subgroup`, e.g. `maraxsis-metallurgy`, `salt`,
  `advanced-fluids`) or in the `f[maraxsis-fluids]-*` block of the `fluid` subgroup
  (`order_subgroup`) — do *not* interleave them into the vanilla subgroup they were modelled on
  (`raw-resource`, `raw-material`, `vulcanus-processes`, ...). Single machines and combat items are
  the exception: they sit next to their vanilla counterpart, ordered off the vanilla prototype's
  order/name (e.g. `maraxsis-sonar` off `radar`, `maraxsis-big-pumpjack` off `pumpjack`,
  `maraxsis-fat-man` off `artillery-shell`), because Maraxsis has no machine subgroup of its own.
  Recipes are only given an order where they must not follow their product's item subgroup; like
  vanilla machine recipes, most have none.
* Item rocket weight: `prototypes/item-weight.lua` (`i_want_to_fit_this_many_per_rocket`).
  Item sounds: `prototypes/item-sounds.lua`. Both live in `data-updates.lua`.
* Locale lives in `locale/en/locale.cfg` under `[item-name]`, `[entity-name]`,
  `[entity-description]`, `[recipe-name]`, `[technology-name]`, `[fluid-name]`, ...
* Icon conventions: item/recipe/fluid icons are 120×64 with **no `icon_size`**; technology icons
  use `icon_size = 256`. Placeholder icons point at vanilla assets.
* Comments in this codebase use `---` doc comments for library functions (with LuaLS
  `---@param` / `---@return` annotations) and `--` for inline notes. There is a
  `.vscode/settings.json` with `Lua.diagnostics.globals` for the game globals.
* `migrations/*.json` carry save-compatibility renames for shipped prototypes that are renamed or
  removed. They are keyed by prototype type and hold `[old_name, new_name]` pairs:

  ```json
  {
      "recipe": [["maraxsis-sand", "maraxsis-sand-extraction"]],
      "item":   [["maraxsis-sand", "sand"]],
      "entity": [["cliff-maraxsis-collisionless", "cliff-maraxsis"]]
  }
  ```

## Third-party art (`tools/free-graphics/`)

`tools/free-graphics/` holds the authoring-time tools used to pull replacement art out of
[snouz's free graphics collection](https://github.com/snouz/factorio_free_graphics_for_modders)
and shape it into the house icon sheets: `ffg.py` (browse and fetch, with licence resolution),
`make_icon.py` (120×64 and 480×256 sheets, optional palette tint) and `extract_rocks.py`
(sprite-sheet cropping). Its README carries the exact commands behind the nickel chain and the
core lava cliff rocks.

Sourcing rules:

* `--tier permissive` only — MIT, CC BY, CC0, public domain, Apache, Mozilla, WTFPL. Never ship
  GPL/LGPL or CC BY-SA (they relicense this MIT mod), NC, Wube's EULA, or the catalogue's
  "ASK … FOR PERMISSION" and unknown-provenance files.
* Skip `icons_technology/Vanilla icons upscaled by snouz (CC BY)`: the folder is tagged CC BY, but
  the art underneath is Wube's.
* Anything that reaches `graphics/` gets a Creators / Source / License / Changes block in
  `CREDITS.md`, describing what was done to the art (cropped, rescaled, tinted, kitbashed).
* A placeholder is only worth replacing if it misleads the player. Referencing vanilla art from a
  prototype (`__base__/graphics/icons/iron-ore.png`) is legal and free of build cost; replacing it
  is about the icon being *wrong*, not about the licence.

## Validation workflow

The game *is* the test suite. Use a scratch mod directory so you never disturb the user's real
profile.

### 1. Scratch install

```
# config.ini
[path]
read-data=__PATH__executable__/../../data
write-data=/tmp/opencode/ft

[general]
locale=en
```

```
/tmp/opencode/ft/mods/
  mod-list.json                 # enable base, space-age, quality, elevated-rails, recycler,
                                # FluidMustFlow, PlanetsLib, SpidertronPatrols,
                                # SpidertronEnhancements, maraxsis, + scratch mods
  maraxsis -> <path to this repo>          # symlink
  PlanetsLib -> ~/Documents/GitHub/PlanetsLib   # dev checkout, tracks the version maraxsis needs
  SpidertronPatrols_2.7.1.zip -> /opt/factorio_space_age_21/mods/...
  FluidMustFlow_1.5.1.zip
  SpidertronEnhancements_1.11.0.zip
  zzz-scratch_1.0.0/            # throwaway probe mod (info.json required!)
```

Binary: `/opt/factorio_space_age_21/bin/x64/factorio`.

### 2. Data stage

```
factorio --config /tmp/opencode/ft/config.ini --dump-data
```

exit 0 → `script-output/data-raw-dump.json` (~33 MB). Grep it, don't open it. `log()` in the data
or control stage writes to stdout **and** to `factorio-current.log`, which is the only way to print
from the data stage.

### 3. Control stage

* Load check: `factorio --config ... --create /tmp/opencode/ft/smoke.zip` — runs `on_init` and
  logs `Finalized N events for maraxsis`. It does **not** tick.
* `--start-server` does **not** tick without a connected player.
* To actually run timers, chunk generation, and event handlers:
  `factorio --config ... --benchmark <save.zip> --benchmark-ticks 200`.
  Then read results from `script-output/` using `helpers.write_file(name, data, append)`
  (`game.write_file` was removed in 2.0+).
* Map generation is random per `--create`. To compare variants, either put several probe
  prototypes on one surface with **distinct** `autoplace.order`s (identical orders compete and
  only one wins), or create extra surfaces from a copy of the original surface's
  `map_gen_settings` and read noise expressions back with `calculate_tile_properties`.

### 4. Syntax

`luac -p <file>` for every touched Lua file. Cheap and catches most typos before a 40 s game load.

Always scan the run output for `Error`, `Warning`, and `nan`/`inf`:

```
grep -in "error\|warning\|nan\|inf" run.log
```

## Factorio 2.1 gotchas (learned the hard way)

### Cliffs

* `OrientedCliffPrototype` needs **all 20** orientation keys, each with `collision_bounding_box`
  and `pictures`. There is no single-orientation cliff. To fake one, give every orientation the
  same `pictures` *and* the same `collision_bounding_box` (this is what
  `maraxsis-core-lava-cliff` does).
* Cliffs have no health and are not entities that fire `on_entity_died` when removed by the
  `destroy-cliffs` trigger effect. The only cliff events are `on_pre_robot_exploded_cliff` /
  `on_robot_exploded_cliff` (robot path only). To react to a player destroying cliffs, use a
  `{type = "script", effect_id = "..."}` **target effect placed before** the `destroy-cliffs`
  effect and handle `on_script_trigger_effect` (see `prototypes/nuke-effects.lua` +
  `scripts/nukes.lua`, and `scripts/core-lava-cliff.lua`).
* `CliffPrototype.cliff_explosive` is documented to gate which explosive can destroy the cliff.
  That gating could **not** be reproduced headlessly (a script-created `destroy-cliffs` projectile
  destroys gated and ungated cliffs alike), and `DestroyCliffsTriggerEffectItem` carries no item
  reference, so treat the gate as unverified and test in a real game.
* Cliffs snap to `grid_size`/`grid_offset` (vanilla: `{4,4}` / `{0,0.5}`, i.e. a measured ~2.06
  tile offset). Pass `surface.create_entity{ ..., snap_to_grid = false }` to land exactly where you
  ask.
* The trench has **no** `cliff_settings`, so cliffs there must be scripted or autoplaced. Huge
  autoplace halos around sparse resources are the usual failure mode: neither the "cliffs spawn on
  lava" nor "cliffs spawn only on lava" variant is reliable with a probability expression, which is
  why `maraxsis-core-lava-cliff` is placed by `on_chunk_generated` instead.

### Autoplace / noise expressions

* `random_penalty{x = x, y = y, source = N, amplitude = A}` is effectively a binary mask: it
  returns `1` with probability `1/A` and a non-positive value otherwise. Multiplying several of
  these thins extremely fast. `place_every_n(n, n, x, y)` and `clamp(expr * a, 0, 1)` are the other
  thinning primitives.
* `clamp(var('default-<resource>-patches'), 0, 1)` is effectively binary (0 or ~1), which is why
  autoplace "halos" appear as whole-patch blobs.
* Declaring a cliff (or any entity) `autoplace` is not enough: it must also be listed in the
  surface's `map_gen_settings.autoplace_settings.entity.settings`. Entities with the same
  `autoplace.order` compete for the same cell.
* `resource_autoplace.initialize_patch_set(name, false)` creates the `default-<name>-patches`
  noise expression that a resource's own autoplace probability consumes.
* `create_entity` may overlap a resource entity; the resource survives. `on_chunk_generated` gives
  you `event.area` (a `BoundingBox`), `event.position` (`ChunkPosition`), `event.surface`,
  `event.tick`.

### Other

* In headless `--dump-data` output (`data-raw-dump.json`), single-element arrays are flattened and
  default `icon_size` is omitted — don't infer "missing icon_size" as a bug for 120×64 icons.
* `vanilla-changes.lua` and other `data-updates` code should use `table.deepcopy` before mutating
  a shared vanilla prototype.
* The mod ships a `restrict_surface_conditions` guard so Nauvis nuke effects only apply where
  pressure is low; keep Maraxsis-specific explosions keyed off surface properties rather than
  surface names where possible.

## Maraxsis domain knowledge

* Surfaces: `maraxsis`, `maraxsis-trench`, `maraxsis-factory-floor`,
  `maraxsis-trench-factory-floor` (see `maraxsis_constants.MARAXSIS_SURFACES` /
  `MARAXSIS_TRENCH_SURFACES`). The trench surface is `maraxsis-trench`; its origin area is mostly
  `maraxsis-trench-out-of-map` tiles, so `find_entities_filtered` near the origin sees very little.
* **Core lava** (defined in `prototypes/technology/nickel.lua`, alongside the chain it feeds): a
  resource *and* a fluid, trench-only, orange
  map colour, oil-like density. It can only be mined by `maraxsis-big-pumpjack` (purple fork of the
  vanilla pumpjack: 150% mining speed, 50% drain, `ducts` connection category). Graphics are forked
  from vanilla and recoloured with `graphics/hue-shift-green-to-purple.sh`.
  It lives here rather than in `prototypes/planet/` because `PlanetsLib.melting_icon` resolves
  prototype icons **at call time**, so core lava must already exist when the nickel recipes that
  draw it into their composite icons are created.
* **Nickel chain** (`prototypes/technology/nickel.lua`): `nickel-ore` (item only — no ore
  resource/autoplace; the cliff drop is its only source), `nickel-ore-melting` (→ `molten-nickel`),
  `molten-nickel` (deepcopy of vanilla `molten-iron`, teal), `casting-nickel` (→ `nickel-plate`),
  `stainless-steel` (molten iron + molten nickel). All recipes are `categories = {"metallurgy"}` and
  gated behind the mod's own `maraxsis-nickel-processing` technology (prereq
  `hydraulic-science-pack`), not the vanilla `foundry` tech.
* **Core lava cliff** (`maraxsis-core-lava-cliff`): looks like a rock (huge-rock dimensions +
  placeholder graphics), 20 identical orientations, no autoplace. Placed by
  `scripts/map-gen/maraxsis-trench.lua` on `on_chunk_generated`: for each `core-lava` entity in the
  chunk it spawns a cliff exactly on top (skipping any within `CORE_LAVA_CLIFF_SPACING` of an
  existing cliff). It gates on `cliff_explosive = "maraxsis-big-cliff-explosives"`. Destroying one
  dispenses **20 `nickel-ore`**, implemented in `scripts/core-lava-cliff.lua` via the
  `maraxsis-core-lava-cliff-destroyed` script effect inserted into the big cliff explosive
  projectile before `destroy-cliffs` (see `prototypes/technology/depth-charges.lua` and
  `maraxsis.index_of_destroy_cliffs` in `lib/data-stage.lua`).
* `maraxsis-big-cliff-explosives` (`prototypes/technology/depth-charges.lua`): recipe needs
  `cliff-explosives` + `atomic-bomb` + `maraxsis-super-sealant-substance`, and its result is
  `quality_min = "legendary"`; capsule action destroys cliffs at radius 100, projectile at radius
  450. Verified target-effect order after mods: `destroy-decoratives`, `create-decorative`,
  `script`, `destroy-cliffs`, `nested-result`.
## Local dev environment (this machine)

* Factorio 2.1.22 binary: `/opt/factorio_space_age_21/bin/x64/factorio`.
  User config: `/opt/factorio_space_age_21/config/config.ini`; the user's real mod directory is
  `/opt/factorio_space_age_21/mods` (which contains a symlink `maraxsis -> this repo`).
* Scratch harness: `/tmp/opencode/ft` (config.ini + `mods/`). `/tmp` is volatile — it has been
  wiped between sessions before, so rebuild rather than assume.
* Validation runs take ~2 s of data load + a few seconds of startup; a `--benchmark` run of a few
  hundred ticks takes a couple of minutes.
* ImageMagick on this machine is 6.9 — the command is `convert`, not `magick`. Recolouring scripts
  in `graphics/` read/write files in place, so restore the originals from git before re-running
  them (`git show <rev>:<path> > <path>`).

## Git / release conventions

* Conventional Commits drive semantic-release (`.releaserc`): `feat`/`feature` → minor;
  `fix`, `balance`, `graphics`, `sound`, `locale`, `translate`, `compat`, `control`, `gui`,
  `perf`, `info`, `other` → patch. Write descriptive commit bodies for balance changes.
* Only the `main` branch is released; feature work happens on branches like `world-gen-update`.
* `changelog.txt` and `info.json` version are maintained by the release tooling — do not hand-edit
  the version.
