<!-- cspell:ignore nuspell nvim treesitter -->

# null-ls-typo-fix

A [`null-ls`](https://github.com/jose-elias-alvarez/null-ls.nvim) code action source for fixing typos via [`lua-nuspell`](https://github.com/f3fora/lua-nuspell) or ignoring cspell typo warnings via [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter).

## Usage

Before beginning, make sure you have [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) installed, and the markdown grammar enabled (as of this commit, it's current disabled by default cause there are some crashing issues).

```lua
use({
   "jose-elias-alvarez/null-ls.nvim",
   rocks = "lua-nuspell",
   requires = "mtoohey31/null-ls-typo-fix",
   config = function()
      local null_ls = require("null-ls")
      null_ls.config({
         sources = {
            -- Replace with your language, you'll need the corresonding dictionary installed
            require("typo_fix").setup("en_GB"),
         },
      })
   end,
})
```
