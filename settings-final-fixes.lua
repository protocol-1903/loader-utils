-- disable snapping

if mods["aai-loaders"] then
  data.raw["string-setting"]["aai-loaders-belt-stacking-mode"].hidden = true
  data.raw["string-setting"]["aai-loaders-belt-stacking-mode"].forced_value = "off"
  data.raw["string-setting"]["aai-loaders-belt-stacking-mode"].allowed_values = {"off"}
  -- data.raw["bool-setting"]["aai-loaders-enable-snapping"].hidden = true
  -- data.raw["bool-setting"]["aai-loaders-enable-snapping"].forced_value = false
end

if mods["deadlock-beltboxes-loaders"] then
  data.raw["bool-setting"]["deadlock-loaders-snap-to-belts"].hidden = true
  data.raw["bool-setting"]["deadlock-loaders-snap-to-belts"].forced_value = false
  data.raw["bool-setting"]["deadlock-loaders-snap-to-inventories"].hidden = true
  data.raw["bool-setting"]["deadlock-loaders-snap-to-inventories"].forced_value = false
end

if mods["comfortable-loader"] then
  data.raw["bool-setting"]["comfortable-loader-snap-to-belts"].hidden = true
  data.raw["bool-setting"]["comfortable-loader-snap-to-belts"].forced_value = false
  data.raw["bool-setting"]["comfortable-loader-snap-to-inventories"].hidden = true
  data.raw["bool-setting"]["comfortable-loader-snap-to-inventories"].forced_value = false
end

if mods["vanilla-loaders-hd"] then
  data.raw["bool-setting"]["vanillaLoaders-do-loader-snapping"].hidden = true
  data.raw["bool-setting"]["vanillaLoaders-do-loader-snapping"].forced_value = false
end