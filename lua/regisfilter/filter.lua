local M = {}

-- Save value of vim.fn.setreg
M.setreg = vim.fn.setreg

-- Override vim.fn.setreg to update the register table
function M.setreg_custom(opts, reg, val, ...)
    local ret = M.setreg(reg, val, ...)
    M.diff(opts)
    return ret
end

-- Custom clipboard handling
function M.clipboard(opts)
    if opts.system_clipboard == "unnamed" then
        M.setreg('"', vim.fn.getreg("*"))
    end
    if opts.system_clipboard == "unnamedplus" then
        M.setreg('"', vim.fn.getreg("+"))
    end
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
        M.setreg('"', val)
        if opts.system_clipboard == "unnamed" then
            M.setreg("*", val)
        end
        if opts.system_clipboard == "unnamedplus" then
            M.setreg("+", val)
        end
    elseif reg == '1' then
        for i = 9, 1, -1 do
            M.setreg(tostring(i), vim.g.registers[tostring(i)])
        end
    else
        M.setreg(reg, val)
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
