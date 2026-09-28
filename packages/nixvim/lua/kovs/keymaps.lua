local function copy_to_clipboard(value, label)
	if value == "" then
		vim.notify(label .. " not found", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", value)
	vim.fn.setreg('"', value)
	vim.notify(label .. " copied: " .. value)
end
local function current_project_root()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return vim.fn.getcwd()
	end
	return vim.fs.root(path, { ".git" }) or vim.fn.getcwd()
end
vim.keymap.set("n", "<leader>yf", function()
	local name = vim.fn.expand("%:t")
	if name == "" then
		vim.notify("Filename not found", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", name)
	vim.fn.setreg('"', name)
	vim.notify("Filename copied: " .. name)
end, { desc = "[Y]ank [F]ilename" })
vim.keymap.set("n", "<leader>yp", function()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		copy_to_clipboard("", "Project path")
		return
	end
	local root = current_project_root()
	copy_to_clipboard(vim.fs.relpath(root, path) or vim.fn.fnamemodify(path, ":."), "Project path")
end, { desc = "[Y]ank project [P]ath" })

vim.keymap.set("n", "]3", function()
	vim.diagnostic.jump({ count = 1, float = false })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = false })
end, { desc = "Prev diagnostic" })

local function cycle_list(next_cmd, prev_cmd, first_cmd, last_cmd, dir)
	local ok, err = pcall(dir == 1 and next_cmd or prev_cmd)
	if not ok and err:match("E553") then
		if dir == 1 then
			first_cmd()
		else
			last_cmd()
		end
	end
end
vim.keymap.set("n", "]!", function()
	cycle_list(vim.cmd.cnext, vim.cmd.cprev, vim.cmd.cfirst, vim.cmd.clast, 1)
end, { desc = "Quickfix next" })
vim.keymap.set("n", "[q", function()
	cycle_list(vim.cmd.cnext, vim.cmd.cprev, vim.cmd.cfirst, vim.cmd.clast, -1)
end, { desc = "Quickfix prev" })
vim.keymap.set("n", "]9", function()
	cycle_list(vim.cmd.lnext, vim.cmd.lprev, vim.cmd.lfirst, vim.cmd.llast, 1)
end, { desc = "Location list next" })
vim.keymap.set("n", "[l", function()
	cycle_list(vim.cmd.lnext, vim.cmd.lprev, vim.cmd.lfirst, vim.cmd.llast, -1)
end, { desc = "Location list prev" })

vim.keymap.set("n", "]-", function()
	vim.cmd.normal({ "]c", bang = true })
end, { desc = "Diff next change" })
vim.keymap.set("n", "[c", function()
	vim.cmd.normal({ "[c", bang = true })
end, { desc = "Diff prev change" })

vim.keymap.set("i", "<A-c>", "<C-^>", { noremap = true, desc = "Switch language layout RU/EN" })
