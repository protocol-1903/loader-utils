require "__perel__.util.scripts.general"

local mod_data = assert(prototypes.mod_data["loader-utils"], "ERROR: mod-data for loader-utils not found!")
local base_loaders = assert(mod_data.data.base_loaders, "ERROR: data.base_loaders for loader-utils not found!")
local loader_ids = assert(mod_data.data.loader_ids, "ERROR: data.loader_ids for loader-utils not found!")
local modded_loaders = assert(mod_data.data.modded_loaders, "ERROR: data.modded_loaders for loader-utils not found!")

local event_filter = {{filter = "type", type = "loader"}, {filter = "type", type = "loader-1x1"}, {filter = "ghost_type", type = "loader"}, {filter = "ghost_type", type = "loader-1x1"}}

script.on_configuration_changed(function ()
  for _, player in pairs(game.players) do
    if player.gui.relative["loader-utils-ui"] then
      player.gui.relative["loader-utils-ui"].destroy()
    end
  end
end)

script.on_init(function()
  if helpers.compare_versions(script.active_mods["loaders-modernized"], "2.0.5") >= 0 then
    remote.call("loaders-modernized", "disable_snapping")
  end
end)

script.on_load(function()
  if helpers.compare_versions(script.active_mods["loaders-modernized"], "2.0.5") >= 0 then
    remote.call("loaders-modernized", "disable_snapping")
  end
end)

-- parse modded_loaders to convert ["0"] into [0]
for i, tabledata in pairs(modded_loaders) do
  for j, name in pairs(tabledata) do
    modded_loaders[i][j + 0] = name
    modded_loaders[i][j] = nil
  end
end

---@param old_entity LuaEntity
---@param player_index uint32
---@param new_id uint32
---@return LuaEntity?
local function replace(old_entity, player_index, new_id)
  -- swap open the new loader gui if the old loader gui is opened
  local player = player_index and game.get_player(player_index)
  local opened = player and player.opened == old_entity
  local old_name = old_entity.name == "entity-ghost" and old_entity.ghost_name or old_entity.name

  -- return if entity, id, or base type not found
  if not old_entity or not new_id or not base_loaders[old_name] then return end

  local surface = old_entity.surface
  local parameters = {
    name = old_entity.name == "entity-ghost" and "entity-ghost" or modded_loaders[base_loaders[old_entity.name]][new_id] or base_loaders[old_entity.name],
    ghost_name = old_entity.name == "entity-ghost" and modded_loaders[base_loaders[old_entity.ghost_name]][new_id] or base_loaders[old_entity.name] or nil,
    position = old_entity.position,
    direction = old_entity.direction,
    quality = old_entity.quality,
    type = old_entity.loader_type,
    force = old_entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
    raise_built = true,
    fast_replace = true,
    spill = false
  }
  local control_behavior = old_entity.get_control_behavior()
  local control_data = control_behavior and {
    set_filters = control_behavior.circuit_set_filters,
    read_transfers = control_behavior.circuit_read_transfers,
    enable = control_behavior.circuit_enable_disable,
    circuit_condition = control_behavior.circuit_condition,
    connect_to_logistic_network = control_behavior.connect_to_logistic_network,
    logistic_condition = control_behavior.logistic_condition,
  }
  local stacking = old_entity.prototype.loader_adjustable_belt_stack_size and old_entity.loader_belt_stack_size_override or nil
  local mode = old_entity.loader_filter_mode
  local red_connections = {}
  local green_connections = {}
  local fluid
  local filters = {}

  local stack = player and player.undo_redo_stack
  if stack then
    local item = perel.find_build_item(stack, old_entity)
    if item then
      parameters.player = player.index
      parameters.undo_index = item
    end
  end

  -- save filters
  for i=1, old_entity.filter_slot_count do
    filters[i] = old_entity.get_filter(i)
  end

  for _, connection in pairs((old_entity.get_wire_connector(defines.wire_connector_id.circuit_red) or {}).connections or {}) do
    red_connections[#red_connections+1] = connection.target
  end

  for _, connection in pairs((old_entity.get_wire_connector(defines.wire_connector_id.circuit_green) or {}).connections or {}) do
    green_connections[#green_connections+1] = connection.target
  end

  -- find AAI pipe entity (if it exists)
  if old_entity.name:sub(1, 4) == "aai-" and settings.startup["aai-loaders-mode"].value == "lubricated" and prototypes.entity[old_entity.name .. "-pipe"] then
    local old_pipe = surface.find_entities_filtered{name = old_entity.name .. "-pipe", position = old_entity.position, limit = 1}[1]
    if old_pipe then
      fluid = old_pipe.get_fluid(1)
      old_pipe.destroy()
    end
  end

  local new_entity = surface.create_entity(parameters)
  if not new_entity then return end

  -- copy circuit connections
  if #red_connections ~= 0 then
    for _, target in pairs(red_connections) do
      new_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(target)
    end
  end
  if #green_connections ~= 0 then
    for _, target in pairs(green_connections) do
      new_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connect_to(target)
    end
  end

  -- update stack size if appliccable
  if stacking and new_entity.prototype.loader_adjustable_belt_stack_size then
    new_entity.loader_belt_stack_size_override = stacking
  end

  -- set filter(s) and circuit controls
  if mode then new_entity.loader_filter_mode = mode end

  -- apply as many filters as possible
  for j, filter in pairs(filters) do
    if j <= new_entity.filter_slot_count then
      new_entity.set_filter(j, filter)
    else
      local i = 1
      for _, filter in pairs(filters) do
        new_entity.set_filter(i, filter)
        if i == new_entity.filter_slot_count then break end
        i = i + 1
      end
      break
    end
  end

  if control_data then
    local new_control = new_entity.get_or_create_control_behavior()

    new_control.circuit_set_filters = control_data.set_filters
    new_control.circuit_read_transfers = control_data.read_transfers
    new_control.circuit_enable_disable = control_data.enable
    new_control.circuit_condition = control_data.circuit_condition
    new_control.connect_to_logistic_network = control_data.connect_to_logistic_network
    new_control.logistic_condition = control_data.logistic_condition
  end

  -- remove 'remove old entity' action
  if stack and parameters.undo_index then
    for a, action in pairs(stack.get_undo_item(parameters.undo_index)) do
      if action.type == "removed-entity" and
        action.surface_index == new_entity.surface_index and
        action.target.name == old_name and
        action.target.position.x == new_entity.position.x and
        action.target.position.y == new_entity.position.y then
        stack.remove_undo_action(parameters.undo_index, a)
      end
    end
  end

  -- find AAI pipe item (if it exists)
  if new_entity.name:sub(1, 4) == "aai-" and settings.startup["aai-loaders-mode"].value == "lubricated" then
    local new_pipe = surface.find_entities_filtered{name = new_entity.name .. "-pipe", position = new_entity.position}[1]

    -- if new_pipe then
    if new_pipe and fluid then
      -- refill fluidbox
      new_pipe.fluidbox[1] = fluid
    end
  end

  if opened then
    player.opened = new_entity
  end

  return new_entity
end

-- copy paste settings, but change the mode if they are different
---@param event EventData.on_entity_settings_pasted
script.on_event(defines.events.on_entity_settings_pasted, function (event)

  local source_id = loader_ids[event.source.name == "entity-ghost" and event.source.ghost_name or event.source.name]
  local destination_id = loader_ids[event.destination.name == "entity-ghost" and event.destination.ghost_name or event.destination.name]

  if not source_id or not destination_id then return end

  -- make sure both are valid entities
  if source_id ~= destination_id then
    -- two different styles, need to swap the destination to match the source
    local entity = event.destination
    local player = game.get_player(event.player_index)
    local item = {name = entity.prototype.mineable_properties.products[1].name, quality = entity.quality}
    local amount = player.get_main_inventory() and player.get_main_inventory().get_item_count(item)
    replace(entity, event.player_index, source_id)
    if player.controller_type ~= defines.controllers.remote then
      item.count = amount + 1
      player.get_main_inventory().remove(item)
      if amount > 0 then
        item.count = amount
        player.get_main_inventory().insert(item)
      end
    end
  end

  game.get_player(event.player_index).play_sound{path = "utility/entity_settings_pasted"}
end)

local bitmask = {
  lf = 0,
  rl = 1,
  fs = 2
}

-- update gui events
---@param event EventData.on_gui_checked_state_changed
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() ~= "loader-utils" then return end
  local player = game.get_player(event.player_index)
  local entity = player.opened
  if entity.name == "entity-ghost" then
    local tags = entity.tags or {}
    tags["loader-utils"] = (tags["loader-utils"] or 0) + (event.element.state and 1 or -1) * 2 ^ bitmask[event.element.name]
    entity.tags = tags
  else
    local item = {name = entity.prototype.mineable_properties.products[1].name, quality = entity.quality}
    local amount = player.get_main_inventory() and player.get_main_inventory().get_item_count(item)
    replace(entity, event.player_index, loader_ids[entity.name] + (event.element.state and 1 or -1) * 2 ^ bitmask[event.element.name])
    if player.controller_type ~= defines.controllers.remote then
      item.count = amount + 1
      player.get_main_inventory().remove(item)
      if amount > 0 then
        item.count = amount
        player.get_main_inventory().insert(item)
      end
    end
  end
end)

local just_destroyed = {}
local masking = {
  [defines.events.on_player_mined_entity] = defines.events.on_built_entity,
  [defines.events.on_robot_mined_entity] = defines.events.on_robot_built_entity,
  [defines.events.on_space_platform_mined_entity] = defines.events.on_space_platform_built_entity,
  [defines.events.script_raised_destroy] = defines.events.script_raised_built,
  [defines.events.on_entity_died] = defines.events.script_raised_revive,
}
local snap_targets = {
  "container",
  "logistic-container",
  "linked-container",
  "infinity-container",
  "assembling-machine",
  "furnace",
  "rocket-silo",
  "mining-drill",
  "lab",
  "boiler",
  "reactor",
  "fusion-reactor",
  "ammo-turret",
  "artillery-turret",
  "straight-rail",
  "agricultural-tower",
  "asteroid-collector",
}

--- @param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity|EventData.script_raised_built|EventData.script_raised_revive
local function on_built(event)
  -- if player has setting enabled, then replace with custom
  local player = event.player_index and game.get_player(event.player_index)
  local entity = event.entity
  local id = event.tags and event.tags["loader-utils"] or
    just_destroyed.tick == event.tick and masking[just_destroyed.event] == event.name and just_destroyed.id or player and (
    (player.mod_settings["lu-lf-default"].value and 1 or 0) +
    (player.mod_settings["lu-rl-default"].value and 2 or 0) +
    (player.mod_settings["lu-fs-default"].value and 4 or 0)) or nil
  just_destroyed = {}
  if id and id ~= 0 and entity.name ~= "entity-ghost" then
    local item = {
      name = entity.prototype.mineable_properties.products[1].name,
      quality = entity.quality
    }
    entity = replace(entity, event.player_index, id)
    if player then
      if player.cursor_stack and player.cursor_stack.valid_for_read then
        player.cursor_stack.count = player.cursor_stack.count - 1
      elseif player.is_cursor_empty() then
        -- just placed last item, remove from inventory
        player.get_main_inventory().remove(item)
      end
    end
  elseif id and entity.name == "entity-ghost" then
    local tags = entity.tags or {}
    tags["loader-utils"] = tags["loader-utils"] or id
    entity.tags = tags
  end
  -- just checking to make sure someone else didnt screw something up
  if player and entity and entity.valid and player.mod_settings["lu-enable-snapping"].value then
    -- attempt snapping
    local surface = entity.surface
    local force = entity.force
    local loader_position = entity.position
    local direction = entity.direction
    local type = entity.loader_type
    local output = entity.loader_type == "output"
    local x, y = loader_position.x, loader_position.y
    local dir = {
      [0] = {x = 0, y = 1},
      {x = -1, y = 0},
      {x = 0, y = -1},
      {x = 1, y = 0}
    }
    local belt = {x = x + dir[entity.direction/4].x, y = y + dir[entity.direction/4].y}
    local target = {x = x - dir[entity.direction/4].x, y = y - dir[entity.direction/4].y}
    local alt = {
      input = "output",
      output = "input"
    }

    if entity.belt_neighbours[type .. "s"][1] then return end
    local connected = entity.type ~= "entity-ghost" and not not entity.loader_container
    entity.loader_type = alt[type]
    if entity.belt_neighbours[alt[type] .. "s"][1] then return end
    entity.direction = direction
    entity.update_connections()
    if entity.belt_neighbours[alt[type] .. "s"][1] then return end
    entity.loader_type = type
    if entity.belt_neighbours[type .. "s"][1] then return end

    if connected or
        surface.count_entities_filtered{ghost_type=snap_targets, position=output and belt or target, force=force, limit=1} > 0 or
        surface.count_entities_filtered{type="straight-rail", position=output and belt or target, force=force, limit=1} > 0 or
        (not connected and
        surface.count_entities_filtered{ghost_type=snap_targets, position=output and target or belt, force=force, limit=1} == 0 and
        surface.count_entities_filtered{type="straight-rail", position=output and target or belt, force=force, limit=1} == 0) then
      entity.loader_type = type
      entity.direction = direction
    end
  end
end

script.on_event(defines.events.on_built_entity, on_built, event_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, event_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, event_filter)
script.on_event(defines.events.script_raised_built, on_built, event_filter)
script.on_event(defines.events.script_raised_revive, on_built, event_filter)

--- @param event EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_space_platform_mined_entity|EventData.script_raised_destroy|EventData.on_entity_died
local function on_destroyed(event)
  just_destroyed = {
    tick = event.tick,
    event = event.name,
    id = loader_ids[event.entity.name == "entity-ghost" and event.entity.ghost_name or event.entity.name]
  }
end

script.on_event(defines.events.on_player_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_space_platform_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, event_filter)
script.on_event(defines.events.on_entity_died, on_destroyed, event_filter)

---@param event EventData.on_gui_opened
script.on_event(defines.events.on_gui_opened, function (event)
  local entity = event.entity
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local name = entity and (entity.name == "entity-ghost" and entity.ghost_name or entity.name)

  -- if loader opened, handle it
  if type == "loader" or type == "loader-1x1" then
    local player = game.get_player(event.player_index)
    local id = entity.tags and entity.tags["loader-utils"] or loader_ids[name]
    if not id then return end
    local gui = player.gui.relative["loader-utils-ui"]

    if not gui then
      -- create gui
      gui = player.gui.relative.add{
        type = "frame",
        name = "loader-utils-ui",
        caption = { "loader-utils-ui.frame" },
        direction = "horizontal",
        anchor = {
          gui = defines.relative_gui_type.loader_gui,
          position = defines.relative_gui_position.right
        }
      }
      gui.add{
        type = "frame",
        name = "sub",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical",
      }

      gui.sub.add{
        type = "checkbox",
        name = "lf",
        style = "caption_checkbox",
        caption = { "loader-utils-ui.checkbox-lf" },
        state = false
      }
      gui.sub.add{
        type = "checkbox",
        name = "rl",
        style = "caption_checkbox",
        caption = { "loader-utils-ui.checkbox-rl" },
        state = false
      }
      gui.sub.add{
        type = "checkbox",
        name = "fs",
        style = "caption_checkbox",
        caption = { "loader-utils-ui.checkbox-fs" },
        state = false
      }.visible = script.feature_flags.space_travel
    end

    -- update GUI
    gui.sub.lf.state = bit32.band(id, 1) ~= 0
    gui.sub.rl.state = bit32.band(id, 2) ~= 0
    gui.sub.fs.state = bit32.band(id, 4) ~= 0
  end
end)

---@param event EventData.on_player_setup_blueprint
script.on_event(defines.events.on_player_setup_blueprint, function (event)
	local player = game.get_player(event.player_index)
	local blueprint = player.blueprint_to_setup
  -- if normally invalid
	if not blueprint or not blueprint.valid_for_read then blueprint = player.cursor_stack end
  -- if non existant, cancel
  local entities = blueprint and blueprint.get_blueprint_entities()
  if not entities then return end
  local changed = false
  -- update entities
  for _, entity in pairs(entities) do
    if base_loaders[entity.name] then
      changed = true
      local tags = entity.tags or {}
      tags["loader-utils"] = tags["loader-utils"] or loader_ids[entity.name]
      entity.tags = tags
      entity.name = base_loaders[entity.name] or entity.name
    end
  end
  if not changed then return end -- make no changes unless required
  blueprint.set_blueprint_entities(entities)
end)