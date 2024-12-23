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
    M.update_cache(opts, '"')
end

-- Check which register was updated
function M.diff(opts)
    for reg, _ in pairs(_G.registers) do
        if M.filter(opts, reg) then
            M.update_reg(opts, reg)
        else
            M.update_cache(opts, reg)
        end
    end
end

-- Handle special cases for registers
function M.update_reg(opts, reg)
    if reg == '"' then
        if _G.registers[reg] ~= "" then
            if opts.system_clipboard == "unnamed" then
                M.setreg('"', vim.fn.getreg("*"))
            elseif opts.system_clipboard == "unnamedplus" then
                M.setreg('"', vim.fn.getreg("+"))
            else
                M.setreg('"', _G.registers[reg])
            end
        end
    elseif reg == "1" then
        for i = 1, 9, 1 do
            if _G.registers[tostring(i)] ~= "" then
                M.setreg(tostring(i), _G.registers[tostring(i)])
            end
        end
    else
        if _G.registers[reg] ~= "" then
            M.setreg(reg, _G.registers[reg])
        end
    end
end

-- Update the cache with the current register value
function M.update_cache(opts, reg)
    if reg == "1" then
        for i = 9, 1, -1 do
            _G.registers[tostring(i)] = vim.fn.getreg(tostring(i))
        end
    elseif reg == '"' then
        _G.registers['"'] = vim.fn.getreg('"')
        if opts.system_clipboard == "unnamed" then
            M.setreg("*", _G.registers['"'])
        elseif opts.system_clipboard == "unnamedplus" then
            M.setreg("+", _G.registers['"'])
        end
    else
        _G.registers[reg] = vim.fn.getreg(reg)
    end
end

-- Match the register against the patterns
function M.filter(opts, reg)
    local new = vim.fn.getreg(reg)

    for _, pattern in ipairs(opts.global_patterns) do
        if string.match(new, pattern) then
            return opts.negative_match
        end
    end

    for _, pattern in ipairs(opts.register_patterns[reg] or {}) do
        if string.match(reg, pattern) then
            return opts.negative_match
        end
    end

    for _, pattern in ipairs(opts.ft_patterns[vim.bo.filetype] or {}) do
        if string.match(reg, pattern) then
            return opts.negative_match
        end
    end

    return not opts.negative_match
end

return M
