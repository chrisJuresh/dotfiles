return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- Creates a beautiful debugger UI
			{
				"rcarriga/nvim-dap-ui",
				dependencies = {
					"nvim-neotest/nvim-nio", -- Required dependency for nvim-dap-ui
				},
			},
			-- Virtual text for the debugger
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = {},
			},
		},
		-- stylua: ignore
		keys = {
			{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
			{ "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
			{ "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
			{ "<leader>dj", function() require("dap").down() end, desc = "Down" },
			{ "<leader>dk", function() require("dap").up() end, desc = "Up" },
			{ "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
			{ "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
			{ "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
			{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
			{ "<leader>ds", function() require("dap").session() end, desc = "Session" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
			{ "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			-- Setup dapui
			dapui.setup()
			-- Automatically open/close dapui when starting/stopping debug sessions
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Function to parse .env file (used for Python, kept for consistency)
			local function load_env_file(path)
				local env_vars = {}
				local file = io.open(path, "r")
				if file then
					for line in file:lines() do
						if not line:match("^%s*#") and line:match("%S") then
							local key, value = line:match("^%s*(%S+)%s*=%s*(.+)%s*$")
							if key and value then
								value = value:gsub("^[\"'](.+)[\"']$", "%1")
								env_vars[key] = value
							end
						end
					end
					file:close()
				end
				return env_vars
			end

			-- Adapters
			-- Node.js adapter (pwa-node)
			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}", -- DAP will find a free port
				executable = {
					command = "node",
					-- Ensure this path is correct and the vscode-js-debug server is functional
					args = { "/Users/christian.juresh/work/js-debug/src/dapDebugServer.js", "${port}" },
				},
			}

			-- Chrome adapter for client-side debugging (pwa-chrome)
			dap.adapters["pwa-chrome"] = {
				type = "server",
				host = "localhost",
				port = "${port}", -- DAP will find a free port
				executable = {
					command = "node",
					-- Uses the same vscode-js-debug server
					args = { "/Users/christian.juresh/work/js-debug/src/dapDebugServer.js", "${port}" },
				},
			}

			-- JavaScript and Next.js Configurations
			dap.configurations.javascript = {
				-- Your existing "Launch file" config
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch current file (Node)",
					program = "${file}",
					cwd = "${workspaceFolder}",
				},

				-- Next.js: debug server-side
				{
					type = "pwa-node",
					request = "launch",
					name = "Next.js: debug server-side",
					runtimeExecutable = "npm",
					runtimeArgs = { "run", "dev" }, -- Executes `npm run dev`
					cwd = "${workspaceFolder}",
					console = "integratedTerminal",
					autoAttachChildProcesses = true,
				},

				-- Next.js: debug client-side
				{
					type = "pwa-chrome",
					request = "launch",
					name = "Next.js: debug client-side",
					-- IMPORTANT: `next dev` usually runs on http://localhost:3000.
					-- Your VS Code config had 4000. Adjust if your `npm run dev`
					-- is specifically configured for a different port (e.g., 4000).
					url = "http://localhost:3000", -- ADJUST PORT IF NECESSARY
					webRoot = "${workspaceFolder}",
					sourceMaps = true,
					userDataDir = true, -- Recommended for a clean debugging environment
				},

				-- Next.js: debug full stack
				{
					type = "pwa-node", -- Primary process is the Node.js server
					request = "launch",
					name = "Next.js: debug full stack",
					runtimeExecutable = "npm",
					runtimeArgs = { "run", "dev" },
					cwd = "${workspaceFolder}",
					console = "integratedTerminal",
					autoAttachChildProcesses = true,
					serverReadyAction = {
						pattern = "started server on .+, url: (https?://.+)",
						uriFormat = "%s",
						action = "debugWithChrome", -- `vscode-js-debug` handles this
					},
				},
			}

			-- If you use TypeScript for your Next.js project, share the JavaScript configurations
			dap.configurations.typescript = dap.configurations.javascript

			-- Setup Python adapter (existing)
			dap.adapters.debugpy = {
				type = "executable",
				command = "python",
				args = { "-m", "debugpy.adapter" },
			}

			-- Python configuration with .env support (existing)
			dap.configurations.python = {
				{
					type = "debugpy",
					request = "launch",
					name = "Launch file (with .env)",
					program = "${file}",
					pythonPath = function()
						local cwd = vim.fn.getcwd()
						if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
							return cwd .. "/venv/bin/python"
						elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
							return cwd .. "/.venv/bin/python"
						else
							return "/usr/bin/python3" -- Consider using a more robust way to find python3
						end
					end,
					env = function()
						local cwd = vim.fn.getcwd()
						local env_path = cwd .. "/.env"
						local env_vars = load_env_file(env_path)
						-- Print for debugging if needed:
						-- print("Loaded .env variables for Python DAP:")
						-- for k, v in pairs(env_vars) do print(k, v) end
						return env_vars
					end,
				},
				{
					type = "debugpy",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						local cwd = vim.fn.getcwd()
						if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
							return cwd .. "/venv/bin/python"
						elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
							return cwd .. "/.venv/bin/python"
						else
							return "/usr/bin/python3" -- Fallback
						end
					end,
				},
			}
		end,
	},
	-- Optional: Add lazydev.nvim for type checking and better documentation
	{
		"folke/lazydev.nvim",
		opts = {
			library = { "nvim-dap-ui" },
		},
	},
}
