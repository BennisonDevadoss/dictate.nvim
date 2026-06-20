local M = {}
local commands = require("dictate.commands")

-- Resolve absolute path to the plugin root directory, resolving symlinks for development
local source_file = debug.getinfo(1).source:sub(2)
local plugin_root = vim.fn.fnamemodify(vim.fn.resolve(source_file), ":h:h:h")

M.config = {
	voice = "Samantha",
	rate = 180,
	stt_script = plugin_root .. "/bin/daemon.py",
	python_path = plugin_root .. "/.venv/bin/python3",
	stt_args = {},
	notify = true,

	insert_commands = {
		["stop listening"] = function()
			M.stop()
		end,
		["normal mode"] = function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "m", true)
		end,
		["new line"] = function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "m", true)
		end,
		["delete word"] = function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>", true, false, true), "m", true)
		end,
		["delete line"] = function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "m", true)
		end,
		["tab"] = function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "m", true)
		end,
	},
}

local listen_job = nil
local listening = false

-- ── TTS ──────────────────────────────────────────────────────────────────

local function speak(text)
	text = text:gsub("'", "'\\''")
	vim.fn.jobstart(string.format("say -v '%s' -r %d '%s'", M.config.voice, M.config.rate, text), { detach = true })
end

-- ── Mode check ────────────────────────────────────────────────────────────

local function current_mode()
	return vim.api.nvim_get_mode().mode
end

-- ── Dictate text at cursor ────────────────────────────────────────────────

local function dictate(text)
	if M.config.notify then
		vim.notify("✍️  " .. text, vim.log.levels.INFO)
	end
	vim.api.nvim_put({ text }, "c", true, true)
end

-- ── Execute normal mode command ───────────────────────────────────────────

local function execute_command(phrase)
	local keys = commands.parse(phrase)
	if keys then
		if M.config.notify then
			vim.notify("🎤 " .. phrase .. " → " .. keys, vim.log.levels.INFO)
			speak(phrase)
		end
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "m", true)
	else
		vim.notify('🎤 Unknown: "' .. phrase .. '"', vim.log.levels.WARN)
		speak("Unknown command")
	end
end

-- ── Mode-aware phrase handler ─────────────────────────────────────────────

local function handle_phrase(phrase)
	local mode = current_mode()

	if mode == "i" then
		local clean_phrase = phrase:lower():gsub("[%.%?,!]", ""):gsub("^%s*(.-)%s*$", "%1")
		local insert_cmd = M.config.insert_commands[clean_phrase]
		if insert_cmd then
			if M.config.notify then
				vim.notify("🎤 " .. clean_phrase, vim.log.levels.INFO)
			end
			insert_cmd()
		else
			dictate(phrase)
		end
	elseif mode == "n" or mode == "v" or mode == "V" or mode == "\22" then
		execute_command(phrase)
	elseif mode == "c" then
		vim.api.nvim_feedkeys(phrase, "m", true)
	else
		execute_command(phrase)
	end
end

-- ── Start / Stop / Toggle ─────────────────────────────────────────────────

function M.start()
	if listening then
		vim.notify("Dictate: already listening", vim.log.levels.WARN)
		return
	end
	listening = true
	speak("Listening")
	vim.notify("🎤 Voice ON", vim.log.levels.INFO)

	local python_bin = M.config.python_path
	if vim.fn.executable(python_bin) ~= 1 then
		python_bin = "python3"
	end

	local cmd = { python_bin, M.config.stt_script }
	if M.config.stt_args and #M.config.stt_args > 0 then
		for _, arg in ipairs(M.config.stt_args) do
			table.insert(cmd, arg)
		end
	end

	listen_job = vim.fn.jobstart(cmd, {
		stdout_buffered = false,
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				line = vim.trim(line)
				if line == "READY" then
					vim.schedule(function()
						vim.notify("✅ Mic ready — speak a command", vim.log.levels.INFO)
					end)
				elseif line ~= "" then
					vim.schedule(function()
						handle_phrase(line)
					end)
				end
			end
		end,
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line ~= "" then
					vim.schedule(function()
						vim.notify("Dictate error: " .. line, vim.log.levels.ERROR)
					end)
				end
			end
		end,
		on_exit = function()
			listening = false
			listen_job = nil
			vim.schedule(function()
				vim.notify("🔇 Voice OFF", vim.log.levels.INFO)
			end)
		end,
	})
end

function M.stop()
	if listen_job then
		vim.fn.jobstop(listen_job)
		listen_job = nil
		listening = false
		speak("Stopped")
	end
end

function M.toggle()
	if listening then
		M.stop()
	else
		M.start()
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("VoiceStart", M.start, {})
	vim.api.nvim_create_user_command("VoiceStop", M.stop, {})
	vim.api.nvim_create_user_command("VoiceToggle", M.toggle, {})

	vim.keymap.set("n", "<leader>vm", M.toggle, { desc = "Toggle voice commands" })
end

return M
