using SpaceTrack
using Documenter

DocMeta.setdocmeta!(SpaceTrack, :DocTestSetup, :(using SpaceTrack); recursive=true)

makedocs(
    modules=[SpaceTrack],
    authors="Ben Elsen <mail@benelsen.com>",
    sitename="SpaceTrack.jl",
    format=Documenter.HTML(;
        canonical="https://benelsen.github.io/SpaceTrack.jl",
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
