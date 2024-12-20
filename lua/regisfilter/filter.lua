local M = {}

-- Save value of vim.fn.setreg
M.setreg_orig = vim.fn.setreg

-- Override vim.fn.setreg to update the register table
function M.setreg_custom(opts, reg, val, ...)
    local ret = M.setreg_orig(reg, val, ...)
    M.diff(opts)
    return ret
end

-- Check which register was updated
function M.diff(opts)
    for _, reg in ipairs(vim.g.registers) do
        if vim.g.registers[reg] ~= vim.fn.getreg(reg) then
            if M.filter(reg, opts) then
                M.update_reg(opts, reg, vim.g.registers[reg])
            else
                M.update_cache(reg)
            end
        end
    end
end

-- Handle special cases for registers
function M.update_reg(opts, reg, val)
    if reg == '"' then
        vim.fn.setreg_orig('"', val)
        if string.find(opts.system_clipboard, "unnamed") then
            vim.fn.setreg("*", val)
        end
        if string.find(opts.system_clipboard, "unnamedplus") then
            vim.fn.setreg("+", val)
        end
    elseif reg == '1' then
        for i = 9, 1, -1 do
            vim.fn.setreg_orig(tostring(i), vim.g.registers[tostring(i)])
        end
    else
        vim.fn.setreg_orig(reg, val)
    end
end

-- Update the cache with the current register value
function M.update_cache(reg)
    if reg == "1" then
        for i = 9, 1, -1 do
            vim.g.registers[tostring(i)] = vim.fn.getreg(tostring(i))
        end
    else
        vim.g.registers[reg] = vim.fn.getreg(reg)
    end
end

-- Match the register against the patterns
function M.filter(reg, opts)
    local new = vim.fn.getreg(reg)

    for _, pattern in ipairs(opts.patterns) do
        if new:match(pattern) then
            return true
        end
    end

    for _, pattern in ipairs(opts.ft_patterns[vim.bo.filetype] or {}) do
        if new:match(pattern) then
            return true
        end
    end

    return false
end

return M
