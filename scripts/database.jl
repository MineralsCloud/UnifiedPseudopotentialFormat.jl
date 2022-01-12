using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using DataFrames: DataFrame, groupby
using JLD2: jldsave
using Pkg.Artifacts: artifact_hash, artifact_exists, create_artifact, bind_artifact!
using Pseudopotentials:
    CoreHole, ExchangeCorrelationFunctional, ValenceCoreState, Pseudization

using UnifiedPseudopotentialFormat: UPFFileName
using UnifiedPseudopotentialFormat.PSlibrary: ELEMENTS, list_elements

const ARTIFACT_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const LIBRARY_ROOT = "https://www.quantum-espresso.org/pseudopotentials/ps-library/"
const UPF_ROOT = "https://www.quantum-espresso.org"
const DOWNLOAD_URL_ROOT = "https://github.com/MineralsCloud/PseudopotentialArtifacts/raw/main/pslibrary/"

function _parsehtml(element)
    url = LIBRARY_ROOT * element
    path = download(url)
    str = read(path, String)
    doc = parsehtml(str)
    primates = root(doc)
    anchors = findall("//table//a", primates)
    return map(anchors) do anchor
        (
            name = strip(nodecontent(anchor)),
            src = UPF_ROOT * anchor["href"],
            metadata = nodecontent(nextelement(anchor)),
        )
    end
end

function makedb(element::String)
    database = DataFrame(
        element = [],
        rel = Bool[],
        corehole = UN{CoreHole}[],
        xc = UN{ExchangeCorrelationFunctional}[],
        cv = UN{Vector{<:ValenceCoreState}}[],
        pseudization = UN{Pseudization}[],
        src = String[],
        name = String[],
    )
    for meta in _parsehtml(lowercase(element))
        parsed = parse(UPFFileName, meta.name)
        push!(database, [fieldvalues(parsed)..., meta.src, meta.name])
    end
    return database
end
makedb(i::Integer) = makedb(ELEMENTS[i])

function serializedb(file, element)
    database = makedb(element)
    return jldsave(file; database)
end

function makeartifact(element::AbstractString)
    pslibrary_hash = artifact_hash("pslibrary", ARTIFACT_TOML)
    if pslibrary_hash === nothing || !artifact_exists(pslibrary_hash)
        element_hash = create_artifact() do artifact_dir
            download(
                "$(DOWNLOAD_URL_ROOT)/$element.jld2",
                joinpath(artifact_dir, "$element.jld2"),
            )
        end
        bind_artifact!(ARTIFACT_TOML, element, element_hash)
    end
end
makeartifact(i::Integer) = makeartifact(ELEMENTS[i])

fieldvalues(x::UPFFileName) = (
    getfield(x, i) for
    i in (:element, :fullrelativistic, :corehole, :xc, :valencecore, :pseudization)
)
