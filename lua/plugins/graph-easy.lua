--[[
===============================================
Graph-Easy Neovim Plugin Prerequisites
===============================================

This plugin requires the Graph::Easy Perl module to generate ASCII diagrams.

INSTALLATION STEPS (macOS):

1. Install cpanminus (Perl package manager):
   $ brew install cpanminus

2. Install Graph::Easy module:
   $ cpanm Graph::Easy

3. Add Perl paths to your shell configuration (~/.bashrc, ~/.zshrc, etc.):
   export PATH="$HOME/perl5/bin:$PATH"
   export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"

4. Reload your shell or source the config:
   $ source ~/.bashrc  # or ~/.zshrc

5. Verify installation:
   $ graph-easy --version
   $ echo "[A] -> [B]" | graph-easy --as=boxart

ALTERNATIVE INSTALLATION METHODS:

Linux (Ubuntu/Debian):
   $ sudo apt-get install libgraph-easy-perl

Linux (RHEL/CentOS/Fedora):
   $ sudo yum install perl-Graph-Easy
   # or
   $ sudo dnf install perl-Graph-Easy

Windows:
   1. Install Strawberry Perl or ActivePerl
   2. cpanm Graph::Easy
   3. Add perl/bin to your PATH

TROUBLESHOOTING:

- If 'graph-easy' command not found: Check PATH includes $HOME/perl5/bin
- If module errors: Ensure PERL5LIB includes $HOME/perl5/lib/perl5
- On some systems, you may need: cpanm --local-lib=~/perl5 Graph::Easy

TESTING THE INSTALLATION:

Run this test command to verify everything works:
   echo "[ Start ] -> [ Process ] -> [ End ]" | graph-easy --as=boxart

Expected output should show connected boxes with ASCII art.
]]

return {
  {
    name = "easygraph-integration",
    dir = vim.fn.stdpath("config"),
    config = function()
      -- Configuration
      local config = {
        outputs = { "boxart", "ascii", "svg", "html", "dot" },
        default_output = "boxart",
        popup = {
          min_width = 60,
          min_height = 15,
          max_width_ratio = 0.9,
          max_height_ratio = 0.9,
          border = "rounded"
        },
        keymaps = {
          close = { "<Esc>", "q" },
          yank = "y",
          next_format = "<Tab>",
          prev_format = "<S-Tab>",
          help = "?",
          open_browser = "o",
          -- Direct format selection
          formats = {
            b = "boxart",
            a = "ascii", 
            s = "svg",
            h = "html",
            d = "dot"
          }
        }
      }

      -- Track temp files for cleanup
      local temp_files = {}

      -- State management
      local state = {
        current_output = config.default_output
      }

      -- Utility functions
      local function find_output_index(output_name)
        for i, name in ipairs(config.outputs) do
          if name == output_name then
            return i
          end
        end
        return 1
      end

      local function cycle_output(direction)
        local current_index = find_output_index(state.current_output)
        local new_index = ((current_index + direction - 1) % #config.outputs) + 1
        state.current_output = config.outputs[new_index]
        return state.current_output
      end

      local function get_title(output_format)
        return string.format(" Graph-Easy - %s ( ? for help ) ", output_format)
      end

      -- Content extraction
      local function get_visual_selection()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local mode = vim.fn.visualmode()
        
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
        
        if #lines == 0 then
          return ""
        end
        
        if mode == "v" then
          -- Character-wise selection
          if #lines == 1 then
            lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
          else
            lines[1] = string.sub(lines[1], start_pos[3])
            lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
          end
        elseif mode == "\22" then
          -- Block selection
          for i = 1, #lines do
            lines[i] = string.sub(lines[i], start_pos[3], end_pos[3])
          end
        end
        -- Visual line mode uses full lines as-is
        
        return table.concat(lines, "\n")
      end

      local function get_diagram_content(use_selection)
        if use_selection then
          return get_visual_selection()
        else
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          return table.concat(lines, "\n")
        end
      end

      -- Browser integration
      local function open_in_browser(content, format)
        local temp_dir = vim.fn.tempname()
        vim.fn.mkdir(temp_dir, "p")
        
        -- Use timestamp and random number for unique filename
        local timestamp = os.time()
        local random = math.random(1000, 9999)
        local filename = string.format("%s/graph_easy_%s_%d_%d.html", temp_dir, format, timestamp, random)
        
        -- Wrap all content in HTML structure
        local html_content
        if format == "html" and (content:match("<!DOCTYPE") or content:match("<html")) then
          -- Already proper HTML
          html_content = content
        else
          -- Wrap in HTML with appropriate styling
          local body_content = content
          local style = ""
          
          if format == "svg" then
            style = [[
        body { margin: 20px; text-align: center; }
        svg { max-width: 100%; height: auto; border: 1px solid #ccc; }
]]
          else
            -- ASCII, boxart, dot, or other text formats
            style = [[
        body { 
          font-family: 'Monaco', 'Consolas', 'Courier New', monospace; 
          white-space: pre; 
          margin: 20px; 
          line-height: 1.2;
          font-size: 12px;
        }
]]
          end
          
          html_content = string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Graph-Easy Output (%s)</title>
    <style>%s    </style>
</head>
<body>%s</body>
</html>]], format, style, body_content)
        end
        
        -- Write content to file
        local file = io.open(filename, "w")
        if not file then
          print("Error: Could not create temporary file")
          return false
        end
        
        file:write(html_content)
        file:close()
        
        -- Track temp file for cleanup
        table.insert(temp_files, temp_dir)
        
        -- Force open in browser using -a flag with a browser app
        local browsers = {
          "Google Chrome",
          "Safari", 
          "Firefox",
          "Microsoft Edge"
        }
        
        local cmd = nil
        for _, browser in ipairs(browsers) do
          if vim.fn.system(string.format("mdfind 'kMDItemDisplayName == \"%s\"'", browser)):match("%S") then
            cmd = string.format("open -a '%s' '%s'", browser, filename)
            break
          end
        end
        
        -- Fallback: force any browser
        if not cmd then
          cmd = string.format("open -a Safari '%s'", filename)
        end
        
        vim.fn.system(cmd)
        
        -- Clean up after delay
        vim.defer_fn(function()
          vim.fn.delete(temp_dir, "rf")
        end, 5000)
        
        return true
      end

      -- Setup cleanup on exit
      local function cleanup_temp_files()
        for _, temp_dir in ipairs(temp_files) do
          if vim.fn.isdirectory(temp_dir) == 1 then
            vim.fn.delete(temp_dir, "rf")
          end
        end
        temp_files = {}
      end

      -- Register cleanup handlers
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("GraphEasyCleanup", { clear = true }),
        callback = cleanup_temp_files,
      })
      local function validate_graph_easy()
        local handle = io.popen("command -v graph-easy 2>/dev/null")
        if not handle then
          return false, "Could not check for graph-easy command"
        end
        
        local result = handle:read("*a")
        handle:close()
        
        if result == "" then
          return false, "graph-easy command not found. Please install Graph::Easy Perl module."
        end
        
        return true, nil
      end

      local function generate_diagram(content, output_format)
        if content:match("^%s*$") then
          return false, "No content provided"
        end

        local cmd = string.format("graph-easy --as=%s", output_format)
        local output = vim.fn.system(cmd, content)
        local exit_code = vim.v.shell_error
        
        if exit_code ~= 0 then
          return false, string.format("graph-easy error (exit code %d):\n%s", exit_code, output)
        elseif output == "" then
          return false, "graph-easy produced no output"
        else
          return true, output
        end
      end

      -- UI Management
      local function calculate_popup_size(content_lines)
        local width = 0
        for _, line in ipairs(content_lines) do
          width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        
        local height = #content_lines
        local max_width = math.floor(vim.o.columns * config.popup.max_width_ratio)
        local max_height = math.floor(vim.o.lines * config.popup.max_height_ratio)

        width = math.max(math.min(width + 4, max_width), config.popup.min_width)
        height = math.max(math.min(height + 2, max_height), config.popup.min_height)
        
        return width, height
      end

      local function update_popup_content(buf, win, original_content)
        local success, result = generate_diagram(original_content, state.current_output)
        
        if not success then
          -- Show error in buffer
          local error_lines = vim.split("Error: " .. result, "\n")
          vim.bo[buf].modifiable = true
          vim.bo[buf].readonly = false
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, error_lines)
          vim.bo[buf].readonly = true
          vim.bo[buf].modifiable = false
          return
        end

        local new_lines = vim.split(result, "\n")
        local new_width, new_height = calculate_popup_size(new_lines)
        
        -- Update buffer content
        vim.bo[buf].modifiable = true
        vim.bo[buf].readonly = false
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
        vim.bo[buf].readonly = true
        vim.bo[buf].modifiable = false
        
        -- Update window size and title
        vim.api.nvim_win_set_config(win, {
          relative = "editor",
          width = new_width,
          height = new_height,
          col = math.floor((vim.o.columns - new_width) / 2),
          row = math.floor((vim.o.lines - new_height) / 2),
          style = "minimal",
          border = config.popup.border,
          title = get_title(state.current_output),
          title_pos = "center",
        })
      end

      local function setup_popup_keymaps(buf, win, original_content, close_fn)
        local opts = { buffer = buf, noremap = true, silent = true, nowait = true }
        
        -- Close keymaps
        for _, key in ipairs(config.keymaps.close) do
          vim.keymap.set("n", key, close_fn, opts)
        end
        
        -- Yank content
        vim.keymap.set("n", config.keymaps.yank, function()
          local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local content = table.concat(current_lines, "\n")
          vim.fn.setreg('"', content)
          vim.fn.setreg('+', content)
          print(string.format("Diagram (%s) yanked to clipboard", state.current_output))
          close_fn()
        end, opts)
        
        -- Open in browser
        vim.keymap.set("n", config.keymaps.open_browser, function()
          local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local content = table.concat(current_lines, "\n")
          
          if open_in_browser(content, state.current_output) then
            print(string.format("Opened %s diagram in browser", state.current_output))
            -- Don't close popup - user can continue working
          end
        end, opts)
        vim.keymap.set("n", config.keymaps.next_format, function()
          cycle_output(1)
          update_popup_content(buf, win, original_content)
        end, opts)
        
        vim.keymap.set("n", config.keymaps.prev_format, function()
          cycle_output(-1)
          update_popup_content(buf, win, original_content)
        end, opts)
        
        -- Direct format selection
        for key, format in pairs(config.keymaps.formats) do
          vim.keymap.set("n", key, function()
            if vim.tbl_contains(config.outputs, format) then
              state.current_output = format
              update_popup_content(buf, win, original_content)
            end
          end, opts)
        end
        
        -- Help
        vim.keymap.set("n", config.keymaps.help, function()
          local help_lines = {
            "Graph-Easy Keybindings:",
            "",
            string.format("%s - Close popup", table.concat(config.keymaps.close, "/")),
            string.format("%s - Copy to clipboard", config.keymaps.yank),
            string.format("%s - Open in browser", config.keymaps.open_browser),
            string.format("%s - Next format", config.keymaps.next_format),
            string.format("%s - Previous format", config.keymaps.prev_format),
            "",
            "Direct format selection:"
          }
          
          for key, format in pairs(config.keymaps.formats) do
            table.insert(help_lines, string.format("  %s - %s", key, format))
          end
          
          print(table.concat(help_lines, "\n"))
        end, opts)
      end

      local function show_diagram_popup(content, use_selection)
        local original_content = get_diagram_content(use_selection)
        
        if original_content:match("^%s*$") then
          print("No content to generate diagram from")
          return
        end
        
        -- Validate graph-easy availability
        local valid, error_msg = validate_graph_easy()
        if not valid then
          print("Error: " .. error_msg)
          return
        end
        
        -- Generate initial content
        local success, result = generate_diagram(original_content, state.current_output)
        if not success then
          print("Failed to generate diagram: " .. result)
          return
        end
        
        local lines = vim.split(result, "\n")
        local width, height = calculate_popup_size(lines)
        
        -- Create popup
        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          col = math.floor((vim.o.columns - width) / 2),
          row = math.floor((vim.o.lines - height) / 2),
          style = "minimal",
          border = config.popup.border,
          title = get_title(state.current_output),
          title_pos = "center",
        })
        
        -- Setup buffer
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].readonly = true
        vim.bo[buf].modifiable = false
        vim.bo[buf].filetype = "text"
        
        -- Cleanup function
        local function close_popup()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
        
        -- Setup keymaps
        setup_popup_keymaps(buf, win, original_content, close_popup)
        
        -- Auto-close on focus lost
        vim.api.nvim_create_autocmd("WinLeave", {
          buffer = buf,
          once = true,
          callback = close_popup,
        })
      end

      -- Public interface
      local function generate_ascii_diagram(use_selection)
        show_diagram_popup(nil, use_selection)
      end

      -- Commands and keymaps
      vim.api.nvim_create_user_command("GraphEasy", function(opts)
        if opts.range == 2 then
          -- Visual mode - temporarily enter visual mode to capture selection
          vim.cmd("normal! gv")
          vim.defer_fn(function() 
            generate_ascii_diagram(true)
          end, 10)
        else
          -- Normal mode
          generate_ascii_diagram(false)
        end
      end, {
        range = true,
        desc = "Generate diagram using graph-easy CLI",
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>ad", ":GraphEasy<CR>", { desc = "Generate diagram (buffer)" })
      vim.keymap.set("v", "<leader>ad", ":GraphEasy<CR>", { desc = "Generate diagram (selection)" })
    end,
  },
}
--[[
===============================================
Graph-Easy ASCII Output - Shapes That Matter
===============================================

http://bloodgate.com/perl/graph/manual/syntax.html

SHAPES THAT WORK IN ASCII/BOXART:

1. Regular nodes (default rectangular boxes):
[ Normal node ]
[ Bold border node ] { border: bold; }
[ Broad border node ] { border: broad; }
[ Wide border node ] { border: wide; }
[ Wide-dash border node ] { border: bold-dash; }
[ Double border node ] { border: double; }
[ Dotted border node ] { border: dotted; }
[ Dashed border node ] { border: dashed; }
[ Dot-dashed border node ] { border: dot-dash; }
[ Dot-dot-dashed border node ] { border: dot-dot-dash; }

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃      Bold border node      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
▛▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▜
▌     Broad border node      ▐
▙▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▟
┌−−−−−−−−−−−−−−−−−−−−−−−−−−−−┐
╎     Dashed border node     ╎
└−−−−−−−−−−−−−−−−−−−−−−−−−−−−┘
┌-·-·-·-·-·-·-·-·-·-·-·-·-·-·┐
!   Dot-dashed border node   !
└-·-·-·-·-·-·-·-·-·-·-·-·-·-·┘
┌·-··-··-··-··-··-··-··-··-··┐
│ Dot-dot-dashed border node │
└·-··-··-··-··-··-··-··-··-··┘
┌⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯┐
⋮     Dotted border node     ⋮
└⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯┘
╔════════════════════════════╗
║     Double border node     ║
╚════════════════════════════╝
┌────────────────────────────┐
│        Normal node         │
└────────────────────────────┘
██████████████████████████████
█      Wide border node      █
██████████████████████████████
┏ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━┓
╻   Wide-dash border node    ╻
┗ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━┛

2. Invisible nodes (take up no space):
[ Start ] -> [ ] -> [ End ]

┌───────┐             ┌─────┐
│ Start │ ──>     ──> │ End │
└───────┘             └─────┘

3. Point nodes (very small, no text):
[A] -> [B] { shape: point; }

┌───┐
│ A │ ──>   ★
└───┘

4. Edge-shaped nodes (appear inline with edges):
[A] -> [ connector ] { shape: edge; } -> [B]

┌───┐      connector        ┌───┐
│ A │ ──> -------------───> │ B │
└───┘                       └───┘

5. Different edge styles:
I. Solid line:
[A] - solid -> [B]
[A] -- [B]
[A] <-> [B]

  ┌──────────────┐
  │              │
┌───┐  solid   ┌───┐
│ A │ ───────> │ B │
└───┘          └───┘
  ∧              ∧
  └──────────────┘

II. Dashed line:
[A] -  dashed - > [B]
[A] - - [B]
[A] <- - > [B]

  ┌╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┐
  ╵               ╵
┌───┐  dashed   ┌───┐
│ A │ ╴╴╴╴╴╴╴╴> │ B │
└───┘           └───┘
  ∧               ∧
  ╵╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴┘

III. Dotted line:
[A] . dotted .> [B]
[A] .. [ B]
[A] <.> [B]

  ┌···············┐
  :               :
┌───┐  dotted   ┌───┐
│ A │ ········> │ B │
└───┘           └───┘
  ∧               ∧
  └···············┘

IV. Double line:
[A] = double => [B] 
[A] <=> [B] 

  ╔═══════════════╗
  ∨               ∨
┌───┐  double   ┌───┐
│ A │ ════════> │ B │
└───┘           └───┘

V. Dot-dashed line:
[A] .- dot-dashed .-> [B]
[A] .- [B]
[A] <.-> [B]

  ┌-·-·-·-·-·-·-·-·-·-┐
  !                   !
┌───┐  dot-dashed   ┌───┐
│ A │ ·-·-·-·-·-·-> │ B │
└───┘               └───┘
  ∧                   ∧
  └-·-·-·-·-·-·-·-·-·-┘

VI. Dot-dot-dashed line:
[A] ..- dot-dot-dashed ..-> [B]
[A] ..- [B]
[A] <..-> [B]

  ┌··-··-··-··-··-··-··-··-·┐
  !                         !
┌────┐  dot-dot-dashed    ┌────┐
│ A  │ ··-··-··-··-··-··> │ B  │
└────┘                    └────┘
  ∧                         ∧
  └··-··-··-··-··-··-··-··-·┘

VII. Double-dashed line:
[A] =  double-dashed = > [B]
[A] = = [B]
[A] <= > [B]

  ╔ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═╗
  ∥                      ∥
┌───┐  double-dashed   ┌───┐
│ A │ ═ ═ ═ ═ ═ ═ ═ ═> │ B │
└───┘                  └───┘
  ∧                      ∧
  ╚ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═╝

VIII. Wave line:
[A] ~ wave ~> [B]
[A] ~~ [B]
[A] <~> [B]

  ┌∼∼∼∼∼∼∼∼∼∼∼∼∼┐
  ≀             ≀
┌───┐  wave   ┌───┐
│ A │ ∼∼∼∼∼∼> │ B │
└───┘         └───┘
  ∧             ∧
  └∼∼∼∼∼∼∼∼∼∼∼∼∼┘


SHAPES THAT DON'T MATTER IN ASCII:
- diamond (renders as regular box)
- circle (renders as regular box)  
- ellipse (renders as regular box)
- triangle (renders as regular box)

USEFUL ASCII EXAMPLES:

Simple flow with decision:
[ Input ] -> [ Valid? ] - Yes -> [ Process ]
[ Valid? ] - No -> [ Error ] --> [ Input ]

  ┌───────────────────────────────┐
  ∨                               │
┌───────┐     ┌─────────┐  No   ┌───────┐
│ Input │ ──> │ Valid?  │ ────> │ Error │
└───────┘     └─────────┘       └───────┘
                │
                │ Yes
                ∨
              ┌─────────┐
              │ Process │
              └─────────┘

Using invisible nodes for routing:
[A] -> [ ] { shape: invisible; } -> [C]
[B] -> [ ] { shape: invisible; }

┌───┐             ┌───┐
│ A │ ──>     ──> │ C │
└───┘             └───┘
┌───┐
│ B │ ──>
└───┘

Using point nodes as connectors:
[ Source ] -> [ ] { shape: point; } -> [ Target A ]
[ ] { shape: point; } -> [ Target B ]

               ┌──────────┐
  ★        ──> │ Target B │
               └──────────┘
┌────────┐                      ┌──────────┐
│ Source │ ──>   ★          ──> │ Target A │
└────────┘                      └──────────┘

Using edge nodes for inline labels:
[ Start ] -> [ step 1 ] { shape: edge; } -> [ Middle ] -> [ step 2 ] { shape: edge; } -> [ End ]

┌───────┐      step 1        ┌────────┐      step 2        ┌─────┐
│ Start │ ──> ----------───> │ Middle │ ──> ----------───> │ End │
└───────┘                    └────────┘                    └─────┘

Complex routing with invisible nodes:
[ Frontend ] -> [ ] { shape: invisible; } -> [ Database ]
[ ] { shape: invisible; } -> [ Cache ]
[ ] { shape: invisible; } -> [ Logger ]

                 ┌────────┐
             ──> │ Cache  │
                 └────────┘
┌──────────┐                    ┌──────────┐
│ Frontend │ ──>            ──> │ Database │
└──────────┘                    └──────────┘
                 ┌────────┐
             ──> │ Logger │
                 └────────┘

Real-world process:
[ Request ] -> [ Valid? ] - Yes -> [ Process ] -> [ Response ]
[ Valid? ] - No -> [ Error Log ] { shape: edge; } -> [ ] { shape: invisible; }

┌─────────┐     ┌─────────┐  No    Error Log
│ Request │ ──> │ Valid?  │ ────> -------------───>
└─────────┘     └─────────┘
                  │
                  │ Yes
                  ∨
                ┌─────────┐       ┌───────────┐
                │ Process │ ────> │ Response  │
                └─────────┘       └───────────┘
]]
