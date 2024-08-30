using Documenter
using DocumenterInterLinks
using EnergyModelsBase
using EnergyModelsCO2
using TimeStruct

const EMB = EnergyModelsBase
const EMCO2 = EnergyModelsCO2

DocMeta.setdocmeta!(
    EnergyModelsCO2,
    :DocTestSetup,
    :(using EnergyModelsCO2);
    recursive = true,
)

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
if isfile(news)
    rm(news)
end
cp("NEWS.md", news)

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
)

makedocs(;
    sitename = "EnergyModelsCO2",
    modules = [EnergyModelsCO2],
    authors = "Sigmund Eggen Holm <sigmund.holm@sintef.no> and contributors",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
        ansicolor = true,
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Nodes" => Any[
            "CO₂ source" => "nodes/source.md",
            "CO₂ storage" => "nodes/storage.md",
            "CO₂ retrofit" => "nodes/retrofit.md",
        ],
        "How to" => Any[
            "Contribute to EnergyModelsCO2" => "how-to/contribute.md",
            "Incorporate CO₂ capture retrofit in other nodes"=> "how-to/incorporate_retrofit.md",
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => String[
                "library/internals/types.md",
                "library/internals/methods-fields.md",
                "library/internals/methods-EMB.md",
            ],
        ],
    ],
    plugins=[links],
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsCO2.jl.git",
)
