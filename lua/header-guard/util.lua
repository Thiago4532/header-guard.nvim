local vim = vim
local api = vim.api

local M = {}

M.gen_guard_name = function()
    local path = vim.fn.expand('%:p')

    local function get_name(pattern)
        local match1, match2 = path:match(pattern)
        if match1 == nil then
            return nil
        end
        local match = match2 == nil
                    and match1
                    or match1 .. match2

        return match:upper():gsub('[/.]', '_')
    end

    local name

    name = get_name('.*/include(/.*)')
    if name then return name end
    name = get_name('.*/(.*)/src(/.*)')
    if name then return name end

    return nil
end

M.error = function(...)
    api.nvim_err_writeln(table.concat(vim.tbl_flatten({ ... })))
    -- api.nvim_command('redraw')
end


return M
