local base_loaders, loader_ids, modded_loaders = {}, {}, {}

local blacklist = {
  ["ee-infinity-loader"] = true
}

---@param old_prototype data.LoaderPrototype
---@param id uint8
---@return data.LoaderPrototype
local function make_copy(old_prototype, id)
  local new_prototype = table.deepcopy(old_prototype)
  new_prototype.name = id .. "-" .. old_prototype.name
  if mods["aai-loaders"] and old_prototype.name:find("aai%-") then
    local name = AAILoaders.make_tier {
      name = id .. (old_prototype.name == "aai-loader" and "" or "-" .. old_prototype.name:sub(5, -8)),
      transport_belt = "transport-belt",
      fluid = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old_prototype.name .. "-pipe"] and data.raw["storage-tank"][old_prototype.name .. "-pipe"].fluid_box.filter or nil,
      fluid_per_minute = settings.startup["aai-loaders-mode"].value == "lubricated" and data.raw["storage-tank"][old_prototype.name .. "-pipe"] and data.raw["storage-tank"][old_prototype.name .. "-pipe"].fluid_box.volume - 100 or nil,
      recipe = {},
      unlubricated_recipe = {}
    }.loader.name
    data.raw.item[name] = nil
    data.raw.recipe[name] = nil
    new_prototype.name = name
  end
  new_prototype.localised_name = old_prototype.localised_name or { "entity-name." .. old_prototype.name }
  new_prototype.localised_description = old_prototype.localised_description or { "entity-description." .. old_prototype.name }
  new_prototype.hidden = not settings.startup["lu-show-all-loaders"].value
  new_prototype.factoriopedia_alternative = old_prototype.factoriopedia_alternative or old_prototype.name
  new_prototype.hidden_in_factoriopedia = true
  data.raw[new_prototype.type][new_prototype.name] = new_prototype
  return new_prototype
end

local max_stack_size
if feature_flags.space_travel then
  -- update util constant for max stack size
  max_stack_size = data.raw["utility-constants"]["default"].max_belt_stack_size or 0
  max_stack_size = max_stack_size > 1 and max_stack_size or 4
  data.raw["utility-constants"]["default"].max_belt_stack_size = max_stack_size

  if not data.raw.technology["transport-belt-capacity-1"] and not data.raw.technology["py-transport-belt-capacity-1"] then
    error("Technology transport-belt-capacity-1 not found! Please install a mod that adds this technology, such as:\n\nhttps://mods.factorio.com/mod/stack-inserters\n")
  end
end

-- mark existing loaders as base loaders
for _, prototypes in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for _, prototype in pairs(prototypes) do
  if not blacklist[prototype.name] and not prototype.ignore_by_loader_utils then
    base_loaders[prototype.name] = prototype.name
    modded_loaders[prototype.name] = {[0] = prototype.name}
    loader_ids[prototype.name] = 0
    prototype.per_lane_filters = false
    prototype.wait_for_full_stack = false
    prototype.respect_insert_limits = false
    prototype.placeable_by = prototype.placeable_by or data.raw.item[prototype.name] and {item = prototype.name, count = 1} or nil
    prototype.filter_count = prototype.filter_count >= 2 and prototype.filter_count or 2 -- ensure at least 2 filters for the base loader
    prototype.order = prototype.order or "loader-[" .. prototype.name .. "]" -- default order parameter
    if max_stack_size then
      prototype.max_belt_stack_size = (prototype.max_belt_stack_size or 0) > 1 and prototype.max_belt_stack_size or max_stack_size
      prototype.adjustable_belt_stack_size = true
    end
  elseif prototype.ignore_by_loader_utils then
    blacklist[prototype.name] = true
    prototype.ignore_by_loader_utils = nil
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
} do for _, old_prototype in pairs(table.deepcopy(prototypes)) do
  if not blacklist[old_prototype.name] then
    local new_prototype = make_copy(old_prototype, id)
    new_prototype.order = prototypes[base_loaders[old_prototype.name]].order .. "[" .. (loader_ids[old_prototype.name] + 2^bit) .. "]"

    if id == "lf" then
      new_prototype.filter_count = 2
      new_prototype.per_lane_filters = true
    elseif id == "rl" then
      new_prototype.respect_insert_limits = true
    elseif id == "fs" then
      new_prototype.wait_for_full_stack = true
    end

    -- save the ID and lookup
    loader_ids[new_prototype.name] = loader_ids[old_prototype.name] + 2^bit
    base_loaders[new_prototype.name] = base_loaders[old_prototype.name]
    modded_loaders[base_loaders[new_prototype.name]][loader_ids[new_prototype.name]] = new_prototype.name
    modded_loaders[base_loaders[new_prototype.name]][loader_ids[new_prototype.name]] = new_prototype.name
  end
end end end

for _, prototypes in pairs {
  data.raw.loader,
  data.raw["loader-1x1"]
} do for _, prototype in pairs(prototypes) do
  -- set next_upgrade properly
  if not blacklist[prototype.name] then
    if prototype.next_upgrade then
      prototype.next_upgrade = modded_loaders[prototypes[base_loaders[prototype.name]].next_upgrade][loader_ids[prototype.name]]
    end

    -- update icons
    prototype.icons = prototype.icons or {{
      icon = prototype.icon,
      icon_size = prototype.icon_size
    }}
    prototype.icon = nil
    prototype.icon_size = nil
    for i = 1, 3 do
      prototype.icons[#prototype.icons+1] = {
        icon = ("__loader-utils__/graphics/pips/pip-%s.png"):format(bit32.band(2^(i-1), loader_ids[prototype.name]) ~= 0 and "green" or "red"),
        icon_size = 32,
        scale = 0.3,
        shift = {-14, i * 6}
      }
    end
  end
end end

data:extend{{
  type = "mod-data",
  name = "loader-utils",
  data = {
    base_loaders = base_loaders,
    loader_ids = loader_ids,
    modded_loaders = modded_loaders
  }
}}