using SpaceTrack
using Documenter

DocMeta.setdocmeta!(Example20250122, :DocTestSetup, :(using Example20250122); recursive=true)

makedocs(
    modules=[SpaceTrack],
    authors="Ben Elsen <mail@benelsen.com>",
    sitename="SpaceTrack.jl",
    format=Documenter.HTML(;
        canonical="https://benelsen.github.io/Example20250122.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/benelsen/SpaceTrack.jl",
    target = "build",
    push_preview = true,
)
