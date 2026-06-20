local M = {}

local number_words = {
	one = 1,
	two = 2,
	three = 3,
	four = 4,
	five = 5,
	six = 6,
	seven = 7,
	eight = 8,
	nine = 9,
	ten = 10,
	eleven = 11,
	twelve = 12,
	thirteen = 13,
	fourteen = 14,
	fifteen = 15,
	sixteen = 16,
	seventeen = 17,
	eighteen = 18,
	nineteen = 19,
	twenty = 20,
	["twenty one"] = 21,
	["twenty two"] = 22,
	["twenty three"] = 23,
	["twenty four"] = 24,
	["twenty five"] = 25,
	thirty = 30,
	forty = 40,
	fifty = 50,
}

local function to_num(word)
	return tonumber(word) or number_words[word]
end

M.map = {
	-- File
	["save"] = ":w<CR>",
	["save file"] = ":w<CR>",
	["save and quit"] = ":wq<CR>",
	["quit"] = ":q<CR>",
	["force quit"] = ":q!<CR>",
	["new file"] = ":enew<CR>",

	-- Navigation
	["go to top"] = "gg",
	["go to bottom"] = "G",
	["next word"] = "w",
	["previous word"] = "b",
	["end of line"] = "$",
	["start of line"] = "0",
	["first character"] = "^",
	["scroll down"] = "<C-d>",
	["scroll up"] = "<C-u>",
	["center"] = "zz",
	["next paragraph"] = "}",
	["previous paragraph"] = "{",
	["matching bracket"] = "%",

	-- Editing
	["delete line"] = "dd",
	["delete word"] = "dw",
	["delete character"] = "x",
	["change line"] = "cc",
	["change word"] = "cw",
	["undo"] = "u",
	["redo"] = "<C-r>",
	["copy line"] = "yy",
	["paste"] = "p",
	["paste above"] = "P",
	["indent"] = ">>",
	["unindent"] = "<<",
	["join lines"] = "J",
	["duplicate line"] = "yyp",
	["delete to end"] = "D",
	["change to end"] = "C",

	-- Modes
	["insert"] = "i",
	["insert mode"] = "i",
	["append"] = "a",
	["open below"] = "o",
	["open above"] = "O",
	["normal"] = "<Esc>",
	["normal mode"] = "<Esc>",
	["visual"] = "v",
	["visual mode"] = "v",
	["visual line"] = "V",
	["visual block"] = "<C-v>",

	-- Search
	["search"] = "/",
	["next match"] = "n",
	["previous match"] = "N",
	["clear search"] = ":noh<CR>",

	-- Splits
	["split"] = ":sp<CR>",
	["vertical split"] = ":vsp<CR>",
	["close split"] = "<C-w>c",
	["move right"] = "<C-w>l",
	["move left"] = "<C-w>h",
	["move up"] = "<C-w>k",
	["move down"] = "<C-w>j",

	-- Tabs
	["new tab"] = ":tabnew<CR>",
	["next tab"] = "gt",
	["previous tab"] = "gT",
	["close tab"] = ":tabclose<CR>",

	-- LSP
	["go to definition"] = "gd",
	["go to reference"] = "gr",
	["hover"] = "K",
	["rename"] = "<leader>rn",
	["code action"] = "<leader>ca",
	["show diagnostics"] = "<leader>xx",
	["next error"] = "]d",
	["previous error"] = "[d",

	-- LazyVim Core & Subcommands
	["lazy home"] = ":Lazy home<CR>",
	["lazy install"] = ":Lazy install<CR>",
	["lazy update"] = ":Lazy update<CR>",
	["lazy sync"] = ":Lazy sync<CR>",
	["lazy clean"] = ":Lazy clean<CR>",
	["lazy check"] = ":Lazy check<CR>",
	["lazy log"] = ":Lazy log<CR>",
	["lazy show"] = ":Lazy show<CR>",
	["lazy restore"] = ":Lazy restore<CR>",
	["lazy profile"] = ":Lazy profile<CR>",
	["lazy debug"] = ":Lazy debug<CR>",
	["lazy clear"] = ":Lazy clear<CR>",
	["lazy build"] = ":Lazy build<CR>",
	["lazy health"] = ":checkhealth lazy<CR>",
	["lazy help"] = ":Lazy help<CR>",
	["lazy extras"] = ":LazyExtras<CR>",

	-- LSP Keymaps
	["lsp info"] = "<leader>cl",
	["go to references"] = "gr",
	["show references"] = "gr",
	["go to implementation"] = "gI",
	["go to declaration"] = "gD",
	["go to type definition"] = "gy",
	["show documentation"] = "K",
	["signature help"] = "gK",
	["rename symbol"] = "<leader>cr",
	["rename file"] = "<leader>cR",

	-- Bufferline.nvim (Buffer tabs)
	["toggle pin"] = "<leader>bp",
	["delete non pinned buffers"] = "<leader>bP",
	["delete buffers right"] = "<leader>br",
	["delete buffers left"] = "<leader>bl",
	["pick buffer"] = "<leader>bj",
	["move buffer previous"] = "[B",
	["move buffer next"] = "]B",

	-- Snacks.nvim (Toggles, Notifier, Profiler)
	["toggle format"] = "<leader>uf",
	["toggle format write"] = "<leader>uF",
	["toggle spelling"] = "<leader>us",
	["toggle wrap"] = "<leader>uw",
	["toggle relative number"] = "<leader>uL",
	["toggle diagnostics"] = "<leader>ud",
	["toggle line number"] = "<leader>ul",
	["toggle conceal"] = "<leader>uc",
	["toggle tabline"] = "<leader>uA",
	["toggle treesitter"] = "<leader>uT",
	["toggle background"] = "<leader>ub",
	["toggle dim"] = "<leader>uD",
	["toggle animate"] = "<leader>ua",
	["toggle indent"] = "<leader>ug",
	["toggle scroll"] = "<leader>uS",
	["toggle inlay hints"] = "<leader>uh",
	["toggle zen"] = "<leader>uz",
	["toggle zoom"] = "<leader>uZ",
	["toggle git signs"] = "<leader>uG",
	["notification history"] = "<leader>n",
	["dismiss notifications"] = "<leader>un",
	["toggle profiler"] = "<leader>dpp",
	["toggle profiler highlights"] = "<leader>dph",

	-- Flash.nvim
	["flash search"] = "s",
	["flash"] = "s",
	["flash treesitter"] = "S",
	["remote flash"] = "r",
	["treesitter search"] = "R",
	["treesitter selection"] = "<c-space>",
	["incremental selection"] = "<c-space>",

	-- Noice.nvim
	["noice last"] = "<leader>snl",
	["noice history"] = "<leader>snh",
	["noice all"] = "<leader>sna",
	["dismiss all"] = "<leader>snd",
	["noice picker"] = "<leader>snt",
	["scroll forward"] = "<c-f>",
	["scroll backward"] = "<c-b>",

	-- Trouble.nvim
	["trouble diagnostics"] = "<leader>xx",
	["diagnostics list"] = "<leader>xx",
	["trouble buffer diagnostics"] = "<leader>xX",
	["trouble symbols"] = "<leader>cs",
	["trouble lsp"] = "<leader>cS",
	["trouble location list"] = "<leader>xL",
	["trouble quickfix"] = "<leader>xQ",
	["previous trouble item"] = "[q",
	["next trouble item"] = "]q",

	-- Todo-Comments.nvim
	["next todo"] = "]t",
	["previous todo"] = "[t",
	["trouble todo"] = "<leader>xt",
	["trouble todo fixme"] = "<leader>xT",
	["todo search"] = "<leader>st",
	["find todo"] = "<leader>st",
	["todo search fixme"] = "<leader>sT",

	-- Which-Key.nvim
	["show keymaps"] = "<leader>?",
	["which key"] = "<leader>?",
	["window hydra"] = "<c-w><space>",

	-- Harpoon.nvim
	["harpoon file"] = "<leader>H",
	["harpoon add"] = "<leader>H",
	["harpoon menu"] = "<leader>h",
	["harpoon quick menu"] = "<leader>h",
	["harpoon file one"] = "<leader>1",
	["harpoon file two"] = "<leader>2",
	["harpoon file three"] = "<leader>3",
	["harpoon file four"] = "<leader>4",
	["harpoon file five"] = "<leader>5",
	["harpoon file six"] = "<leader>6",
	["harpoon file seven"] = "<leader>7",
	["harpoon file eight"] = "<leader>8",
	["harpoon file nine"] = "<leader>9",

	-- Search / File Finders (Fzf-lua or Telescope)
	["find files"] = "<leader><space>",
	["find file"] = "<leader>ff",
	["find files current directory"] = "<leader>fF",
	["find git files"] = "<leader>fg",
	["command history"] = "<leader>:",
	["find text"] = "<leader>/",
	["live grep"] = "<leader>/",
	["live grep current directory"] = "<leader>sG",
	["search history"] = "<leader>s/",
	["search buffer lines"] = "<leader>sb",
	["search open buffers"] = "<leader>sB",
	["search registers"] = '<leader>s"',
	["search autocommands"] = "<leader>sa",
	["search document diagnostics"] = "<leader>sd",
	["search workspace diagnostics"] = "<leader>sD",
	["search help"] = "<leader>sh",
	["search highlights"] = "<leader>sH",
	["search keymaps"] = "<leader>sk",
	["search options"] = "<leader>so",
	["search resume"] = "<leader>sR",

	-- Grug-Far.nvim
	["search and replace"] = "<leader>sr",
	["grug far"] = "<leader>sr",

	-- Git / Gitsigns
	["next hunk"] = "]h",
	["previous hunk"] = "[h",
	["last hunk"] = "]H",
	["first hunk"] = "[H",
	["stage hunk"] = "<leader>ghs",
	["reset hunk"] = "<leader>ghr",
	["stage buffer"] = "<leader>ghS",
	["undo stage hunk"] = "<leader>ghu",
	["reset buffer"] = "<leader>ghR",
	["preview hunk"] = "<leader>ghp",
	["blame line"] = "<leader>ghb",
	["blame buffer"] = "<leader>ghB",
	["diff this"] = "<leader>ghd",
	["diff this tilde"] = "<leader>ghD",
}

function M.parse(phrase)
	phrase = phrase:lower():gsub("[%.%?,!]", ""):gsub("^%s*(.-)%s*$", "%1")

	-- "lazy load <plugin>"
	local plugin = phrase:match("^lazy load ([%w%-%._]+)$")
	if plugin then
		return ":Lazy load " .. plugin .. "<CR>"
	end

	-- "lazy build <plugin>"
	plugin = phrase:match("^lazy build ([%w%-%._]+)$")
	if plugin then
		return ":Lazy build " .. plugin .. "<CR>"
	end

	-- "go down <n> lines" → <n>j
	local n = phrase:match("^go down (%w[%w ]*) lines?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. "j"
		end
	end

	-- "go up <n> lines" → <n>k
	n = phrase:match("^go up (%w[%w ]*) lines?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. "k"
		end
	end

	-- "go to line <n>" → :<n><CR>
	n = phrase:match("^go to line number (%w[%w ]*)")
	if n then
		local num = to_num(n)
		if num then
			return ":" .. num .. "<CR>"
		end
	end

	-- "delete <n> lines" → <n>dd
	n = phrase:match("^delete (%w[%w ]*) lines?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. "dd"
		end
	end

	-- "copy <n> lines" → <n>yy
	n = phrase:match("^copy (%w[%w ]*) lines?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. "yy"
		end
	end

	-- "indent <n> lines"
	n = phrase:match("^indent (%w[%w ]*) lines?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. ">>"
		end
	end

	-- "next <n> words" → <n>w
	n = phrase:match("^next (%w+) words?$")
	if n then
		local num = to_num(n)
		if num then
			return num .. "w"
		end
	end

	-- exact match
	if M.map[phrase] then
		return M.map[phrase]
	end

	-- partial match
	for cmd, keys in pairs(M.map) do
		if phrase:find(cmd, 1, true) then
			return keys
		end
	end

	return nil
end

return M
