local vim = vim
local api = vim.api

local M = {}

M.gen_guard_name = function()
    local path = vim.fn.expand('%:p')

    local function get_name(pattern)
        local match = path:match(pattern)
        if match == nil then
            return nil
        end

        return match:upper():gsub('[/.]', '_')
    end

    local name

    name = get_name('.*/include(/.*)')
    if name then return name end
    name = get_name('.*/src(/.*)')
    if name then return name end

    return nil
end

M.error = function(...)
    api.nvim_err_writeln(table.concat(vim.tbl_flatten({ ... })))
    -- api.nvim_command('redraw')
end


return M
