local M = {}

local buf, win

local function render()
	local bufs = vim.fn.getbufinfo({ buflisted = 1 })
	local current = vim.api.nvim_get_current_buf()
	local lines = {}

	for _, b in ipairs(bufs) do
		local name = b.name ~= "" and vim.fn.fnamemodify(b.name, ":~:.") or "[no name]"
		local modified = b.changed == 1 and " +" or ""
		local active = b.bufnr == current and "▌ " or "  "
		table.insert(lines, active .. name .. modified)
	end

	return lines
end

local function update()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = render()
	local width = 0
	for _, l in ipairs(lines) do
		width = math.max(width, #l)
	end
	width = math.max(width + 2, 20)

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_set_config(win, {
			relative = "editor",
			anchor = "NE",
			row = 1,
			col = vim.o.columns - 1,
			width = width,
			height = #lines,
		})
	end
end

function M.setup()
	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "hide"

	local lines = render()
	local width = 0
	for _, l in ipairs(lines) do
		width = math.max(width, #l)
	end
	width = math.max(width + 2, 20)

	win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 1,
		width = width,
		height = math.max(#lines, 1),
		style = "minimal",
		border = "none",
		focusable = false,
		zindex = 10,
	})

	vim.wo[win].cursorline = false
	vim.wo[win].winblend = 0

	vim.api.nvim_create_autocmd({
		"BufEnter",
		"BufAdd",
		"BufDelete",
		"BufWritePost",
		"WinResized",
	}, {
		callback = update,
	})
end

return M
