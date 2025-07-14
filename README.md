# Neovim Configuration

A modern, feature-rich Neovim configuration built with Lua, optimized for web development and general programming tasks with advanced custom systems.

## Features

- **Modern Plugin Management**: Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for fast and efficient plugin loading
- **LSP Integration**: Full Language Server Protocol support with auto-completion, diagnostics, and formatting
- **AI-Powered Development**: GitHub Copilot integration with chat interface
- **Advanced Git Integration**: GitSigns, Diffview, Neogit and comprehensive git workflows
- **Fuzzy Finding**: Telescope with live grep, file search, and project navigation
- **Testing Framework**: Neotest with Vitest integration for JavaScript/TypeScript projects
- **Advanced Session Management**: Custom session system with locking, history, and project switching
- **Custom Language Support**: Integrated Lits language environment with evaluation and file management
- **Debugging Support**: DAP (Debug Adapter Protocol) with breakpoint persistence
- **Terminal Integration**: Toggleterm with floating and split terminal options
- **Enhanced Editing**: Text objects, surround operations, undo tree, and smart text manipulation
- **ASCII Diagram Generation**: Graph-Easy integration for creating diagrams from text

## Directory Structure

```
├── init.lua                           # Entry point with session tracking
├── lua/
│   ├── config/                        # Core configuration
│   │   ├── init.lua                   # Configuration loader
│   │   ├── options.lua                # Vim options and settings
│   │   ├── keymaps.lua                # Global keybindings
│   │   ├── autocmds.lua               # Auto-commands
│   │   ├── lazy.lua                   # Plugin manager setup
│   │   ├── project.lua                # Project-specific config loader
│   │   └── ripgrep.lua                # Centralized ripgrep configuration
│   ├── plugins/                       # Plugin configurations
│   │   ├── editor/                    # Editor enhancement plugins
│   │   ├── lang/                      # Language-specific plugins
│   │   ├── copilot/                   # AI assistance plugins
│   │   └── ui/                        # UI and theme plugins
│   ├── utils/                         # Utility functions
│   │   └── diagnostic.lua             # Diagnostic utilities
│   ├── session/                       # Custom session management
│   │   ├── init.lua                   # Session system entry point
│   │   ├── core.lua                   # Core session logic
│   │   ├── config.lua                 # Session configuration
│   │   ├── data.lua                   # Session data persistence
│   │   ├── lock.lua                   # Session locking system
│   │   ├── picker.lua                 # Telescope session picker
│   │   └── tracking.lua               # Buffer access tracking
│   ├── lits/                         # Custom Lits language support
│   │   ├── init.lua                   # Lits system entry point
│   │   ├── config.lua                 # Lits configuration
│   │   ├── state.lua                  # State management
│   │   ├── utils.lua                  # Lits utilities
│   │   ├── ui.lua                     # UI management
│   │   ├── files.lua                  # File operations
│   │   ├── editor.lua                 # Lits editor
│   │   ├── result.lua                 # Result display
│   │   └── commands.lua               # Lits commands
│   └── my_snippets.lua                # Custom snippet system
├── data/
│   ├── my_snippets.json               # Custom snippet definitions
│   └── telescope-sources/             # Telescope symbol sources
│       ├── arrows.json
│       ├── currency.json
│       ├── fractions.json
│       └── indicators.json
├── session.bash                       # Bash session management script
├── generateDoc.bash                   # Documentation generation script
└── .gitignore                         # Git ignore file
```

## Key Plugins

### Core Development
- **nvim-lspconfig**: Language Server Protocol integration
- **nvim-cmp**: Auto-completion engine with LuaSnip integration
- **nvim-treesitter**: Syntax highlighting and text objects
- **telescope.nvim**: Fuzzy finder and picker with live grep args
- **gitsigns.nvim**: Git integration with sign column

### Custom Systems
- **Lits Integration**: Full language environment with editor, evaluation, and file management
- **Session Management**: Advanced session system with locking, project switching, and history
- **Graph-Easy**: ASCII diagram generation from text descriptions
- **Custom Snippets**: Snippet system with placeholder expansion for dates, files, and paths

### AI Assistance
- **copilot.vim**: GitHub Copilot code suggestions
- **CopilotChat.nvim**: AI-powered chat interface for code assistance

### Testing & Debugging
- **neotest-vitest**: Test runner integration for Vitest with smart configuration detection
- **nvim-dap**: Debug Adapter Protocol support with breakpoint persistence
- **nvim-dap-ui**: Debug interface

### Editor Enhancements
- **harpoon**: Quick file navigation and bookmarking (harpoon2 branch)
- **yanky.nvim**: Enhanced yank/paste with history
- **nvim-surround**: Surround text objects manipulation
- **undotree**: Visual undo history
- **which-key**: Keybinding discovery
- **nvim-various-textobjs**: Additional text objects
- **dial.nvim**: Enhanced increment/decrement for dates, booleans, and more
- **mini.bufremove**: Smart buffer deletion
- **nvim-spectre**: Search and replace across project
- **trouble.nvim**: Enhanced diagnostics display
- **nvim-bqf**: Better quickfix window
- **nvim-scrollbar**: Enhanced scrollbar with diagnostics and git signs

### Git Integration
- **neogit**: Full-featured Git interface
- **diffview.nvim**: Advanced diff and merge tool
- **gitsigns.nvim**: Git signs and hunk operations

### Language Support
- **typescript-tools.nvim**: Enhanced TypeScript/JavaScript support
- **none-ls.nvim**: ESLint integration with auto-fixing
- **venv-selector.nvim**: Python virtual environment management
- **emmet-vim**: HTML/CSS expansion
- **package-info.nvim**: NPM package version information
- **lazydev.nvim**: Enhanced Lua development for Neovim

### UI and Themes
- **catppuccin**: Modern colorscheme
- **lualine.nvim**: Statusline with selection statistics
- **mini.icons**: Icon provider
- **nvim-colorizer**: Color highlighting for CSS/web files
- **nvim-tree.lua**: File explorer with live grep integration

### Terminal Integration
- **toggleterm.nvim**: Advanced terminal management with state restoration

## Key Bindings

### Leader Key
Leader key is set to `<Space>` (space)

### Essential Shortcuts
- `<C-f>` - Find files (Telescope)
- `<C-Space>` - Live grep search
- `<leader><leader>b` - Browse buffers
- `<C-n>` - Toggle file tree
- `<C-M-n>` - Toggle tree and find current file
- `<C-t>` - Toggle floating terminal
- `<C-M-t>` - Toggle horizontal terminal
- `<leader>cc` - Copilot chat

### Session Management
- `<leader>sp` - Pick session (Telescope)
- Session management also available via `session-nvim` bash command

### Custom Language Support (Lits)
- `<leader>L` - Open Lits editor
- In Lits editor:
  - `<leader><CR>` - Evaluate and insert result
  - `<leader>e` - Evaluate and preview result
  - `<leader>s` - Save as
  - `<leader>o` - Open file
  - `<leader>l` - Open in Lits Playground

### ASCII Diagrams (Graph-Easy)
- `<leader>ad` - Generate diagram from buffer/selection

### Buffer Management
- `<leader><Tab>` - Toggle to last buffer
- `<leader>bd` - Delete current buffer (smart)
- `<leader>bc` - Close all buffers except current
- Mouse back/forward buttons - Navigate jump list

### Git Workflow
- `<leader>va` - Stage hunk (GitSigns)
- `<leader>vx` - Reset hunk (GitSigns)
- `<leader>vX` - Reset buffer (GitSigns)
- `<leader>gg` - Open Neogit
- `<leader>gc` - Git commit (Neogit)
- `<leader>gd` - Toggle diffview
- `<leader>gh` - File history (Diffview)

### Testing (JavaScript/TypeScript)
- `<leader>tr` - Run nearest test
- `<leader>tf` - Run tests in current file
- `<leader>ta` - Run all tests
- `<leader>ts` - Toggle test summary
- `<leader>td` - Debug nearest test

### Debugging
- `<leader>db` - Toggle breakpoint
- `<leader>dc` - Continue debugging
- `<leader>ds` - Step over
- `<leader>di` - Step into
- `<leader>bl` - List all breakpoints (Telescope)

### Enhanced Search
- `<leader><leader>G` - Live grep with arguments
- `<leader><leader>w` - Search word under cursor
- `<leader><leader>W` - Search WORD under cursor
- `<leader>S` - Toggle Spectre (project search/replace)

### Symbol Insertion (Telescope)
- `<leader><leader>ss` - All symbols
- `<leader><leader>se` - Emoji symbols
- `<leader><leader>sa` - Arrow symbols
- `<leader><leader>si` - Indicator symbols
- `<leader><leader>sc` - Currency symbols
- `<leader><leader>sf` - Fraction symbols

### Diagnostics and Utilities
- `<leader>cd` - Copy diagnostic under cursor
- `<leader>cm` - Copy last message
- `<leader>ll` - Toggle Trouble diagnostics
- `<leader>ms` - My custom snippets
- `<leader>na` - Add note to ~/notes/_notes.md

## Installation

1. **Backup existing configuration**:
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. **Clone this configuration**:
   ```bash
   git clone <your-repo-url> ~/.config/nvim
   ```

3. **Install dependencies**:
   - Ensure you have Neovim 0.9+ installed
   - Install a Nerd Font for proper icon display
   - Install ripgrep for telescope: `brew install ripgrep`
   - Install Node.js for LSP servers and Copilot
   - Install jq for JSON formatting: `brew install jq`
   - Install stylua for Lua formatting: `brew install stylua`
   - **For Graph-Easy support**: Install Graph::Easy Perl module:
     ```bash
     brew install cpanminus
     cpanm Graph::Easy
     ```
   - **For Lits support**: Install the Lits language interpreter

4. **Optional: Bash session management**:
   Add to your `~/.bashrc` or `~/.bash_profile`:
   ```bash
   source ~/.config/nvim/session.bash
   ```

5. **First launch**:
   ```bash
   nvim
   ```
   Lazy.nvim will automatically install all plugins on first run.

## Custom Features

### Advanced Session Management
The configuration includes a sophisticated session management system:
- **Project-based sessions**: Automatically creates sessions per directory
- **Session locking**: Prevents conflicts when multiple instances access the same project
- **History tracking**: Maintains buffer access history and recent sessions
- **Telescope integration**: Browse and switch sessions with fuzzy finding
- **Bash integration**: Use `session-nvim` command from terminal for session management

Session commands:
```bash
session-nvim                    # Interactive session picker
session-nvim open [pattern]     # Open session by pattern
session-nvim goto [pattern]     # Change to session directory
session-nvim delete <path>      # Delete specific session
session-nvim clean              # Remove stale locks
```

### Lits Language Integration
Full integration for the Lits programming language:
- **Dedicated editor**: Popup editor with syntax highlighting
- **Live evaluation**: Execute Lits code and see results
- **File management**: Save, load, and organize Lits programs
- **Result insertion**: Insert evaluation results directly into buffers
- **Playground integration**: Open current code in Lits Playground

### Graph-Easy ASCII Diagrams
Generate ASCII diagrams from text descriptions:
- **Multiple formats**: Support for boxart, ASCII, SVG, HTML, and DOT
- **Live preview**: Interactive popup with format switching
- **Browser integration**: Open diagrams in browser for sharing
- **Comprehensive syntax**: Support for nodes, edges, and styling

Example diagram syntax:
```
[ Start ] -> [ Process ] -> [ End ]
[ Process ] -> [ Error ] { color: red; }
```

### Smart Snippet System
The configuration includes a custom snippet system with placeholder expansion:
- **Date placeholders**: `{date:date}`, `{date:time}`, `{date:day}`, `{date:week}`
- **File placeholders**: `{file:name}`, `{file:rel}`, `{file:abs}`
- **Environment**: `{cwd}`

Access via `<leader>ms` to open the snippet picker.

### Project-Specific Configuration
The configuration supports project-specific settings through `.nvim.lua` files:

1. Create a `.nvim.lua` file in your project root
2. Add project-specific settings, keybindings, or plugin configurations
3. The configuration will automatically load when entering the directory

Example `.nvim.lua`:
```lua
-- Set specific options for this project
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- Project-specific keybindings
vim.keymap.set('n', '<leader>pr', ':!npm run build<CR>')
```

### Smart Formatting
The configuration includes intelligent formatting that chooses the right tool:
- **JavaScript/TypeScript**: ESLint via none-ls
- **Lua**: StyLua
- **Other languages**: LSP formatting

Use `<leader>lf` for smart formatting.

## Language-Specific Features

### JavaScript/TypeScript
- ESLint integration with auto-fixing (`<leader>lF`)
- Import organization (`<leader>lo`)
- TypeScript-tools for enhanced TS support
- Vitest test runner integration with smart detection
- Emmet support for JSX/TSX

### Python
- Virtual environment selector (`VenvSelect`)
- Pyright LSP integration
- DAP debugging support

### Lua
- StyLua formatting integration
- Neovim API auto-completion via lazydev
- Enhanced development experience for Neovim plugins

### Web Development
- Emmet abbreviations (`<C-Z>` leader)
- Color highlighting for CSS
- Package.json version management
- Auto-tag closing for HTML/JSX

### Git Integration
- Comprehensive diff and merge capabilities
- Interactive staging and unstaging
- Branch management and history browsing
- Conflict resolution tools

## Troubleshooting

### Common Issues

1. **LSP not working**: Run `:LspInfo` to check server status
2. **Plugins not loading**: Run `:Lazy sync` to update plugins
3. **Copilot not working**: Check `:Copilot status` and ensure you're authenticated
4. **Tests not running**: Verify Vitest is installed and configuration files exist
5. **Formatting issues**: Check if appropriate formatters (stylua, eslint_d) are installed
6. **Session conflicts**: Use `session-nvim clean` to remove stale locks
7. **Graph-Easy not working**: Ensure Graph::Easy Perl module is installed
8. **Lits not working**: Ensure Lits interpreter is installed and in PATH

### Useful Commands

- `:checkhealth` - Comprehensive health check
- `:Mason` - Manage LSP servers and tools
- `:Lazy` - Plugin manager interface
- `:LspRestart` - Restart language servers
- `:ProjectReload` - Reload project-specific configuration
- `:CloseOutsideRoot` - Close buffers outside project root
- `:SessionPick` - Pick session (same as `<leader>sp`)
- `:Lits` - Open Lits editor
- `:GraphEasy` - Generate ASCII diagram

### Diagnostic Utilities

The configuration includes utilities for working with diagnostics:
- Copy diagnostics to clipboard
- Navigate between diagnostic issues
- Enhanced diagnostic display via Trouble

## Performance

This configuration is optimized for performance:
- Lazy loading of plugins based on file types and commands
- Efficient use of autocommands and event handling
- Minimal startup time with deferred initialization
- Smart session management to avoid loading unnecessary state
- Optimized ripgrep configuration for fast searching

## Contributing

When modifying this configuration:
1. Keep plugin configurations modular and organized
2. Use descriptive commit messages
3. Test changes thoroughly
4. Update documentation as needed
5. Follow Lua best practices and coding standards

## License

This configuration is provided as-is for educational and personal use. Individual plugins maintain their respective licenses.
