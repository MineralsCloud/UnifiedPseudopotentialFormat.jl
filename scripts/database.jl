using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using DataFrames: DataFrame, groupby
using JLD2: jldsave
using Pkg.Artifacts:
    artifact_hash, artifact_exists, create_artifact, archive_artifact, bind_artifact!
using Pseudopotentials:
    CoreHole, ExchangeCorrelationFunctional, ValenceCoreState, Pseudization

using UnifiedPseudopotentialFormat: UPFFile, analyzename
using UnifiedPseudopotentialFormat.PSlibrary: ELEMENTS, list_elements

const ARTIFACT_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")
const LIBRARY_URL_BASE = "http://pseudopotentials.quantum-espresso.org/legacy_tables/ps-library/"
const UPF_URL_BASE = "http://pseudopotentials.quantum-espresso.org/upf_files"
const DATABASE_URL_BASE = "https://github.com/MineralsCloud/PseudopotentialArtifacts/raw/main/pslibrary/"

function getrawdata(element)
    url = LIBRARY_URL_BASE * lowercase(element)
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
        element = String[],
        rel = Bool[],
        corehole = UN{CoreHole}[],
        xc = UN{ExchangeCorrelationFunctional}[],
        cv = UN{Vector{<:ValenceCoreState}}[],
        pseudization = UN{Pseudization}[],
        src = String[],
        name = String[],
    )
    for meta in getrawdata(element)
        info = analyzename(UPFFile(meta.name))
        push!(
            database,
            [
                (
                    getindex(info, i) for i in (
                        :element,
                        :fullrelativistic,
                        :corehole,
                        :xc,
                        :valencecore,
                        :pseudization,
                    )
                )...,
                meta.src,
                meta.name,
            ],
        )
    end
    return database
end
makedb(i::Integer) = makedb(ELEMENTS[i])
function makedb()
    data = mapreduce(makedb, append!, ELEMENTS)
    return groupby(data, :element)
end

function savedb(file, element)
    database = makedb(element)
    return jldsave(file; database)
end
function savedb(file)
    database = makedb()
    return jldsave(file; database)
end

function makeartifact(element::AbstractString)
    dir_hash = artifact_hash(element, ARTIFACT_TOML)
    if dir_hash === nothing || !artifact_exists(dir_hash)
        dir_hash = create_artifact() do artifact_dir
            savedb(joinpath(artifact_dir, "$element.jld2"), element)
        end
        tar_hash = archive_artifact(dir_hash, "$element.tar.gz")
        bind_artifact!(
            ARTIFACT_TOML,
            element,
            dir_hash;
            download_info = [(DATABASE_URL_BASE * "$element.tar.gz", tar_hash)],
            lazy = true,
        )
    end
end
makeartifact(i::Integer) = makeartifact(ELEMENTS[i])
function makeartifact()
    dir_hash = artifact_hash("all", ARTIFACT_TOML)
    if dir_hash === nothing || !artifact_exists(dir_hash)
        dir_hash = create_artifact() do artifact_dir
            savedb(joinpath(artifact_dir, "all.jld2"))
        end
        tar_hash = archive_artifact(dir_hash, "all.tar.gz")
        bind_artifact!(
            ARTIFACT_TOML,
            "all",
            dir_hash;
            download_info = [(DATABASE_URL_BASE * "all.tar.gz", tar_hash)],
            lazy = true,
        )
    end
end
