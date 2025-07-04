using StatsBase 

abstract type Option end 

@enum Judgment impossible possible necessary mode1 mode2 mode3

struct Apparatus
    options::Vector{<:Option}
    id::Int
end

struct Task 
    name::String
    apparatuses::Vector{Apparatus}
    visible::Bool
end

Result = Dict{Int, Dict{Option, Judgment}}
Dist = Vector{Tuple{Result, Float64}}

@enum Color red blue green yellow pink black purple orange white
@enum Direction left center right

struct Cup <: Option 
    color::Color
    disabled::Bool
    shown_empty::Bool
    id::Int
end

struct Path <: Option
    direction::Direction 
    disabled::Bool
    id::Int
end

struct Gumball <: Option 
    color::Color
    disabled::Bool
    id::Int
end

struct Arm <: Option 
    direction::Direction
    disabled::Bool
    id::Int
end

struct ColoredPath <: Option 
    color::Color
    direction::Direction 
    disabled::Bool
    id::Int
end

global apparatus_counter = 0
global id_counter = 0

function increment_apparatus_id()
    global apparatus_counter += 1
    apparatus_counter
end

function increment_id()
    global id_counter += 1
    id_counter
end

Apparatus(options::Vector{<:Option}) = Apparatus(options, increment_apparatus_id())
Cup(color::Color, disabled::Bool=false, shown_empty::Bool=false) = Cup(color, disabled, shown_empty, increment_id())
Path(direction::Direction, disabled::Bool=false) = Path(direction, disabled, increment_id())
Gumball(color::Color, disabled::Bool=false) = Gumball(color, disabled, increment_id())
Arm(direction::Direction, disabled::Bool=false) = Arm(direction, disabled, increment_id())
Base.string(x::Union{Apparatus, <:Option}) = "$(join(split(repr(x), ",")[1:end-1], ",")))"

mutable struct Function 
    name::String
    arg_names::Vector{String}
    arg_types::Vector{DataType}
    definition::String
end