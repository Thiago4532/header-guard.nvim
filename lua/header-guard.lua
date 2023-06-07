local vim = vim
local api = vim.api
local util = require'header-guard.util'

local M = {
    util = util
}

local opts = {}

local function getline(bufnr, line)
    return api.nvim_buf_get_lines(bufnr, line - 1, line, true)[1]
end

local function setline(bufnr, line, value)
    return api.nvim_buf_set_lines(bufnr, line - 1, line, true, {value})
end

local function find_header_guard(bufnr)
    bufnr = bufnr or 0

    local line_count = api.nvim_buf_line_count(bufnr)

    local ifndef_line, endif_line
    for i=1,line_count do
        local line = getline(bufnr, i)

        if not line:find('^%s*$') and not line:find('^%s*//') then
            local guard_name = line:match('^#ifndef%s+(.+)$')
            if not guard_name then
                return nil, nil, "failed to find #ifndef"
            end

            if i == line_count then
                return nil, nil, "failed to find #define after #ifndef"
            end

            local define_pattern_1 = string.format('^#define%%s+%s$', guard_name)
            local define_pattern_2 = string.format('^#define%%s+%s%%s+', guard_name)

            local n_line = getline(bufnr, i + 1)
            if not n_line:find(define_pattern_1) and not n_line:find(define_pattern_2) then
                return nil, nil, "failed to find #Define after #ifndef"
            end

            ifndef_line = i
            break
        end
    end

    for i=line_count,1,-1 do
        local line = getline(bufnr, i)

        if not line:find('^%s*$') and not line:find('^%s*//') then
            if line:find('^#endif') then
                endif_line = i
                break
            end

            return nil, nil, "failed to find #endif"
        end
    end

    return ifndef_line, endif_line
end

local function setTimeout(timeout, callback)
  local timer = vim.loop.new_timer()
  timer:start(timeout, 0, function ()
    timer:stop()
    timer:close()
    callback()
  end)
  return timer
end

M.setup = function(tbl)
    opts = {
        guard_name = util.gen_guard_name, -- The function used to generate the name of the header guard.
        endif_comment = true, -- Add a comment after the #endif statement. (e.g.: #endif // _INCLUDE_)
        use_block_commentary = false, -- Use block comments instead of inline after the #endif statement. (Only works if endif_comment is true)
    }

    if config ~= nil then
        for k, v in pairs(tbl) do
            opts[k] = v
        end
    end
end

M.guard_name = function()
    return opts.guard_name()
end

M.update_header_guard = function()
    local ifndef_line, endif_line, err = find_header_guard()
    if err then
        return util.error('header-guard: find_header_guard: ', err)
    end

    local name = M.guard_name()
    if name == nil then
        return util.error('header-guard: failed to generate a header guard name')
    end

    setline(0, ifndef_line,     '#ifndef ' .. name)
    setline(0, ifndef_line + 1, '#define ' .. name)

    if opts.endif_comment then
        if opts.use_block_commentary then
            setline(0, endif_line, string.format('#endif /* %s */', name))
        else
            setline(0, endif_line, string.format('#endif // %s',    name))
        end
    else
        setline(0, endif_line, '#endif')
    end
end

-- Automatic setup using metatables

setmetatable(opts, {
    __index = function(_, key)
        M.setup {}
        return opts[key]
    end
})

return M
