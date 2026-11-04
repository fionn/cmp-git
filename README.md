# cmp-git

Completion source for Git commits.

## Usage

Trigger completion with `:`, which will offer the previous 100 commits as completion candidates.

## Installation

Install this plugin, then add it as a completion source for Git commit messages with

```lua
cmp.setup.filetype("gitcommit", {
    ---@type cmp.SourceConfig[]
    sources = cmp.config.sources {
        {name = "git"}
    }
})
```
or similar.
