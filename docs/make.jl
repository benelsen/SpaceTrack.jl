using SpaceTrack
using Documenter

DocMeta.setdocmeta!(SpaceTrack, :DocTestSetup, :(using SpaceTrack); recursive=true)

makedocs(;
    modules=[SpaceTrack],
    authors="Ben Elsen <mail@benelsen.com>",
    repo="https://github.com/benelsen/SpaceTrack.jl/blob/{commit}{path}#{line}",
    sitename="SpaceTrack.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://benelsen.github.io/SpaceTrack.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/benelsen/SpaceTrack.jl",
    devbranch="main",
)
