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
news = "src/manual/NEWS.md"
if isfile(news)
    rm(news)
end
cp("../NEWS.md", "src/manual/NEWS.md")

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
)

makedocs(;
    modules = [EnergyModelsCO2],
    authors = "Sigmund Eggen Holm <sigmund.holm@sintef.no> and contributors",
    repo = "https://gitlab.sintef.no/clean_export/EnergyModelsCO2.jl/blob/{commit}{path}#{line}",
    sitename = "EnergyModelsCO2",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://clean_export.pages.sintef.no/EnergyModelsCO2.jl/",
        edit_link = "main",
        assets = String[],
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
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => map(
                s -> "library/internals/$(s)",
                sort(readdir(joinpath(@__DIR__, "src/library/internals")))
            ),
        ]
    ],
    plugins=[links],
)
