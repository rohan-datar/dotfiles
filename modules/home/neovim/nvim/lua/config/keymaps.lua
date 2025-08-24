-- Set <space> as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Easily enter a newline in normal mode
vim.keymap.set("n", "<Enter>", "o<Esc>")

-- Move selected text around in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

--Keep cursor centered when scrolling
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Same thing but when moving through search terms
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever (thePrimagen), allows for pasted stuff to remain in the default register
vim.keymap.set("x", "<leader>p", [["_dP]])

-- also allow for deleting without copying
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- Quick replace word under my cursor everywhere in the document
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Go back to file explorer
vim.keymap.set("n", "<leader>ef", vim.cmd.Oil)

require("config.keymaps.terminal")
require("config.keymaps.diagnostics")
require("config.keymaps.lsp")
