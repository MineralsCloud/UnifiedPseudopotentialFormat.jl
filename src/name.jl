using AcuteML: UN
using MLStyle: @match
using Parameters: @with_kw
using Pseudopotentials:
    CoreHole,
    ExchangeCorrelationFunctional,
    ValenceCoreState,
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
    SemicoreState,
    CoreState,
    NonLinearCoreCorrection

export UPFFileName

const PSEUDOPOTENTIAL_NAME =
    r"(?:(rel)-)?([^-]*-)?(?:(pz|vwn|pbe|pbesol|blyp|pw91|tpss|coulomb)-)(?:([spdfn]*)l?-)?(ae|mt|bhs|vbc|van|rrkjus|rrkj|kjpaw|bpaw)(?:_(.*))?"i  # spdfnl?

mutable struct UPFFileName
    element::String
    fullrelativistic::Bool
    corehole::UN{CoreHole}
    xc::ExchangeCorrelationFunctional
    valencecore::UN{Vector{<:ValenceCoreState}}
    pseudization::Pseudization
    free::String
end
UPFFileName(;
    element,
    fullrelativistic = false,
    corehole = nothing,
    xc,
    valencecore = nothing,
    pseudization,
    free = "",
) = UPFFileName(element, fullrelativistic, corehole, xc, valencecore, pseudization, free)

function Base.parse(::Type{UPFFileName}, name)
    prefix, extension = splitext(name)
    @assert uppercase(extension) == ".UPF"
    data = split(prefix, '.'; limit = 2)
    if length(data) == 2
        element, description = data
        m = match(PSEUDOPOTENTIAL_NAME, description)
        if m !== nothing
            fullrelativistic = m[1] !== nothing ? true : false
            corehole = m[2] !== nothing ? nothing : nothing
            xc = @match m[3] begin
                "pz" => PerdewZunger()
                "vwn" => VoskoWilkNusair()
                "pbe" => PerdewBurkeErnzerhof()
                "pbesol" => PerdewBurkeErnzerhofRevisedForSolids()
                "blyp" => BeckeLeeYangParr()
                "pw91" => PerdewWang91()
                "tpss" => TaoPerdewStaroverovScuseria()
                "coulomb" => Coulomb()
            end
            valencecore = if m[4] !== nothing
                map(collect(m[4])) do c
                    @match c begin
                        's' || 'p' || 'd' => SemicoreState(c)
                        'f' => CoreState('f')
                        'n' => NonLinearCoreCorrection()
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
        return UPFFileName(
            element,
            fullrelativistic,
            corehole,
            xc,
            valencecore,
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

function Base.string(x::UPFFileName)
    arr = String[]
    if x.fullrelativistic
        push!(arr, "rel")
    end
    if x.corehole !== nothing
        push!(arr, string(x.corehole))
    end
    push!(arr, @match x.xc begin
        ::PerdewZunger => "pz"
        ::VoskoWilkNusair => "vwn"
        ::PerdewBurkeErnzerhof => "pbe"
        ::PerdewBurkeErnzerhofRevisedForSolids => "pbesol"
        ::BeckeLeeYangParr => "blyp"
        ::PerdewWang91 => "pw91"
        ::TaoPerdewStaroverovScuseria => "tpss"
        ::Coulomb => "coulomb"
    end)
    if x.valencecore !== nothing
        push!(arr, join(map(x.valencecore) do c
            @match c begin
                c::Union{SemicoreState,CoreState} => string(c.orbital)
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
