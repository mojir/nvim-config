-- Create a new file: lua/plugins/copilot.lua

return {
  -- GitHub Copilot
  {
    'github/copilot.vim',
    config = function()
      -- Disable default tab mapping to avoid conflicts with nvim-cmp
      vim.g.copilot_no_tab_map = true
      
      -- Set up custom keymaps
      vim.keymap.set('i', '<C-g>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = 'Accept Copilot suggestion'
      })
      
      -- Navigation through suggestions (Mac-friendly alternatives)
      vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)', { desc = 'Next Copilot suggestion' })
      vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)', { desc = 'Previous Copilot suggestion' })
      
      -- Dismiss suggestion
      vim.keymap.set('i', '<C-\\>', '<Plug>(copilot-dismiss)', { desc = 'Dismiss Copilot suggestion' })
      
      -- Configure Copilot settings
      vim.g.copilot_filetypes = {
        ['*'] = false,
        python = true,
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
        lua = true,
        html = true,
        css = true,
        scss = true,
        json = true,
        yaml = true,
        markdown = true,
        bash = true,
        sh = true,
        vim = true,
      }
    end,
  },

  -- Copilot Chat (AI-powered chat interface)
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim' },
    },
    opts = {},
    config = function()
      require('CopilotChat').setup({
        debug = false,
        show_help = true,
        question_header = '## User ',
        answer_header = '## Copilot ',
        error_header = '## Error ',
        auto_follow_cursor = true,
        auto_insert_mode = true,
        clear_chat_on_new_prompt = false,
        context = nil,
        history_path = vim.fn.stdpath('data') .. '/copilotchat_history',
        selection = function(source)
          return require('CopilotChat.select').visual(source) or require('CopilotChat.select').buffer(source)
        end,
      })
      
      -- Keymaps for CopilotChat
      vim.keymap.set('n', '<leader>cc', ':CopilotChat ', { desc = 'Copilot Chat' })
      vim.keymap.set('v', '<leader>ce', ':CopilotChatExplain<CR>', { desc = 'Copilot explain selection' })
      vim.keymap.set('n', '<leader>cr', ':CopilotChatReview<CR>', { desc = 'Copilot review code' })
      vim.keymap.set('n', '<leader>cf', ':CopilotChatFix<CR>', { desc = 'Copilot fix code' })
      vim.keymap.set('n', '<leader>co', ':CopilotChatOptimize<CR>', { desc = 'Copilot optimize code' })
      vim.keymap.set('n', '<leader>cd', ':CopilotChatDocs<CR>', { desc = 'Copilot generate docs' })
      vim.keymap.set('n', '<leader>ct', ':CopilotChatTests<CR>', { desc = 'Copilot generate tests' })
      vim.keymap.set('n', '<leader>cq', ':CopilotChatClose<CR>', { desc = 'Close Copilot Chat' })
      vim.keymap.set('n', '<leader>cs', ':CopilotChatStop<CR>', { desc = 'Stop Copilot Chat' })
      vim.keymap.set('n', '<leader>ch', ':CopilotChatReset<CR>', { desc = 'Reset Copilot Chat' })
      
      -- Inline prompts
      vim.keymap.set('v', '<leader>ci', ':CopilotChatInPlace<CR>', { desc = 'Copilot inline chat' })
      vim.keymap.set('n', '<leader>ci', function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
        end
      end, { desc = 'Copilot quick chat' })
      
      -- Toggle inline chat
      vim.keymap.set('n', '<leader>cv', ':CopilotChatToggle<CR>', { desc = 'Toggle Copilot Chat' })
    end,
  },
}
