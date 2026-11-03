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

    vim.system({"git", "log", "-n", "100"}, system_opts, function(out)
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

            local hash = x:match("^commit (%x+)")
            assert(#hash <= 64)

            ---@type lsp.CompletionItem
            local completion_item = {
                label = hash:sub(1, 7),
                documentation = {
                    kind = "plaintext",
                    value = x,
                },
                textEdit = {
                    newText = hash,
                    range = shared_range
                },
                kind = 21
            }
            table.insert(commit_completion_items, completion_item)
        end
    end):wait(1000)
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
    ---@type integer
    shared_range.start.line = params.context.cursor.line
    shared_range.start.character = params.context.cursor.character - 1
    shared_range["end"].line = params.context.cursor.line
    shared_range["end"].character = params.context.cursor.character

    get_commits()
    callback(commit_completion_items)
end

return source
