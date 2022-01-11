using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using DataFrames: DataFrame, groupby
using Pkg.Artifacts: artifact_hash
using Pseudopotentials:
    CoreHole, ExchangeCorrelationFunctional, ValenceCoreState, Pseudization

using UnifiedPseudopotentialFormat: UPFFileName
using UnifiedPseudopotentialFormat.PSlibrary: ELEMENTS, list_elements

const ARTIFACT_TOML = joinpath(@__DIR__, "Artifacts.toml")
const LIBRARY_ROOT = "https://www.quantum-espresso.org/pseudopotentials/ps-library/"
const UPF_ROOT = "https://www.quantum-espresso.org"

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
end

function uploaddb(path)
    url_base = "https://github.com/MineralsCloud/PseudopotentialArtifacts/pslibrary"
end

fieldvalues(x::UPFFileName) = (
    getfield(x, i) for
    i in (:element, :fullrelativistic, :corehole, :xc, :valencecore, :pseudization)
)
