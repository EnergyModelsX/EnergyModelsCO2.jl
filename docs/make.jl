using Documenter
using EnergyModelsCO2


DocMeta.setdocmeta!(EnergyModelsCO2, :DocTestSetup, :(using EnergyModelsCO2); recursive=true)

# Copy the NEWS.md file
BASE_PATH = joinpath(splitpath(@__DIR__)[1:end - 1])
news_cp_path = joinpath(BASE_PATH, "docs/src/manual/NEWS.md")
if isfile(news_cp_path)
    rm(news_cp_path)
end
cp(joinpath(BASE_PATH, "NEWS.md"), news_cp_path)

makedocs(;
    modules=[EnergyModelsCO2],
    authors="Sigmund Eggen Holm <sigmund.holm@sintef.no> and contributors",
    repo="https://gitlab.sintef.no/clean_export/EnergyModelsCO2.jl/blob/{commit}{path}#{line}",
    sitename="EnergyModelsCO2.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://clean_export.pages.sintef.no/EnergyModelsCO2.jl/",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Release notes" => "manual/NEWS.md",
        ],
        "Library" => Any[
            "Public" => "library/public.md",
            "Internals" => "library/internals.md",
        ]
    ],
)
