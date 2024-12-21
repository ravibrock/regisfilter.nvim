# Regis(fil)ter.nvim

Regisfilter is a plugin that allows you to filter what gets sent to each register. For example, I use Neovim with the system clipboard integration, and I don't want single letters or blank lines sent to my clipboard if I delete them. It does this by maintaining a cache of register values and, when they're updated, checking the new value against the cache and either reverting the register using the cached value or updating the cache using the register value. See below for installation and usage instructions.

## Installation
I recommend using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    {
        "ravibrock/regisfilter.nvim",
        opts = {
            global_patterns = {}, -- List of patterns to match for everything
            register_patterns = {}, -- List of patterns to match for specific registers
            ft_patterns = {}, -- List of patterns to match for specific filetypes
            negative_match = true, -- Don't send to register if the pattern is matched
            registers = { '"', "1", "-" }, -- List of registers to monitor (only need "1" for 1-9)
            system_clipboard = "", -- Use the system clipboard (updates to vim.opt.clipboard if not empty)
            remap_paste = true, -- Remap p and P to sync with clipboard settings
        }
    }
}
```
You probably want to keep the default settings except for specifying `global_patterns`.

## Advanced configuration
You can use `register_patterns` and `ft_patterns` to define patterns to match for specific filetypes and registers (if, for example, you want certain things to be copied in C files but not Lua). Additionally, Regisfilter defines the command `:RegisfilterPaste`. Mapping `p` to `:RegisfilterPaste<CR>p` is what allows `p` to sync with the system clipboard. This is mostly intended for internal use, but setting `remap_paste` to `false` and remapping commands like `p` yourself allows for more fine-grained control over which keybinds are remapped.
