local M = {}
local defaults = {
    global_patterns = {}, -- List of patterns to match for everything
    register_patterns = {}, -- List of patterns to match for specific registers
    ft_patterns = {}, -- List of patterns to match for specific filetypes
    registers = { '"', "1", "-" }, -- List of registers to monitor (only need "1" for 1-9)
    system_clipboard = "", -- Use the system clipboard
    remap_paste = true, -- Remap p and P to sync with clipboard settings
}

-- Setup function for the plugin
function M.setup(opts)
    local options = opts or {}
    local filter = require("regisfilter.filter")

    -- Populate options table
    for k, v in pairs(defaults) do
        options[k] = options[k] or v
    end

    -- Override system clipboard option
    if vim.opt.clipboard["_value"] ~= "" then
        options.system_clipboard = vim.opt.clipboard["_value"]
    end
    vim.opt.clipboard = ""

    -- Populate register cache
    _G.registers = {}
    for _, reg in ipairs(options.registers) do
        _G.registers[tostring(reg)] = vim.fn.getreg(tostring(reg), 1) or ""
    end
    if options.system_clipboard == "unnamed" then
        _G.registers['"'] = vim.fn.getreg("*", 1)
    elseif options.system_clipboard == "unnamedplus" then
        _G.registers['"'] = vim.fn.getreg("+", 1)
    end

    -- Override setreg
    vim.fn.setreg = function(reg, val, ...) ---@diagnostic disable-line: duplicate-set-field
        return filter.setreg_custom(options, reg, val, ...)
    end

    -- Create TextYankPost autocommand
    vim.api.nvim_create_autocmd("TextYankPost", {
        pattern = "*",
        callback = function()
            filter.diff(options)
        end,
    })

    -- Create paste autocommand
    if options.remap_paste then
        vim.api.nvim_create_user_command(
            "RegisfilterPaste",
            function() filter.clipboard(options) end,
            { nargs = 0 }
        )
        vim.api.nvim_create_augroup("RegisfilterPaste", {})
        vim.api.nvim_create_autocmd("BufEnter", {
            group = "RegisfilterPaste",
            callback = function()
                vim.api.nvim_set_keymap("n", "p", ":RegisfilterPaste<CR>p", { noremap = true, silent = true })
                vim.api.nvim_set_keymap("n", "P", ":RegisfilterPaste<CR>P", { noremap = true, silent = true })
                vim.api.nvim_create_augroup("RegisfilterPaste", {})
            end
        })
    end
end

return M
