vim.g.mapleader = " "
vim.o.nu = true
vim.o.rnu = true
vim.o.tabstop = 2
vim.o.swapfile = false
vim.o.backup = false
vim.o.udofile = true
vim.o.hlsearch = false
vim.o.wrap = false
vim.loader.enable()
vim.cmd("imap <C-c> <Esc>")
vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

local nameSpaceId = vim.api.nvim_create_namespace("markdown")
local maxLineLength = 80
function CheckForLongLine()
	if vim.fn.col(".") > maxLineLength then
		vim.api.nvim_buf_set_extmark(0, nameSpaceId, vim.fn.line(".") - 1, 0, {
			id = vim.fn.line("."),
			virt_text = { { "Exceeding max line length (" .. maxLineLength .. ")", "WarningMsg" } },
			virt_text_pos = "right_align",
		})
	else
		vim.api.nvim_buf_del_extmark(0, nameSpaceId, vim.fn.line("."))
	end
end

vim.cmd("autocmd TextChangedI *.md lua CheckForLongLine()")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					local opts = { buffer = event.buf }
					vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
					vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
					vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
					vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
					vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
					vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
					vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
					vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
					vim.keymap.set({ "n", "x" }, "<F3>",
						"<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
					vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
				end,
			})

			local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

			local default_setup = function(server)
				require("lspconfig")[server].setup({
					capabilities = lsp_capabilities,
				})
			end
			require("mason").setup()
			require("mason-lspconfig").setup({
				handlers = {
					default_setup,
				},
			})

			local cmp = require("cmp")
			local luasnip = require("luasnip")

			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
				    and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") ==
				    nil
			end

			cmp.setup({
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}),
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
			})

			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					file_ignore_patterns = { ".git", "node_modules", "vendor" },
				},
			})

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>f", builtin.find_files, {})
			vim.keymap.set("n", "<leader>g", builtin.live_grep, {})
		end,
	},
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				skip_confirm_for_simple_edits = true,
			})
			vim.keymap.set("n", "-", "<CMD>Oil<CR>")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				auto_install = true,
				ignore_install = { "html", "css" },
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = true,
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"windwp/nvim-ts-autotag",
		opts = {},
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.keymap.set("n", "<leader>xx", function()
				require("trouble").toggle()
			end)
		end,
	},
	{
		"crispgm/nvim-tabline",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional
		config = function()
			vim.keymap.set("n", "<leader>l", ":tabn<CR>")
			vim.keymap.set("n", "<leader>h", ":tabp<CR>")
			vim.keymap.set("n", "<leader>c", ":tabnew<CR>")
			vim.keymap.set("n", "<leader>w", ":tabc<CR>")
			vim.keymap.set("n", "<leader>L", ":tabmove<CR>")
		end,
	},
	{
		"terrortylor/nvim-comment",
		config = function()
			require("nvim_comment").setup({
				comment_empty = false,
			})
			vim.keymap.set("n", "<C-/>", ":CommentToggle<CR>")
			vim.keymap.set("v", "<C-/>", ":'<,'>CommentToggle<CR>")
		end,
	},
	{
		"ada0l/obsidian",
		keys = {
			{
				"<leader>ov",
				function()
					Obsidian.select_vault()
				end,
				desc = "Select Obsidian vault",
			},
			{
				"<leader>oo",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.cd_vault()
					end)
				end,
				desc = "Open Obsidian directory",
			},
			{
				"<leader>ot",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.open_today()
					end)
				end,
				desc = "Open today",
			},
			{
				"<leader>od",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write shift in days: " }, function(input_shift)
							local shift = tonumber(input_shift) * 60 * 60 * 24
							Obsidian.open_today(shift)
						end)
					end)
				end,
				desc = "Open daily node with shift",
			},
			{
				"<leader>on",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Write name of new note: " }, function(name)
							Obsidian.new_note(name)
						end)
					end)
				end,
				desc = "New note",
			},
			{
				"<leader>oi",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_template("telescope")
					end)
				end,
				desc = "Insert template",
			},
			{
				"<leader>os",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.search_note("telescope")
					end)
				end,
				desc = "Search note",
			},
			{
				"<leader>ob",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.select_backlinks("telescope")
					end)
				end,
				desc = "Select backlink",
			},
			{
				"<leader>og",
				function()
					Obsidian.get_current_vault(function()
						Obsidian.go_to()
					end)
				end,
				desc = "Go to file under cursor",
			},
			{
				"<leader>or",
				function()
					Obsidian.get_current_vault(function()
						vim.ui.input({ prompt = "Rename file to" }, function(name)
							Obsidian.rename(name)
						end)
					end)
				end,
				desc = "Rename file with updating links",
			},
			{
				"gf",
				function()
					if Obsidian.found_wikilink_under_cursor() ~= nil then
						return "<cmd>lua Obsidian.get_current_vault(function() Obsidian.go_to() end)<CR>"
					else
						return "gf"
					end
				end,
				noremap = false,
				expr = true,
			},
		},
		opts = function()
			return {
				vaults = {
					{
						dir = "~/Sync/Notes/",
						daily = {
							dir = "Journals/",
							format = "%Y-%m-%d-%A",
						},
						templates = {
							dir = "Templates/",
							date = "%Y-%d-%m",
							time = "%Y-%d-%m",
						},
						note = {
							dir = "",
							transformator = function(filename)
								if filename ~= nil and filename ~= "" then
									return filename
								end
								return string.format("%d", os.time())
							end,
						},
					},
				},
			}
		end,
	},
	{
		"adalessa/laravel.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"tpope/vim-dotenv",
			"MunifTanjim/nui.nvim",
			"nvimtools/none-ls.nvim",
		},
		cmd = { "Sail", "Artisan", "Composer", "Npm", "Yarn", "Laravel" },
		keys = {
			{ "<leader>aa", ":Laravel artisan<cr>" },
		},
		event = { "VeryLazy" },
		config = true,
	},
})

vim.cmd("colorscheme catppuccin-mocha")
vim.cmd("highlight Normal ctermbg=none")
vim.cmd("highlight NonText ctermbg=none")
vim.cmd("highlight Normal guibg=none")
vim.cmd("highlight NonText guibg=none")
