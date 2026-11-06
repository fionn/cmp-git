# cmp-git

Completion source for Git commits.

This is not aiming to be an omnibus plugin for Git-adjacent features, rather it attempts to do one thing and do it well.

## Usage

Trigger completion with `:`, which will offer the previous 100 commits as completion candidates.

## Installation

Install this plugin, then add it as a completion source for Git commit messages with

```lua
cmp.setup.filetype("gitcommit", {
    ---@type cmp.SourceConfig[]
    sources = cmp.config.sources {
        {name = "git", keyword_length = 4}
    }
})
```
or similar.

The `keyword_length` causes the completion to only be offered on a triggering character or a hexadecimal string of at least that length.
Set to `math.hugh` to disable keyword completion and require a triggering character.

## Features

* Completion for Git commits via:
  + triggering character,
  + keyword.
* Per-candidate documentation providing commit message and metadata.
* Zero configuration.
* Lazily loaded.
* Fast, via:
  + a single subprocess that runs only once,
  + cached results,
  + a shared table for edit ranges,
  + minimal parsing.
* Simple and maintainable code.
* Human made.

## Non-Features

* Git trailers:
  + use [fionn/cmp-git-trailers](https://github.com/fionn/cmp-git-trailers).
* Data from forges:
  + for GitHub issues, pull requests and users, use [fionn/cmp-github](https://github.com/fionn/cmp-github).

## Demo

<div align="center">
    <a href="https://asciinema.org/a/eVSsaTpbIlB4MacU"><img width="600" alt="Example Git commit completion using fionn/cmp-git" src="https://github.com/user-attachments/assets/2f341058-a475-46ef-a7b5-299aa9c46e17"></a>
</div>
