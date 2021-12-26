module PSlibrary

using DataFrames: DataFrame, groupby
using AcuteML: UN, parsehtml, root, nextelement, nodecontent
using MLStyle: @match
using Pseudopotentials:
    CoreHoleEffect,
    ExchangeCorrelationFunctional,
    CoreValenceInteraction,
    Pseudization,
    PerdewZunger,
    VoskoWilkNusair,
    PerdewBurkeErnzerhof,
    PerdewBurkeErnzerhofRevisedForSolids,
    BeckeLeeYangParr,
    PerdewWang91,
    TaoPerdewStaroverovScuseria,
    Coulomb,
    KresseJoubert,
    Blöchl,
    TroullierMartins,
    BacheletHamannSchlüter,
    VonBarthCar,
    Vanderbilt,
    AllElectron,
    RappeRabeKaxirasJoannopoulos,
    RappeRabeKaxirasJoannopoulosUltrasoft,
    SemicoreValence,
    CoreValence,
    NonLinearCoreCorrection,
    LinearCoreCorrection
using REPL.TerminalMenus: RadioMenu, request

using ..UnifiedPseudopotentialFormat: PseudopotentialName

export list_elements, list_potentials, download_potentials

const LIBRARY_ROOT = "https://www.quantum-espresso.org/pseudopotentials/ps-library/"
const UPF_ROOT = "https://www.quantum-espresso.org"
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
const DATABASE = DataFrame(
    element = [],
    fullrelativistic = Bool[],
    corehole = UN{CoreHoleEffect}[],
    functional = UN{ExchangeCorrelationFunctional}[],
    corevalence = UN{Vector{<:CoreValenceInteraction}}[],
    pseudization = UN{Pseudization}[],
    free = String[],
    src = String[],
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
const PSEUDOPOTENTIAL_NAME =
    r"(?:(rel)-)?([^-]*-)?(?:(pz|vwn|pbe|pbesol|blyp|pw91|tpss|coulomb)-)(?:([spdfnl]*)-)?(ae|mt|bhs|vbc|van|rrkjus|rrkj|kjpaw|bpaw)(?:_(.*))?"i  # spdfnl?

function Base.parse(::Type{PseudopotentialName}, name)
    prefix, extension = splitext(name)
    @assert uppercase(extension) == ".UPF"
    data = split(prefix, '.'; limit = 2)
    if length(data) == 2
        element, description = data
        m = match(PSEUDOPOTENTIAL_NAME, description)
        if m !== nothing
            fullrelativistic = m[1] !== nothing ? true : false
            corehole = m[2] !== nothing ? nothing : nothing
            functional = @match m[3] begin
                "pz" => PerdewZunger()
                "vwn" => VoskoWilkNusair()
                "pbe" => PerdewBurkeErnzerhof()
                "pbesol" => PerdewBurkeErnzerhofRevisedForSolids()
                "blyp" => BeckeLeeYangParr()
                "pw91" => PerdewWang91()
                "tpss" => TaoPerdewStaroverovScuseria()
                "coulomb" => Coulomb()
            end
            corevalence = if m[4] !== nothing
                map(collect(m[4])) do c
                    @match c begin
                        's' || 'p' || 'd' => SemicoreValence(c)
                        'f' => CoreValence('f')
                        'n' => NonLinearCoreCorrection()
                        'l' => LinearCoreCorrection()
                    end
                end
            end
            pseudization = @match m[5] begin
                "ae" => AllElectron()
                "mt" => TroullierMartins()
                "bhs" => BacheletHamannSchlüter()
                "vbc" => VonBarthCar()
                "van" => Vanderbilt()
                "rrkj" => RappeRabeKaxirasJoannopoulos()
                "rrkjus" => RappeRabeKaxirasJoannopoulosUltrasoft()
                "kjpaw" => KresseJoubert()
                "bpaw" => Blöchl()
            end
            free = m[6]
        else
            throw(
                Meta.ParseError(
                    "parsing failed! The file name `$name` does not follow QE's naming convention!",
                ),
            )
        end
        return PseudopotentialName(
            element,
            fullrelativistic,
            corehole,
            functional,
            corevalence,
            pseudization,
            free,
        )
    else
        throw(
            Meta.ParseError(
                "parsing failed! The file name `$name` does not follow QE's naming convention!",
            ),
        )
    end
end

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

"""
    list_elements(pt=true)

List all elements that has pseudopotentials available in `PSlibrary`. Print the periodic table if `pt` is `true`.
"""
function list_elements(pt = true)
    if pt
        println(PERIODIC_TABLE)
    end
    return groupby(unique!(DATABASE), :element)
end

"""
    list_potentials(element::Union{AbstractString,AbstractChar,Integer})

List all pseudopotentials in `PSlibrary` for a specific element (abbreviation or index).
"""
function list_potentials(element::Union{AbstractString,AbstractChar})
    element = lowercase(string(element))
    @assert element in ELEMENTS "element $element is not recognized!"
    for meta in _parsehtml(element)
        parsed = parse(PseudopotentialName, meta.name)
        push!(DATABASE, [fieldvalues(parsed)..., meta.src])
    end
    return list_elements(false)[(uppercasefirst(element),)]
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

fieldvalues(x::PseudopotentialName) = (getfield(x, i) for i in 1:nfields(x))

function Base.string(x::PseudopotentialName)
    arr = String[]
    if x.fullrelativistic
        push!(arr, "rel")
    end
    if x.corehole !== nothing
        push!(arr, string(x.corehole))
    end
    push!(arr, @match x.functional begin
        ::PerdewZunger => "pz"
        ::VoskoWilkNusair => "vwn"
        ::PerdewBurkeErnzerhof => "pbe"
        ::PerdewBurkeErnzerhofRevisedForSolids => "pbesol"
        ::BeckeLeeYangParr => "blyp"
        ::PerdewWang91 => "pw91"
        ::TaoPerdewStaroverovScuseria => "tpss"
        ::Coulomb => "coulomb"
    end)
    if x.corevalence !== nothing
        push!(arr, join(map(x.corevalence) do c
            @match c begin
                c::Union{SemicoreValence,CoreValence} => string(c.orbital)
                ::NonLinearCoreCorrection => 'n'
            end
        end))
    end
    push!(arr, @match x.pseudization begin
        ::TroullierMartins => "mt"
        ::BacheletHamannSchlüter => "bhs"
        ::VonBarthCar => "vbc"
        ::Vanderbilt => "van"
        ::RappeRabeKaxirasJoannopoulos => "rrkj"
        ::RappeRabeKaxirasJoannopoulosUltrasoft => "rrkjus"
        ::KresseJoubert => "kjpaw"
        ::Blöchl => "bpaw"
        ::AllElectron => "ae"
    end)
    prefix = x.element * '.' * join(arr, '-') * '_' * x.free
    return prefix * ".UPF"
end

end