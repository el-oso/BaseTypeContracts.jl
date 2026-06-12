using Documenter, DocumenterVitepress
using TypeContracts, BaseTypeContracts

makedocs(;
    modules = [BaseTypeContracts],
    authors = "el-oso",
    sitename = "BaseTypeContracts.jl",
    remotes = nothing,
    doctest = false,   # example blocks are illustrative ```julia, not jldoctests
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/el-oso/BaseTypeContracts.jl",
        devbranch = "master",
        devurl = "dev",
        description = "Ready-made TypeContracts contracts for Julia Base types.",
        sidebar_drawer = true,
    ),
    pages = [
        "Home" => "index.md",
        "Guide" => [
            "Getting Started" => "guide/getting-started.md",
            "The Base Contracts" => "guide/base-contracts.md",
            "Checking Types" => "guide/checking.md",
        ],
        "Reference" => [
            "API Reference" => "reference/api.md",
        ],
    ],
    checkdocs = :exports,
    warnonly = true,
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/el-oso/BaseTypeContracts.jl",
    devbranch = "master",
    push_preview = true,
)
