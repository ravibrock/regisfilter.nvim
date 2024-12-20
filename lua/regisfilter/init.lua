local M = {}
local defaults = {
    patterns = {}, -- List of patterns to match
    ft_patterns = {}, -- List of patterns to match for specific filetypes
    registers = { '"', "1", "-" }, -- List of registers to monitor (only need "1" for 1-9)
    system_clipboard = "", -- Use the system clipboard
}

-- Setup function for the plugin
function M.setup(opts)
    local options = opts or {}
    local filter = require("filter")

    -- Populate options table
    for k, v in pairs(defaults) do
        options[k] = options[k] or v
    end

    -- Populate register cache
    vim.g.registers = {}
    for _, reg in ipairs(options.registers) do
        vim.g.registers[reg] = vim.fn.getreg(reg, 1)
    end

    -- Override system clipboard option
    if vim.opt.clipboard ~= "" then
        options.system_clipboard = vim.opt.clipboard
    end
    vim.opt.clipboard = ""

    -- Override setreg
    vim.fn.setreg = function(reg, val, ...) ---@diagnostic disable-line: duplicate-set-field
        return filter.setreg_custom(options, reg, val, ...)
    end

    -- Create TextYankPost autocommand
    vim.api.nvim_create_autocmd("TextYankPost", { "*", false, function() filter.diff(options) end })
end

return M
