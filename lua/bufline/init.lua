local M = {}
local buf, win
local hide_timer = nil
local visible = false

M.config = {
	path_depth = 1,
	border = "none",
	next_key = "<tab>",
	prev_key = "<s-tab>",
	timeout = 2000,
}

local function shorten(s, depth)
	if not depth then
		return s
	end
	local parts = {}
	for p in s:gmatch("[^/\\]+") do
		table.insert(parts, p)
	end
	if #parts <= depth then
		return s
	end
	local slice = {}
	for i = #parts - depth + 1, #parts do
		table.insert(slice, parts[i])
	end
	return table.concat(slice, "/")
end

local function render()
	local bufs = vim.fn.getbufinfo({ buflisted = 1 })
	local current = vim.api.nvim_get_current_buf()
	local lines = {}
	for _, b in ipairs(bufs) do
		local name = b.name ~= "" and shorten(vim.fn.fnamemodify(b.name, ":~:."), M.config.path_depth) or "[no name]"
		local modified = b.changed == 1 and " +" or ""
		table.insert(lines, "  " .. name .. modified)
	end
	return lines
end

local function highlight()
	local bufs = vim.fn.getbufinfo({ buflisted = 1 })
	local current = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
	for i, b in ipairs(bufs) do
		local hl = b.bufnr == current and "BuflineActive" or "BuflineInactive"
		vim.api.nvim_buf_add_highlight(buf, -1, hl, i - 1, 0, -1)
	end
end

local function hide()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
		win = nil
		visible = false
	end
end

local function show()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local lines = render()
	if #lines == 0 then
		return
	end
	local width = 0
	for _, l in ipairs(lines) do
		width = math.max(width, #l)
	end
	width = math.max(width + 2, 20)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	highlight()

	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end

	win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 1,
		width = width,
		height = #lines,
		style = "minimal",
		border = M.config.border,
		focusable = false,
		zindex = 10,
	})
	vim.wo[win].cursorline = false
	vim.wo[win].winblend = 0
	visible = true

	if hide_timer then
		hide_timer:stop()
	end
	if M.config.timeout then
		hide_timer = vim.defer_fn(hide, M.config.timeout)
	end
end

function M.setup()
	vim.api.nvim_set_hl(0, "BuflineActive", { link = "Normal" })
	vim.api.nvim_set_hl(0, "BuflineInactive", { link = "Comment" })

	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "hide"

	vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufDelete", "BufWritePost" }, {
		callback = show,
	})

	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if visible then
				show()
			end
		end,
	})

	vim.keymap.set("n", M.config.next_key, function()
		local bufs = vim.fn.getbufinfo({ buflisted = 1 })
		local current = vim.api.nvim_get_current_buf()
		for i, b in ipairs(bufs) do
			if b.bufnr == current then
				local next = bufs[i + 1] or bufs[1]
				vim.api.nvim_set_current_buf(next.bufnr)
				return
			end
		end
	end, { desc = "next buffer" })

	vim.keymap.set("n", M.config.prev_key, function()
		local bufs = vim.fn.getbufinfo({ buflisted = 1 })
		local current = vim.api.nvim_get_current_buf()
		for i, b in ipairs(bufs) do
			if b.bufnr == current then
				local prev = bufs[i - 1] or bufs[#bufs]
				vim.api.nvim_set_current_buf(prev.bufnr)
				return
			end
		end
	end, { desc = "prev buffer" })
end

return M
