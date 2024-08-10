# Generate a variety of AttributeProto constructors of the form
#
#     AttributeProto(name, x; kwargs)
#
# where `x` can be a float, int, string, TensorProto, GraphProto,
# SparseTensorProto, or TypeProto. Additionally it can be a Vector of
# the aforementioned types, and also generalizes to subtypes of
# AbstractFloat, Integer, AbstractString, and AbstractVector.
#
# If you want to create an attribute with an array value, other than
# the Vectors listed above, you need to go via a TensorProto.
for (field, enum, type, convert_func) in
    [(:f, :FLOAT, Float32, nothing),
     (:f, :FLOAT, AbstractFloat, Float32),
     (:i, :INT, Int64, nothing),
     (:i, :INT, Integer, Int64),
     (:s, :STRING, AbstractString, Vector{UInt8}),
     (:t, :TENSOR, TensorProto, nothing),
     (:g, :GRAPH, GraphProto, nothing),
     (:sparse_tensor, :SPARSE_TENSOR, SparseTensorProto, nothing),
     (:tp, :TYPE_PROTO, TypeProto, nothing),
     (:floats, :FLOATS, Vector{Float32}, nothing),
     (:floats, :FLOATS, AbstractVector{<:AbstractFloat},
      Base.Fix1(convert, Vector{Float32})),
     (:ints, :INTS, Vector{Int64}, nothing),
     (:ints, :INTS, AbstractVector{<:Integer},
      Base.Fix1(convert, Vector{Int64})),
     (:strings, :STRINGS, AbstractVector{<:AbstractString},
      Base.Fix1(broadcast, Vector{UInt8})),
     (:tensors, :TENSORS, Vector{TensorProto}, nothing),
     (:tensors, :TENSORS, AbstractVector{TensorProto}, collect),
     (:graphs, :GRAPHS, Vector{<:GraphProto}, nothing),
     (:graphs, :GRAPHS, AbstractVector{<:GraphProto}, collect),
     (:sparse_tensors, :SPARSE_TENSORS, Vector{SparseTensorProto}, nothing),
     (:sparse_tensors, :SPARSE_TENSORS, AbstractVector{SparseTensorProto},
      collect),
     (:type_protos, :TYPE_PROTOS, Vector{TypeProto}, nothing),
     (:type_protos, :TYPE_PROTOS, AbstractVector{TypeProto}, collect)]

    e = getfield(var"AttributeProto.AttributeType", enum)
    if isnothing(convert_func)
        @eval AttributeProto(name, $(field)::$(type); kwargs...) =
            AttributeProto(; name,
                           var"#type" = $e,
                           $(field),
                           kwargs...)
    else
        @eval AttributeProto(name, $(field)::$(type); kwargs...) =
            AttributeProto(; name,
                           var"#type" = $e,
                           $(field) = $(convert_func)($(field)),
                           kwargs...)
    end
end

"""
    AttributeProto(name, value; kwargs...)
    AttributeProto(name => value; kwargs...)

Construct an AttributeProto with the given `name` and a `value`, which
can be a `Float64`, `Int64`, `String`, `TensorProto`, `GraphProto`,
`SparseTensorProto`, or `TypeProto`. Additionally it can be a `Vector`
of the aforementioned types, and also generalizes to all subtypes of
`AbstractFloat`, `Integer`, `AbstractString`, and `AbstractVector`.
Additional `AttributeProto` fields can be set with keyword arguments.

---
    AttributeProto.(dict::AbstractDict; kwargs...)

A `Dict` of name, value pairs can be converted to a
`Vector{AttributeProto}` by broadcasting the constructor.
"""
AttributeProto(p::Pair; kwargs...) = AttributeProto(first(p), last(p); kwargs...)

# Support `AttributeProto.(dict)`.
#
# Note: This might turn out to be a bad idea.
function Base.broadcasted(::Type{<:AttributeProto}, d::AbstractDict; kwargs...)
    return AttributeProto[AttributeProto(p; kwargs...) for p in d]
end

"""
    ValueInfoProto(name::AbstractString, type::DataType,
                   dims::Vector{<:Any}; kwargs...)

Construct a `ValueInfoProto` with the given `name` for a tensor. The
`type` can be `Int64`, `UInt64`, `Int32`, `UInt32`, `Int16`, `UInt16`,
`Int8`, `UInt8`, `Float64`, `Float32`, `Float16`, `ComplexF64`, or
`ComplexF32`. Each element of `dims` can be either an integer or a
string, where the former is the size of the dimension and the latter
is a symbolic name for the dimension, which can be set dynamically.
Additional `ValueInfoProto` fields can be set with keyword arguments.
"""
function ValueInfoProto(name::AbstractString, type::DataType,
                        dims::Vector{<:Any}; kwargs...)
    shape = TensorShapeProto(; dim = var"TensorShapeProto.Dimension".(dims))
    element_type = tensorproto_data_type(type)
    t = var"TypeProto.Tensor"(Int32(element_type), shape)
    var"#type" = TypeProto(value = OneOf(:tensor_type, t))
    return ValueInfoProto(; name, var"#type", kwargs...)
end

var"TensorShapeProto.Dimension"(x::Integer) =
    var"TensorShapeProto.Dimension"(value = OneOf(:dim_value, Int64(x)))

var"TensorShapeProto.Dimension"(x::AbstractString) =
    var"TensorShapeProto.Dimension"(value = OneOf(:dim_param, string(x)))

tensorproto_data_type(::Type{Float32}) = var"TensorProto.DataType".FLOAT
tensorproto_data_type(::Type{UInt8}) = var"TensorProto.DataType".UINT8
tensorproto_data_type(::Type{Int8}) = var"TensorProto.DataType".INT8
tensorproto_data_type(::Type{UInt16}) = var"TensorProto.DataType".UINT16
tensorproto_data_type(::Type{Int16}) = var"TensorProto.DataType".INT16
tensorproto_data_type(::Type{Int32}) = var"TensorProto.DataType".INT32
tensorproto_data_type(::Type{Int64}) = var"TensorProto.DataType".INT64
tensorproto_data_type(::Type{String}) = var"TensorProto.DataType".STRING
tensorproto_data_type(::Type{Bool}) = var"TensorProto.DataType".BOOL
tensorproto_data_type(::Type{Float16}) = var"TensorProto.DataType".FLOAT16
tensorproto_data_type(::Type{Float64}) = var"TensorProto.DataType".DOUBLE
tensorproto_data_type(::Type{UInt32}) = var"TensorProto.DataType".UINT32
tensorproto_data_type(::Type{UInt64}) = var"TensorProto.DataType".UINT64
tensorproto_data_type(::Type{ComplexF32}) = var"TensorProto.DataType".COMPLEX64
tensorproto_data_type(::Type{ComplexF64}) = var"TensorProto.DataType".COMPLEX128
# TODO: Add BFloat16 in an extension for the BFloat16s package.
# TODO: Add some kind of support for the exotic 8 bit float formats
#       and 4 bit integers.

"""
    TensorProto(name::AbstractString, x::AbstractArray; kwargs...)

Create a `TensorProto` with the given `name` from an array `x`. The
array can have any shape and an element type of either `Int64`,
`UInt64`, `Int32`, `UInt32`, `Int16`, `UInt16`, `Int8`, `UInt8`,
`Float64`, `Float32`, `Float16`, `ComplexF64`, `ComplexF32`, `Bool`,
or `String`. Additional `TensorProto` fields can be set with keyword
arguments.

    TensorProto(x::AbstractArray; kwargs...)

Like above but `name` is set to the empty string.
"""
function TensorProto(name::AbstractString, x::Array; kwargs...)
    return TensorProto(; name,
                       dims = collect(reverse(size(x))),
                       data_type = Int32(tensorproto_data_type(eltype(x))),
                       raw_data = reinterpret(UInt8, vec(x)),
                       kwargs...)
end

function TensorProto(name::AbstractString, x::AbstractArray; kwargs...)
    return TensorProto(name, Array(x); kwargs...)
end

function TensorProto(name::AbstractString, x::Array{String}; kwargs...)
    return TensorProto(; name,
                       dims = collect(reverse(size(x))),
                       data_type = Int32(var"TensorProto.DataType".STRING),
                       string_data = codeunits.(vec(x)),
                       kwargs...)
end

function TensorProto(name::AbstractString, x::AbstractArray{<:AbstractString};
                     kwargs...) 
    return TensorProto(name, String.(x), kwargs...)
end

TensorProto(x::AbstractArray; kwargs...) = TensorProto("", x; kwargs...)
