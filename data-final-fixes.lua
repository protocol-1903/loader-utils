local base_loaders, loader_ids, modded_loaders = {}, {}, {}

local blacklist = {
  ["ee-infinity-loader"] = true
}

---@param old data.LoaderPrototype
---@param id uint8
---@return data.LoaderPrototype
local function make_copy(old, id)
  local new = table.deepcopy(old)
  new.name = id .. "-" .. old.name
  if mods["aai-loaders"] and old.name:find("aai%-") then
    local name = AAILoaders.make_tier {
      name = id .. (old.name == "aai-loader" and "" or "-" .. old.name:sub(5, -8)),
      transport_belt = "transport-belt",
      fluid = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old.name .. "-pipe"] and data.raw["storage-tank"][old.name .. "-pipe"].fluid_box.filter or nil,
      fluid_per_minute = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old.name .. "-pipe"] and data.raw["storage-tank"][old.name .. "-pipe"].fluid_box.volume - 100 or nil,
      recipe = {},
      unlubricated_recipe = {}
    }.loader.name
    data.raw.item[name] = nil
    data.raw.recipe[name] = nil
    new.name = name
  end
  new.localised_name = old.localised_name or { "entity-name." .. old.name }
  new.localised_description = old.localised_description or { "entity-description." .. old.name }
  new.hidden_in_factoriopedia = true
  new.hidden = true
  data.raw[new.type][new.name] = new
  return new
end

local max_stack_size
if feature_flags.space_travel then
  -- update util constant for max stack size
  max_stack_size = data.raw["utility-constants"]["default"].max_belt_stack_size or 0
  max_stack_size = max_stack_size > 1 and max_stack_size or 4
  data.raw["utility-constants"]["default"].max_belt_stack_size = max_stack_size

  if not data.raw.technology["transport-belt-capacity-1"] then
    error("Technology transport-belt-capacity-1 not found! Please install a mod that adds this technology, such as:\n\nhttps://mods.factorio.com/mod/stack-inserters\n")
  end
end

-- mark existing loaders as base loaders
for _, prototypes in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for _, loader in pairs(prototypes) do
  if not blacklist[loader.name] and not loader.ignore_by_loader_utils then
    base_loaders[loader.name] = loader.name
    modded_loaders[loader.name] = {[0] = loader.name}
    loader_ids[loader.name] = 0
    loader.per_lane_filters = false
    loader.wait_for_full_stack = false
    loader.respect_insert_limits = false
    loader.placeable_by = loader.placeable_by or data.raw.item[loader.name] and {item = loader.name, count = 1} or nil
    if max_stack_size then
      loader.max_belt_stack_size = (loader.max_belt_stack_size or 0) > 1 and loader.max_belt_stack_size or max_stack_size
      loader.adjustable_belt_stack_size = true
    end
  elseif loader.ignore_by_loader_utils then
    blacklist[loader.name] = true
  end
end end

-- find a way to avoid the race condition
for _, prototypes in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for bit, id in pairs {
  [0] = "lf",
  "rl",
  "fs"
} do for _, old in pairs(table.deepcopy(prototypes)) do
  if not blacklist[old.name] then
    local new = make_copy(old, id)

    if id == "lf" then
      new.filter_count = 2
      new.per_lane_filters = true
    elseif id == "rl" then
      new.respect_insert_limits = true
    elseif id == "fs" then
      new.wait_for_full_stack = true
    end

    -- save the ID and lookup
    loader_ids[new.name] = loader_ids[old.name] + 2^bit
    base_loaders[new.name] = base_loaders[old.name]
    modded_loaders[base_loaders[new.name]][loader_ids[new.name]] = new.name
    modded_loaders[base_loaders[new.name]][loader_ids[new.name]] = new.name
  end
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