using dolphindb
using Documenter

DocMeta.setdocmeta!(dolphindb, :DocTestSetup, :(using dolphindb); recursive=true)

makedocs(;
    modules=[dolphindb],
    authors="linan <linanisyugioh@163.com>",
    sitename="dolphindb.jl",
    format=Documenter.HTML(;
        canonical="https://linanisyugioh.github.io/dolphindb.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/linanisyugioh/dolphindb.jl",
    devbranch="master",
)
