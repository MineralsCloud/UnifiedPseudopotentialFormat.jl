using UnifiedPseudopotentialFormat
using Documenter

DocMeta.setdocmeta!(UnifiedPseudopotentialFormat, :DocTestSetup, :(using UnifiedPseudopotentialFormat); recursive=true)

makedocs(;
    modules=[UnifiedPseudopotentialFormat],
    authors="singularitti <singularitti@outlook.com> and contributors",
    repo="https://github.com/MineralsCloud/UnifiedPseudopotentialFormat.jl/blob/{commit}{path}#{line}",
    sitename="UnifiedPseudopotentialFormat.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/UnifiedPseudopotentialFormat.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/UnifiedPseudopotentialFormat.jl",
    devbranch="main",
)
