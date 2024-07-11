local Buf = require("which-key.buf")
local Config = require("which-key.config")
local Icons = require("which-key.icons")
local Tree = require("which-key.tree")

local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error
local info = vim.health.info or vim.health.report_info

function M.check()
  if Icons.have() then
    ok("|mini.icons| installed and ready")
  else
    warn("|mini.icons| not installed. Keymap icon support will be limited.")
  end

  start("checking for overlapping keymaps")
  local found = false

  Buf.cleanup()

  ---@type table<string, boolean>
  local reported = {}

  for _, buf in pairs(Buf.bufs) do
    for mapmode in pairs(Config.modes) do
      local mode = buf:get({ mode = mapmode })
      if mode then
        mode.tree:walk(function(node)
          local km = node.keymap
          if not km or km.rhs == "" or km.rhs == "<Nop>" or node.keys:sub(1, 6) == "<Plug>" then
            return
          end
          if node.keymap and Tree.is_group(node) then
            local id = mode.mode .. ":" .. node.keys
            if reported[id] then
              return
            end
            reported[id] = true
            local overlaps = {}
            local queue = vim.tbl_values(node.children)
            while #queue > 0 do
              local child = table.remove(queue)
              if child.keymap then
                table.insert(overlaps, "<" .. child.keys .. ">")
              end
              vim.list_extend(queue, vim.tbl_values(child.children or {}))
            end
            if #overlaps > 0 then
              found = true
              warn(
                "In mode `" .. mode.mode .. "`, <" .. node.keys .. "> overlaps with " .. table.concat(overlaps, ", ")
              )
            end
            return false
          end
        end)
      end
    end
  end

  if found then
    ok(
      "Overlapping keymaps are only reported for informational purposes.\n"
        .. "This doesn't necessarily mean there is a problem with your config."
    )
  else
    ok("No overlapping keymaps found")
  end
end

return M
