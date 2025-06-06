-- Load all configuration modules in the correct order
require("config.options")
require("config.lazy")     -- This must come early as it sets up the plugin manager
require("config.keymaps")
require("config.autocmds")
require("config.project")
