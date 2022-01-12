using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using Artifacts:
    artifact_hash, artifact_exists, create_artifact, archive_artifact, bind_artifact!
using DataFrames: DataFrame, groupby
using JLD2: jldsave
using Pseudopotentials:
    CoreHole, ExchangeCorrelationFunctional, ValenceCoreState, Pseudization

using UnifiedPseudopotentialFormat: UPFFileName
using UnifiedPseudopotentialFormat.PSlibrary: ELEMENTS, list_elements

const ARTIFACT_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const LIBRARY_URL_BASE = "https://www.quantum-espresso.org/pseudopotentials/ps-library/"
const UPF_URL_BASE = "https://www.quantum-espresso.org"
const DATABASE_URL_BASE = "https://github.com/MineralsCloud/PseudopotentialArtifacts/raw/main/pslibrary/"

function getrawdata(element)
    url = LIBRARY_URL_BASE * element
    path = download(url)
    str = read(path, String)
    doc = parsehtml(str)
    primates = root(doc)
    anchors = findall("//table//a", primates)
    return map(anchors) do anchor
        (
            name = strip(nodecontent(anchor)),
            src = UPF_URL_BASE * anchor["href"],
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
    for meta in getrawdata(lowercase(element))
        parsed = parse(UPFFileName, meta.name)
        push!(database, [grepvalues(parsed)..., meta.src, meta.name])
    end
    return database
end
makedb(i::Integer) = makedb(ELEMENTS[i])

function savedb(file, element)
    database = makedb(element)
    return jldsave(file; database)
end

function makeartifact(element::AbstractString)
    element_hash = artifact_hash(element, ARTIFACT_TOML)
    if element_hash === nothing || !artifact_exists(element_hash)
        element_hash = create_artifact() do artifact_dir
            savedb(joinpath(artifact_dir, "$element.jld2"), element)
        end
        tar_hash = archive_artifact(element_hash, "$element.tar.gz")
        bind_artifact!(
            ARTIFACT_TOML,
            element,
            element_hash;
            download_info = [(DATABASE_URL_BASE * "$element.tar.gz", tar_hash)],
            lazy = true,
        )
    end
end
makeartifact(i::Integer) = makeartifact(ELEMENTS[i])

grepvalues(x::UPFFileName) = (
    getfield(x, i) for
    i in (:element, :fullrelativistic, :corehole, :xc, :valencecore, :pseudization)
)
