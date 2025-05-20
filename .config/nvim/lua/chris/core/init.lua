require("chris.core.options")
require("chris.core.keymaps")

vim.api.nvim_create_user_command("CC", function(opts)
	vim.cmd("CopilotChat " .. opts.args)
end, { nargs = 1 })
