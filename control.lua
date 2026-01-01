assert(prototypes.mod_data["lane-filtered-loaders"], "ERROR: mod-data for lane-filtered-loaders not found!")
local alt_loaders = assert(prototypes.mod_data["lane-filtered-loaders"].data.alt_loaders, "ERROR: data.alt_loaders for lane-filtered-loaders not found!")
local lane_filtered_loaders = assert(prototypes.mod_data["lane-filtered-loaders"].data.lane_filtered_loaders, "ERROR: data.lane_filtered_loaders for lane-filtered-loaders not found!")

local function replace(old_entity, player)
  -- swap open the new loader gui if the old loader gui is opened
  local swap_gui = player and player.opened == old_entity

  local surface = old_entity.surface
  local parameters = {
    name = old_entity.type == "entity-ghost" and "entity-ghost" or alt_loaders[old_entity.type == "entity-ghost" and old_entity.ghost_name or old_entity.name],
    ghost_name = alt_loaders[old_entity.type == "entity-ghost" and old_entity.ghost_name or old_entity.name],
    position = old_entity.position,
    direction = old_entity.direction,
    quality = old_entity.quality,
    loader_type = old_entity.loader_type,
    force = old_entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
    raise_built = true,
    fast_replace = true
  }
  local control_data = {
    set_filters = old_entity.get_or_create_control_behavior().circuit_set_filters,
    read_transfers = old_entity.get_or_create_control_behavior().circuit_read_transfers,
    enable = old_entity.get_or_create_control_behavior().circuit_enable_disable,
    circuit_condition = old_entity.get_or_create_control_behavior().circuit_condition,
    connect_to_logistic_network = old_entity.get_or_create_control_behavior().connect_to_logistic_network,
    logistic_condition = old_entity.get_or_create_control_behavior().logistic_condition,
  }
  local stack = old_entity.prototype.loader_adjustable_belt_stack_size and old_entity.loader_belt_stack_size_override or nil
  local mode = old_entity.loader_filter_mode
  local red_connections = {}
  local green_connections = {}
  local fluid
  local filters = {}

  -- save filters
  for i=1, old_entity.filter_slot_count do
    filters[#filters+1] = old_entity.get_filter(i)
  end

  for _, connection in pairs(old_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connections) do
    red_connections[#red_connections+1] = connection.target
  end

  for _, connection in pairs(old_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connections) do
    green_connections[#green_connections+1] = connection.target
  end

  -- find AAI pipe item (if it exists)
  if old_entity.name:sub(1, 4) == "aai-" and settings.startup["aai-loaders-mode"].value == "lubricated" then
    local old_pipe = surface.find_entities_filtered{name = old_entity.name .. "-pipe", position = old_entity.position}[1]

    -- store fluid data
    if old_pipe then
      fluid = old_pipe.get_fluid(1)
    end
  end

  -- delete old loader
  old_entity.destroy{raise_destroy = true}

  -- create new loader
  new_entity = surface.create_entity(parameters)

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
  if stack and new_entity.prototype.loader_adjustable_belt_stack_size then
    new_entity.loader_belt_stack_size_override = stack
  end

  -- set filter(s) and circuit controls
  if mode then new_entity.loader_filter_mode = mode end
  if #filters <= new_entity.filter_slot_count then
    for i, filter in pairs(filters) do
      new_entity.set_filter(i, filter)
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

  -- find AAI pipe item (if it exists)
  if new_entity.name:sub(1, 4) == "aai-" and settings.startup["aai-loaders-mode"].value == "lubricated" then
    local new_pipe = surface.find_entities_filtered{name = new_entity.name .. "-pipe", position = new_entity.position}[1]

    -- if new_pipe then
    if new_pipe and fluid then
      -- refill fluidbox
      new_pipe.fluidbox[1] = fluid
    end
  end

  if swap_gui then
    player.opened = new_entity
  end

  return new_entity
end

remote.add_interface("lane-filtered-loaders",
  {
    ["build-check"] = function (entity, player)
      if player.mod_settings["loaders-lane-filtered-by-default"].value then
        replace(entity, player)
      end
    end
  }
)

-- copy paste settings, but change the mode if they are different
script.on_event(defines.events.on_entity_settings_pasted, function (event)

  local source = event.source.type == "entity-ghost" and event.source.ghost_prototype or event.source.prototype
  local destination = event.destination.type == "entity-ghost" and event.destination.ghost_prototype or event.destination.prototype

  -- make sure both are valid entities
  if lane_filtered_loaders[source.name] == nil or lane_filtered_loaders[destination.name] == nil then return end

  if lane_filtered_loaders[source.name] ~= lane_filtered_loaders[destination.name] then
    -- two different styles, need to swap the destination to match the source
    replace(event.destination, game.players[event.player_index])
  end

  game.players[event.player_index].play_sound{path = "utility/entity_settings_pasted"}
end)

-- update gui events
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() == "lane-filtered-loaders" and event.element.name == "checkbox-lane" then
    replace(game.players[event.player_index].opened, game.players[event.player_index])
  end
end)

-- only register event if the event filter exists, i.e. another mod hasn't overridden it (such as loaders make full stacks)
if prototypes.mod_data["lane-filtered-loaders"].data.build_event_filter then
  assert(#prototypes.mod_data["lane-filtered-loaders"].data.build_event_filter ~= 0, "ERROR: data.build_event_filter for lane-filtered-loaders not found!")
  script.on_event(defines.events.on_built_entity, function (event)
    -- if player has setting enabled, then replace with custom
    if game.players[event.player_index].mod_settings["loaders-lane-filtered-by-default"].value then
      replace(event.entity, game.players[event.player_index])
    end
  end, prototypes.mod_data["lane-filtered-loaders"].data.build_event_filter)
end

-- when loader gui opened add custom gui
script.on_event(defines.events.on_gui_opened, function (event)
  local entity = event.entity and (event.entity.type == "entity-ghost" and event.entity.ghost_type or event.entity.type)

  -- if loader opened, handle it
  if entity == "loader" or entity == "loader-1x1" then
    local player = game.players[event.player_index]

    -- if gui exists then delete it
    if player.gui.relative["lfl-frame"] then
      player.gui.relative["lfl-frame"].destroy()
    end

    -- create gui
    player.gui.relative.add{
      type = "frame",
      name = "lfl-frame",
      caption = { "lfl-window.frame" },
      direction = "horizontal",
      anchor = {
        gui = defines.relative_gui_type.loader_gui,
        position = defines.relative_gui_position.right
      }
    }.add{
      type = "frame",
      name = "inner-frame",
      style = "inside_shallow_frame_with_padding",
      direction = "vertical",
    }.add{
      type = "checkbox",
      name = "checkbox-lane",
      style = "caption_checkbox",
      caption = { "lfl-window.checkbox-lane" },
      state = lane_filtered_loaders[event.entity and (event.entity.type == "entity-ghost" and event.entity.ghost_name or event.entity.name)]
    }
  end
end)

-- when loader gui closed delete the custom gui, if it exists
script.on_event(defines.events.on_gui_closed, function (event)
  -- if loader opened, handle it
  if event.entity and event.entity.type == "loader" or event.entity and event.entity.type == "loader-1x1" then
    local player = game.players[event.player_index]
    if player.gui.relative["lfl-frame"] then
      player.gui.relative["lfl-frame"].destroy()
    end
  end
end)