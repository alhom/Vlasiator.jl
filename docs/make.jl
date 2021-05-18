using Vlasiator, PyPlot
using Documenter

makedocs(;
    modules=[Vlasiator],
    authors="Hongyang Zhou <hongyang.zhou@helsinki.fi> and contributors",
    repo="https://github.com/henry2004y/Vlasiator.jl/blob/{commit}{path}#L{line}",
    sitename="Vlasiator.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://henry2004y.github.io/Vlasiator.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Example" => "examples.md",
        "Internal" => "internal.md",
        "Log" => "log.md",
    ],
)

deploydocs(;
    repo="github.com/henry2004y/Vlasiator.jl",
)