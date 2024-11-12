require("chris.core")
require("chris.lazy")

-- Define colors as variables
local active_bg = "#0a0a0a"
local inactive_bg = "#000000"

-- Base window dimming
vim.opt.winhighlight = "Normal:ActiveWindow,NormalNC:InactiveWindow"
vim.api.nvim_set_hl(0, "ActiveWindow", { bg = active_bg })
vim.api.nvim_set_hl(0, "InactiveWindow", { bg = inactive_bg })

-- Function to dim all windows
local function dim_windows()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].winhighlight = "Normal:InactiveWindow,NormalNC:InactiveWindow"
		end
	end
end

-- Function to restore window highlights
local function restore_windows()
	-- Set inactive windows
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].winhighlight = "Normal:InactiveWindow,NormalNC:InactiveWindow"
		end
	end
	-- Set active window
	vim.wo[vim.api.nvim_get_current_win()].winhighlight = "Normal:ActiveWindow,NormalNC:InactiveWindow"
end

-- Update nvim-tree highlights
local function update_nvim_tree(is_focused)
	if vim.bo.filetype == "NvimTree" then
		local bg = is_focused and active_bg or inactive_bg
		vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = bg })
		vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = bg })
		vim.api.nvim_set_hl(0, "NvimTreeVertSplit", { bg = bg })
		vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = bg, fg = inactive_bg })
	end
end

-- Set up autocommands
vim.api.nvim_create_augroup("WindowFocus", { clear = true })

-- Handle Tmux focus events
vim.api.nvim_create_autocmd("FocusLost", {
	group = "WindowFocus",
	callback = function()
		dim_windows()
		update_nvim_tree(false)
	end,
})

vim.api.nvim_create_autocmd("FocusGained", {
	group = "WindowFocus",
	callback = function()
		restore_windows()
		update_nvim_tree(true)
	end,
})

-- Handle window switching within Neovim
vim.api.nvim_create_autocmd("WinEnter", {
	group = "WindowFocus",
	callback = function()
		restore_windows()
		update_nvim_tree(true)
	end,
})
