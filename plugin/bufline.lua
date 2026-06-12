if vim.g.bufline_loaded then
	return
end
vim.g.bufline_loaded = true

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		require("bufline").setup()
	end,
})
