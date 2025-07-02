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
    dir = vim.fn.stdpath("config"), -- Use local config as plugin directory
    config = function()
      -- Function to get visual selection or entire buffer
      local function get_diagram_content()
        local mode = vim.fn.mode()
        
        if mode == "v" or mode == "V" or mode == "\22" then
          -- Visual mode - get selection
          local start_pos = vim.fn.getpos("'<")
          local end_pos = vim.fn.getpos("'>")
          
          local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
          
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
          
          return table.concat(lines, "\n")
        else
          -- Normal mode - get entire buffer
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          return table.concat(lines, "\n")
        end
      end

      -- Function to generate diagram with specified format
      local function generate_diagram(content, use_boxart)
        local cmd = use_boxart and "graph-easy --as=boxart" or "graph-easy"
        local output = vim.fn.system(cmd, content)
        local exit_code = vim.v.shell_error
        
        if exit_code ~= 0 then
          return false, "graph-easy error (exit code " .. exit_code .. "):\n" .. output
        elseif output == "" then
          return false, "graph-easy produced no output"
        else
          return true, output
        end
      end

      -- Function to create and show popup with ASCII diagram
      local function show_ascii_popup(ascii_content, original_content, initial_boxart_state)
        -- Split content into lines
        local lines = vim.split(ascii_content, "\n")
        
        -- Calculate popup dimensions
        local width = 0
        for _, line in ipairs(lines) do
          width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        
        local height = #lines
        local max_width = math.floor(vim.o.columns * 0.8)
        local max_height = math.floor(vim.o.lines * 0.8)
        local min_width = 40
        local min_height = 15

        width = math.max(math.min(width + 4, max_width), min_width)
        height = math.max(math.min(height + 2, max_height), min_height)
        
        -- State variables
        local is_boxart = initial_boxart_state
        local stored_content = original_content
        
        -- Create popup buffer
        local buf = vim.api.nvim_create_buf(false, true)
        local win_opts = {
          relative = "editor",
          width = width,
          height = height,
          col = math.floor((vim.o.columns - width) / 2),
          row = math.floor((vim.o.lines - height) / 2),
          style = "minimal",
          border = "rounded",
          title = " Graph-Easy " .. (is_boxart and "boxart" or "plain") .. " ( ? for help ) ",
          title_pos = "center",
        }
        
        local win = vim.api.nvim_open_win(buf, true, win_opts)
        
        -- Function to update buffer content and title
        local function update_display()
          local success, result = generate_diagram(stored_content, is_boxart)
          
          if success then
            local new_lines = vim.split(result, "\n")
            vim.bo[buf].modifiable = true
            vim.bo[buf].readonly = false
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
            vim.bo[buf].readonly = true
            vim.bo[buf].modifiable = false
            
            -- Recalculate dimensions if needed
            local new_width = 0
            for _, line in ipairs(new_lines) do
              new_width = math.max(new_width, vim.fn.strdisplaywidth(line))
            end
            local new_height = #new_lines
            
            new_width = math.max(math.min(new_width + 4, max_width), min_width)
            new_height = math.max(math.min(new_height + 2, max_height), min_height)
            
            -- Update window with complete config
            local new_title = " Graph-Easy " .. (is_boxart and "boxart" or "plain") .. " ? for help "
            vim.api.nvim_win_set_config(win, {
              relative = "editor",
              width = new_width,
              height = new_height,
              col = math.floor((vim.o.columns - new_width) / 2),
              row = math.floor((vim.o.lines - new_height) / 2),
              style = "minimal",
              border = "rounded",
              title = new_title,
              title_pos = "center",
            })
          else
            -- Show error
            local error_lines = vim.split(result, "\n")
            vim.bo[buf].modifiable = true
            vim.bo[buf].readonly = false
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, error_lines)
            vim.bo[buf].readonly = true
            vim.bo[buf].modifiable = false
          end
        end
        
        -- Initial setup
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
        vim.bo[buf].readonly = true
        vim.bo[buf].filetype = "text"
        
        -- Function definitions
        local function close_popup()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
        
        local function yank_content()
          local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local content = table.concat(current_lines, "\n")
          vim.fn.setreg('"', content)
          vim.fn.setreg('+', content)
          print("ASCII diagram yanked to clipboard")
          close_popup()
        end
        
        local function toggle_boxart()
          is_boxart = not is_boxart
          print("Switching to " .. (is_boxart and "boxart" or "plain") .. " mode...")
          update_display()
        end
        
        -- Buffer-local keymaps
        local opts = { buffer = buf, noremap = true, silent = true, nowait = true }
        vim.keymap.set("n", "<Esc>", close_popup, opts)
        vim.keymap.set("n", "q", close_popup, opts)
        vim.keymap.set("n", "y", yank_content, opts)
        vim.keymap.set("n", "b", toggle_boxart, opts)
        vim.keymap.set("n", "?", function()
          print("Keybindings: <Esc>/q = close, b = toggle boxart, y = copy to clipboard, ? = help")
        end, opts)

        -- Auto-close on focus lost
        vim.api.nvim_create_autocmd("WinLeave", {
          buffer = buf,
          once = true,
          callback = close_popup,
        })
      end

      -- Function to generate ASCII diagram
      local function generate_ascii_diagram()
        local content = get_diagram_content()
        
        if content == "" then
          print("No content to generate diagram from")
          return
        end
        
        -- Generate initial diagram with boxart (default)
        local success, result = generate_diagram(content, true)
        
        if success then
          show_ascii_popup(result, content, true) -- Pass original content and initial state
        else
          show_ascii_popup(result, content, true) -- Show error but still store content
        end
      end

      -- Create user command
      vim.api.nvim_create_user_command("GraphEasy", function(opts)
        if opts.range == 2 then
          -- Visual mode - temporarily enter visual mode to capture selection
          vim.cmd("normal! gv")
          vim.defer_fn(generate_ascii_diagram, 10)
        else
          -- Normal mode
          generate_ascii_diagram()
        end
      end, {
        range = true,
        desc = "Generate ASCII diagram using graph-easy CLI",
      })

      -- Optional: Add keymap
      vim.keymap.set("n", "<leader>ad", ":GraphEasy<CR>", { desc = "Generate ASCII diagram (buffer)" })
      vim.keymap.set("v", "<leader>ad", ":GraphEasy<CR>", { desc = "Generate ASCII diagram (selection)" })
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
