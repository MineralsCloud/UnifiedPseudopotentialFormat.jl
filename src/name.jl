using AcuteML: UN
using MLStyle: @match
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

struct UPFFileName
    name::String
end

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
                ArgumentError(
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
            ArgumentError(
                "parsing failed! The file name `$name` does not follow QE's naming convention!",
            ),
        )
    end
end
