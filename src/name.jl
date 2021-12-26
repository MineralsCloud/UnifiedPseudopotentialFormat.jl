using AcuteML: UN
using Parameters: @with_kw
using Pseudopotentials: CoreHoleEffect, ExchangeCorrelationFunctional, CoreValenceInteraction, Pseudization

@with_kw mutable struct PseudopotentialName
    element::String
    fullrelativistic::Bool
    corehole::UN{CoreHoleEffect} = nothing
    functional::ExchangeCorrelationFunctional
    corevalence::UN{Vector{<:CoreValenceInteraction}} = nothing
    pseudization::Pseudization
    free::String = ""
end
