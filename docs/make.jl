using SpaceTrack
using Documenter

makedocs(
    modules=[SpaceTrack],
    sitename="SpaceTrack.jl",
    format=Documenter.HTML(;
        edit_link=nothing,
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/benelsen/SpaceTrack.jl",
    target = "build",
    deps   = nothing,
    make   = nothing,
    push_preview = true,
)
