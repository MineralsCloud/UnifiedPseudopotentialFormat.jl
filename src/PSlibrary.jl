module PSlibrary

using DataFrames: DataFrame, groupby
using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using JLD2: load
using LazyArtifacts
using MLStyle: @match
using Pseudopotentials:
    CoreHole, ExchangeCorrelationFunctional, ValenceCoreState, Pseudization
using Pkg.Artifacts: @artifact_str
using REPL.TerminalMenus: RadioMenu, request

using ..UnifiedPseudopotentialFormat: UPFFile

import Pseudopotentials: download_potential

export list_elements,
    list_potentials, download_potentials, download_potential, potential_exists

const ELEMENTS = (
    "h",
    "he",
    "li",
    "be",
    "b",
    "c",
    "n",
    "o",
    "f",
    "ne",
    "na",
    "mg",
    "al",
    "si",
    "p",
    "s",
    "cl",
    "ar",
    "k",
    "ca",
    "sc",
    "ti",
    "v",
    "cr",
    "mn",
    "fe",
    "co",
    "ni",
    "cu",
    "zn",
    "ga",
    "ge",
    "as",
    "se",
    "br",
    "kr",
    "rb",
    "sr",
    "y",
    "zr",
    "nb",
    "mo",
    "tc",
    "ru",
    "rh",
    "pd",
    "ag",
    "cd",
    "in",
    "sn",
    "sb",
    "te",
    "i",
    "xe",
    "cs",
    "ba",
    "la",
    "ce",
    "pr",
    "nd",
    "pm",
    "sm",
    "eu",
    "gd",
    "tb",
    "dy",
    "ho",
    "er",
    "tm",
    "yb",
    "lu",
    "hf",
    "ta",
    "w",
    "re",
    "os",
    "ir",
    "pt",
    "au",
    "hg",
    "tl",
    "pb",
    "bi",
    "po",
    "at",
    "rn",
    "fr",
    "ra",
    "ac",
    "th",
    "pa",
    "u",
    "np",
    "pu",
)
const PERIODIC_TABLE = raw"""
H                                                  He
Li Be                               B  C  N  O  F  Ne
Na Mg                               Al Si P  S  Cl Ar
K  Ca Sc Ti V  Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr
Rb Sr Y  Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I  Xe
Cs Ba    Hf Ta W  Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn
Fr Ra
      La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu
      Ac Th Pa U  Np Pu
"""

"""
    list_elements(pt=true)

List all elements that has pseudopotentials available in `PSlibrary`. Print the periodic table if `pt` is `true`.
"""
function list_elements(pt = true)
    if pt
        println(PERIODIC_TABLE)
    end
    return loaddb()
end

"""
    list_potentials(element::Union{AbstractString,AbstractChar,Integer})

List all pseudopotentials in `PSlibrary` for a specific element (abbreviation or index).
"""
function list_potentials(element::Union{AbstractString,AbstractChar})
    element = lowercase(string(element))
    @assert element in ELEMENTS "element $element is not recognized!"
    return loaddb(element)
end
function list_potentials(atomic_number::Integer)
    @assert 1 <= atomic_number <= 94
    element = ELEMENTS[atomic_number]
    return list_potentials(element)
end

"""
    download_potential(element::Union{AbstractString,AbstractChar,Integer})

Download one or multiple pseudopotentials from `PSlibrary` for a specific element.
"""
function download_potentials(element)
    df = list_potentials(element)
    display(df)
    paths, finished = String[], false
    while !finished
        printstyled("Enter its index (integer) to download a potential: "; color = :green)
        i = parse(Int, readline())
        printstyled(
            "Enter the file path to save the potential (press enter to skip): ";
            color = :green,
        )
        str = readline()
        path = abspath(expanduser(isempty(str) ? tempname() : strip(str)))  # `abspath` is necessary since the path will depend on where you run it
        download(df.src[i], path)
        push!(paths, path)
        finished = request("Finished?", RadioMenu(["yes", "no"])) == 1
    end
    return paths
end

function potential_exists(name::AbstractString)
    x = parse(UPFFile, name)
    db = list_potentials(x.element)
    return name in db.name
end

function download_potential(name::AbstractString, path)
    x = parse(UPFFile, name)
    df = list_potentials(x.element)
    if name in df.name
        i = findfirst(==(name), df.name)
        return download(df.src[i], path)
    else
        throw("potential '$name' is not in the database!")
    end
end

function loaddb(element::AbstractString)
    artifact_path = joinpath(@artifact_str(element), "$element.jld2")
    return load(artifact_path)["database"]
end
loaddb(i::Integer) = loaddb(ELEMENTS[i])
function loaddb()
    artifact_path = joinpath(artifact"all", "all.jld2")
    return load(artifact_path)["database"]
end

end
