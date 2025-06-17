# Neovim Configuration

A modern, feature-rich Neovim configuration built with Lua, optimized for web development and general programming tasks.

## Features

- **Modern Plugin Management**: Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for fast and efficient plugin loading
- **LSP Integration**: Full Language Server Protocol support with auto-completion, diagnostics, and formatting
- **AI-Powered Development**: GitHub Copilot integration with chat interface
- **Advanced Git Integration**: GitSigns, Diffview, and comprehensive git workflows
- **Fuzzy Finding**: Telescope with live grep, file search, and project navigation
- **Testing Framework**: Neotest with Vitest integration for JavaScript/TypeScript projects
- **Session Management**: Auto-session with project-specific configurations
- **Debugging Support**: DAP (Debug Adapter Protocol) with breakpoint persistence
- **Terminal Integration**: Toggleterm with floating and split terminal options

## Directory Structure

```
├── init.lua                           # Entry point
├── lua/
│   ├── config/                        # Core configuration
│   │   ├── init.lua                   # Configuration loader
│   │   ├── options.lua                # Vim options and settings
│   │   ├── keymaps.lua                # Global keybindings
│   │   ├── autocmds.lua               # Auto-commands
│   │   ├── lazy.lua                   # Plugin manager setup
│   │   └── project.lua                # Project-specific config loader
│   ├── plugins/                       # Plugin configurations
│   │   ├── editor/                    # Editor enhancement plugins
│   │   ├── lang/                      # Language-specific plugins
│   │   ├── copilot/                   # AI assistance plugins
│   │   └── ui/                        # UI and theme plugins
│   └── utils/                         # Utility functions
├── generateDoc.bash                   # Documentation generation script
└── .gitignore                         # Git ignore file
```

## Key Plugins

### Core Development
- **nvim-lspconfig**: Language Server Protocol integration
- **nvim-cmp**: Auto-completion engine
- **nvim-treesitter**: Syntax highlighting and text objects
- **telescope.nvim**: Fuzzy finder and picker
- **gitsigns.nvim**: Git integration with sign column

### AI Assistance
- **copilot.vim**: GitHub Copilot code suggestions
- **CopilotChat.nvim**: AI-powered chat interface for code assistance

### Testing & Debugging
- **neotest-vitest**: Test runner integration for Vitest
- **nvim-dap**: Debug Adapter Protocol support with breakpoint persistence
- **nvim-dap-ui**: Debug interface

### Editor Enhancements
- **harpoon**: Quick file navigation and bookmarking
- **yanky.nvim**: Enhanced yank/paste with history
- **nvim-surround**: Surround text objects manipulation
- **undotree**: Visual undo history
- **which-key**: Keybinding discovery

### Language Support
- **typescript-tools.nvim**: Enhanced TypeScript/JavaScript support
- **venv-selector.nvim**: Python virtual environment management
- **emmet-vim**: HTML/CSS expansion
- **package-info.nvim**: NPM package version information

## Key Bindings

### Leader Key
Leader key is set to `,` (comma)

### Essential Shortcuts
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep search
- `<leader>fb` - Browse buffers
- `<leader>gs` - Git status
- `<Ctrl-n>` - Toggle file tree
- `<leader>tt` - Toggle terminal
- `<leader>cc` - Copilot chat

### Buffer Management
- `<Tab>` / `<S-Tab>` - Navigate between buffers
- `<leader>1-9` - Quick switch to buffer by number
- `<leader>bd` - Delete current buffer (smart)
- `<leader>bc` - Close all buffers except current

### Git Workflow
- `<leader>ga` - Stage hunk
- `<leader>gr` - Reset hunk
- `<leader>gp` - Preview hunk
- `<leader>gb` - Blame line
- `<leader>gdo` - Open diff view

### Testing (JavaScript/TypeScript)
- `<leader>tr` - Run nearest test
- `<leader>tf` - Run tests in current file
- `<leader>ta` - Run all tests
- `<leader>ts` - Toggle test summary

### Debugging
- `<leader>db` - Toggle breakpoint
- `<leader>dc` - Continue debugging
- `<leader>ds` - Step over
- `<leader>di` - Step into

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

4. **First launch**:
   ```bash
   nvim
   ```
   Lazy.nvim will automatically install all plugins on first run.

## Documentation Generation

The `generateDoc.bash` script uses `tree-doc` to generate documentation:

```bash
#!/bin/bash
tree-doc -t "NeoVim Configuration" -i "*.lua" | pbcopy
```

This script:
- Generates a tree view of all Lua files
- Sets the title to "NeoVim Configuration"
- Copies the output to clipboard (macOS)

Run it with: `./generateDoc.bash`

## Project-Specific Configuration

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

## Language-Specific Features

### JavaScript/TypeScript
- ESLint integration with auto-fixing
- Prettier formatting
- Import organization
- Vitest test runner integration

### Python
- Virtual environment selector
- Pyright LSP integration
- Auto-formatting with Black (when configured)

### Lua
- StyLua formatting integration
- Neovim API auto-completion
- Lazy.nvim plugin development support

### Web Development
- Emmet abbreviations
- Color highlighting for CSS
- Live server integration
- Package.json version management

## Customization

### Adding New Plugins
Create a new file in the appropriate directory under `lua/plugins/`:

```lua
-- lua/plugins/my-plugin.lua
return {
  {
    "author/plugin-name",
    config = function()
      -- Plugin configuration
    end,
  },
}
```

### Modifying Keybindings
Edit `lua/config/keymaps.lua` or add to specific plugin configurations.

### Theme Customization
Modify `lua/plugins/ui/catppuccin.lua` or replace with your preferred colorscheme.

## Troubleshooting

### Common Issues

1. **LSP not working**: Run `:LspInfo` to check server status
2. **Plugins not loading**: Run `:Lazy sync` to update plugins
3. **Copilot not working**: Check `:Copilot status` and ensure you're authenticated
4. **Tests not running**: Verify Vitest is installed in your project

### Useful Commands

- `:checkhealth` - Comprehensive health check
- `:Mason` - Manage LSP servers and tools
- `:Lazy` - Plugin manager interface
- `:LspRestart` - Restart language servers
- `:ProjectReload` - Reload project-specific configuration

## Performance

This configuration is optimized for performance:
- Lazy loading of plugins based on file types and commands
- Efficient use of autocommands
- Minimal startup time with deferred initialization
- Smart session management to avoid loading unnecessary state

## Contributing

When modifying this configuration:
1. Keep plugin configurations modular and organized
2. Use descriptive commit messages
3. Test changes thoroughly
4. Update documentation as needed
5. Follow Lua best practices and coding standards

## License

This configuration is provided as-is for educational and personal use. Individual plugins maintain their respective licenses.
