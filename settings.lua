-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

data:extend{
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "lu-lf-default",
    default_value = true
  },
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "lu-rl-default",
    default_value = false
  },
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "lu-fs-default",
    default_value = false
  },
  {
    type = "bool-setting",
    setting_type = "startup",
    name = "lu-show-all-loaders",
    default_value = true
  },
  {
    type = "bool-setting",
    setting_type = "runtime-per-user",
    name = "lu-enable-snapping",
    default_value = true
  }
}