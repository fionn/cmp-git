---@diagnostic disable-next-line: name-style-check
local source = {}

---@type vim.SystemOpts
local system_opts = {
    text = true,
    timeout = 1000
}

---@type lsp.Range
local shared_range = {
    start = {line = 0, character = 0},
    ["end"] = {line = 0, character = 0}
}

---@type lsp.CompletionItem[]
local commit_completion_items = {}
local updated_commits = false

local function get_commits()
    if updated_commits then return end
    updated_commits = true

    local cmd = {
        "git", "log",
        "--expand-tabs=4", "--no-color", "--decorate=short",
        "-n", "100"
    }
    vim.system(cmd, system_opts, function(out)
        if out.code ~= 0 then
            vim.schedule(function()
                vim.notify("Failed to get commit log", vim.log.levels.ERROR)
            end)
        end

        for x in vim.gsplit(assert(out.stdout), "\ncommit ", {plain=true}) do
            if not string.match(x, "^commit ") then
                ---@type string
                x = "commit " .. x
            end

            ---@type string
            local hash = assert(x:match("^commit (%x+)"))
            assert(hash:len() >= 40 and hash:len() <= 64)

            ---@type string
            local title = x:match("\n\n    ([^\n]+)\n") or ""
            -- Ideally this would be truncated to 50 characters, with an …
            -- appended if necessary, but the completion menu truncates more
            -- aggressively anyway so we can save ourselves the trouble.

            ---@type lsp.CompletionItem
            local completion_item = {
                label = string.format("%s %s", hash:sub(1, 7), title),
                documentation = {
                    kind = "markdown",
                    value = string.format("```git\n%s\n```", x)
                },
                textEdit = {
                    newText = hash,
                    range = shared_range
                },
                kind = 21
            }
            table.insert(commit_completion_items, completion_item)
        end
    end):wait(system_opts.timeout)
end

---@diagnostic disable-next-line
function source:is_available()
    return vim.bo.filetype == "gitcommit"
end

---@return string[]
---@diagnostic disable-next-line
function source:get_trigger_characters()
    return {":"}
end

---@return string
---@diagnostic disable-next-line
function source:get_keyword_pattern()
    return [[\x\+]]
end

---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
---@diagnostic disable-next-line
function source:complete(params, callback)
    if params.context.cursor.row < 3 then
        -- The cursor is on the subject or gap between subject and body, where
        -- we don't expect to be completing commit hashes.
        callback()
        return
    end

    -- Because the triggering character ":" shouldn't be entered, we need to get
    -- the completion to eat it. We do this by setting the completion item's
    -- textEdit.range, which is a shared table that we update on completion.
    -- Because we micromanage this for the trigger character, we must also
    -- consider keyword completions.

    local backtrack = 1
    if params.completion_context.triggerKind ~= 2 then
        -- Not invoked via triggering character, so calculate how far we have to
        -- backtrack.
        local words = vim.split(params.context.cursor_before_line, " ", {plain=true})
        backtrack = words[#words]:len()
    end

    local line = params.context.cursor.line
    local character = assert(params.context.cursor.character)
    shared_range.start.line = line
    shared_range.start.character = character - backtrack
    shared_range["end"].line = line
    shared_range["end"].character = character

    get_commits()
    callback(commit_completion_items)
end

return source
