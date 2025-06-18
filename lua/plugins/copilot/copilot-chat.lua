return {
  -- Copilot Chat (AI-powered chat interface)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
    },
    cmd = {
      "CopilotChat",
      "CopilotChatExplain",
      "CopilotChatReview", 
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
      "CopilotChatTests",
      "CopilotChatToggle",
      "CopilotChatInPlace",
    },
    keys = {
      { "<leader>cc", ":CopilotChat ", desc = "Copilot Chat" },
      { "<leader>ce", ":CopilotChatExplain<CR>", mode = "v", desc = "Copilot explain selection" },
      { "<leader>cr", ":CopilotChatReview<CR>", desc = "Copilot review code" },
      { "<leader>cf", ":CopilotChatFix<CR>", desc = "Copilot fix code" },
      { "<leader>co", ":CopilotChatOptimize<CR>", desc = "Copilot optimize code" },
      { "<leader>cd", ":CopilotChatDocs<CR>", desc = "Copilot generate docs" },
      { "<leader>ct", ":CopilotChatTests<CR>", desc = "Copilot generate tests" },
      { "<leader>cq", ":CopilotChatClose<CR>", desc = "Close Copilot Chat" },
      { "<leader>cs", ":CopilotChatStop<CR>", desc = "Stop Copilot Chat" },
      { "<leader>ch", ":CopilotChatReset<CR>", desc = "Reset Copilot Chat" },
      { "<leader>ci", ":CopilotChatInPlace<CR>", mode = "v", desc = "Copilot inline chat" },
      { 
        "<leader>ci", 
        function()
          local input = vim.fn.input("Quick Chat: ")
          if input ~= "" then
            require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
          end
        end, 
        desc = "Copilot quick chat" 
      },
      { "<leader>cv", ":CopilotChatToggle<CR>", desc = "Toggle Copilot Chat" },
    },
    opts = {
      debug = false,
      show_help = true,
      question_header = "## User ",
      answer_header = "## Copilot ",
      error_header = "## Error ",
      auto_follow_cursor = true,
      auto_insert_mode = true,
      clear_chat_on_new_prompt = false,
      context = nil,
      history_path = vim.fn.stdpath("data") .. "/copilotchat_history",
      selection = function(source)
        return require("CopilotChat.select").visual(source) or require("CopilotChat.select").buffer(source)
      end,
    },
  },
}
