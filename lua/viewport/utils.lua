local utils = {}

function utils.debounce(func, delay_ms)
  local timer = vim.uv.new_timer()
  local last_call_args = {}

  return function(...)
    last_call_args = { ... }
    timer:stop()
    timer:start(delay_ms, 0, vim.schedule_wrap(function()
      func(unpack(last_call_args))
    end))
  end
end

return utils
