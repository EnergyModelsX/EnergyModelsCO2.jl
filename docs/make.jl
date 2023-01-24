using EnergyModelsCO2
using Documenter

DocMeta.setdocmeta!(EnergyModelsCO2, :DocTestSetup, :(using EnergyModelsCO2); recursive=true)

makedocs(;
    modules=[EnergyModelsCO2],
    authors="Sigmund Eggen Holm <sigmund.holm@sintef.no> and contributors",
    repo="https://github.com/sigmund.holm@sintef.no/EnergyModelsCO2.jl/blob/{commit}{path}#{line}",
    sitename="EnergyModelsCO2.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://sigmund.holm@sintef.no.github.io/EnergyModelsCO2.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="gitlab.sintef.no/sigmund.holm/EnergyModelsCO2.jl",
    devbranch="master",
)
