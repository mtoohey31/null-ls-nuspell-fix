local null_ls = require("null-ls")
local nuspell = require("nuspell")
local ts = vim.treesitter

local M = {}

---@param lang string the language to use
M.setup = function(lang)
  local source = {}

  local dirs = nuspell.search_default_dirs_for_dicts()
  local path = nuspell.find_dictionary(dirs, lang)
  local dict = nuspell.Dictionary.load_from_path(path)

  source.filetypes = { "markdown" }

  source.method = null_ls.methods.CODE_ACTION

  source.generator = {
    fn = function(params)
      -- Produce the current word by matching alpha characters plus `-` before and after the cursor
      local row = params.content[params.row]
      local after = row:sub(params.col + 1)
      local before = row:sub(0, params.col + 1)
      after = after:match("^[-%w]*")
      before = before:match("[-%w]*$")
      if after == nil or before == nil then
        return {}
      end
      before = before:sub(0, -2)
      local word = before:sub(0, -2) .. after

      -- Test if the current word can be spelled, if so, return empty suggestions
      if dict:spell(word) then
        return {}
      end

      local root = ts.get_parser(0, "markdown"):parse()[1]:root()
      local word_ignore_comment_query_string = '(html_block (text) @potential_comment (#match? @potential_comment "^\\\\<!-- ?cspell:ignore.* '
        .. word
        .. ' .*-->"))'
      local word_ignore_comment_query = ts.parse_query("markdown", word_ignore_comment_query_string)
      local num_captures = 0
      for _, _, _ in (word_ignore_comment_query:iter_captures(root, 0, 0, -1)) do
        num_captures = num_captures + 1
      end

      -- If the current word has already been ignored, return empty suggestions
      if num_captures ~= 0 then
        return {}
      end

      local suggestions = {}

      table.insert(suggestions, {
        title = "Ignore " .. word,
        action = function()
          local ignore_comment_query_string =
            [[(html_block (text) @potential_comment (#match? @potential_comment "^\\<!-- ?cspell:ignore.* -->"))]]
          local ignore_comment_query = ts.parse_query("markdown", ignore_comment_query_string)
          local first_node = nil
          for _, node, _ in (ignore_comment_query:iter_captures(root, 0, 0, -1)) do
            first_node = node
            break
          end
          if first_node ~= nil then
            local _, _, row_end, col_end = first_node:range()
            print(row_end .. col_end)
            vim.api.nvim_buf_set_text(params.bufnr, row_end, col_end - 4, row_end, col_end - 4, { " " .. word })
          else
            vim.api.nvim_buf_set_lines(params.bufnr, 0, 0, false, { "<!-- cspell:ignore " .. word .. " -->", "" })
          end
        end,
      })

      -- Iterate through all suggestions for the current word
      for _, suggestion in ipairs(dict:suggest(word)) do
        table.insert(suggestions, {
          title = "Change to " .. suggestion,
          action = function()
            -- Replace the exising word with the suggestion
            vim.api.nvim_buf_set_text(
              params.bufnr,
              params.row - 1,
              params.col - #before,
              params.row - 1,
              params.col + #after,
              { suggestion }
            )
          end,
        })
      end

      return suggestions
    end,
  }

  return source
end

return M
