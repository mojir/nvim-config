-- Enhances <C-a>/<C-x> to work with booleans, dates, operators, and more beyond just numbers

return {
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "<C-a>",
        function()
          require("dial.map").manipulate("increment", "normal")
        end,
        mode = "n",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "normal")
        end,
        mode = "n",
      },
      {
        "<C-a>",
        function()
          require("dial.map").manipulate("increment", "visual")
        end,
        mode = "v",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "visual")
        end,
        mode = "v",
      },
      {
        "g<C-a>",
        function()
          require("dial.map").manipulate("increment", "gvisual")
        end,
        mode = "v",
      },
      {
        "g<C-x>",
        function()
          require("dial.map").manipulate("decrement", "gvisual")
        end,
        mode = "v",
      },
    },
    config = function()
      local augend = require("dial.augend")

      require("dial.config").augends:register_group({
        default = {
          -- Numbers
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.integer.alias.octal,
          augend.integer.alias.binary,

          -- Dates & Times
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%Y-%m-%d"], -- ISO date

          -- Booleans & Constants
          augend.constant.alias.bool, -- true/false

          -- Programming operators
          augend.constant.new({
            elements = { "&&", "||" },
            word = false,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "==", "!=" },
            word = false,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "===", "!==" },
            word = false,
            cyclic = true,
          }),

          -- HTTP methods
          augend.constant.new({
            elements = { "GET", "POST", "PUT", "DELETE", "PATCH" },
            word = true,
            cyclic = true,
          }),

          -- CSS units
          augend.constant.new({
            elements = { "px", "em", "rem", "%", "vh", "vw" },
            word = false,
            cyclic = true,
          }),

          -- Log levels
          augend.constant.new({
            elements = { "debug", "info", "warn", "error" },
            word = true,
            cyclic = true,
          }),

          -- Yes/No variations
          augend.constant.new({
            elements = { "yes", "no" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "on", "off" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "enable", "disable" },
            word = true,
            cyclic = true,
          }),

          -- Weekdays
          augend.constant.new({
            elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
            word = true,
            cyclic = true,
          }),

          -- Months
          augend.constant.new({
            elements = {
              "January",
              "February",
              "March",
              "April",
              "May",
              "June",
              "July",
              "August",
              "September",
              "October",
              "November",
              "December",
            },
            word = true,
            cyclic = true,
          }),
        },
      })
    end,
  },
}
