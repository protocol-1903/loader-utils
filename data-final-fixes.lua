local base_loaders, loader_ids, modded_loaders = {}, {}, {}

local function make_copy(old, id)
  if mods["aai-loaders"] and old.name:find("aai%-") then
    local name = AAILoaders.make_tier {
      name = id .. (old.name == "aai-loader" and "" or "-" .. old.name:sub(5, -8)),
      transport_belt = "transport-belt",
      recipe = {},
      unlubricated_recipe = {}
    }.loader.name
    data.raw.item[name] = nil
    data.raw.recipe[name] = nil
  end
  local new = table.deepcopy(old)
  new.localised_name = old.localised_name or { "entity-name." .. old.name }
  new.localised_description = old.localised_description or { "entity-description." .. old.name }
  new.hidden_in_factoriopedia = true
  new.hidden = true

  --[[
    {
      name = old.name == "aai-loader" and "lane" or "lane-" .. old.name:sub(5, -8),
      transport_belt = "transport-belt",
      speed = old.speed,
      color = {1, 1, 1},
      fast_replaceable_group = old.fast_replaceable_group,
      fluid = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old.name .. "-pipe"].fluid_box.filter or nil,
      fluid_per_minute = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old.name .. "-pipe"].fluid_box.volume - 100 or nil,
      recipe = {energy_required = 1},
      unlubricated_recipe = {energy_required = 1},
      collision_mask = old.collision_mask,
      upgrade = old.next_upgrade and "aai-lane-" .. old.next_upgrade:sub(5) or nil,
      localise = true
    }
  ]]
  return new
end

-- mark existing loaders as base loaders
for _, prototypes in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for _, loader in pairs(prototypes) do
  base_loaders[loader.name] = loader.name
  modded_loaders[loader.name] = {[0] = loader.name}
  loader_ids[loader.name] = ""
  loader.per_lane_filters = false
  loader.wait_for_full_stack = false
  loader.respect_insert_limits = false
end end

for _, prototype in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for bit, id in pairs {
  [0] = settings.startup["loader-utils-lane-filtering"].value and "lf" or nil,
  settings.startup["loader-utils-full-stacks"].value and "fs" or nil,
  settings.startup["loader-utils-respect-limits"].value and "rl" or nil
} do for _, old in pairs(prototype) do
  local new = make_copy(old) ---@cast new data.LoaderPrototype

  if id == "lf" then
    new.filter_count = 2
    new.per_lane_filters = true
  elseif id == "fs" then
    new.wait_for_full_stack = true
  elseif id == "rl" then
    new.respect_insert_limits = true
  end

  -- save the ID and lookup
  loader_ids[new.name] = loader_ids[old.name] + 2^bit
  base_loaders[new.name] = base_loaders[old.name]
  modded_loaders[base_loaders[new.name]][loader_ids[new.name]] = new.name
end end end

data:extend{{
  type = "mod-data",
  name = "loader-utils",
  data = {
    base_loaders = base_loaders,
    loader_ids = loader_ids,
    modded_loaders = modded_loaders
  }
}}