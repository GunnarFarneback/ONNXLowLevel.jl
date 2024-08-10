export get_attribute, get_attributes, get_value_info, get_tensor

"""
    get_attribute(attribute::AttributeProto)

Create a `Pair` of `name => value` from an `AttributeProto`.
"""
function get_attribute(attribute::AttributeProto)
    type = Int(attribute.var"#type")
    if (type != 0)
        field = [:f, :i, :s, :t, :g, :floats, :ints, :strings, :tensors,
                 :graphs, :sparse_tensor, :sparse_tensors,
                 :tp, :type_protos][type]
        if field === :s
            return attribute.name => String(copy(getfield(attribute, field)))
        elseif field === :strings
            return attribute.name => String.(copy.(getfield(attribute, field)))
        end
        return attribute.name => getfield(attribute, field)
    end
    return attribute.name => nothing
end

"""
    get_attributes(attributes::Vector{<:AttributeProto})
    get_attributes(attributes::Vector{<:AttributeProto}; dicttype)

Create a `Dict` of `name => value` pairs from a vector of
`AttributeProto`. By default a `Dict{String, Any}` is returned. This
can be customized with the `dicttype` keyword argument.
"""
function get_attributes(attributes::Vector{<:AttributeProto};
                        dicttype = Dict{String, Any})
    return dicttype(get_attribute(attribute) for attribute in attributes)
end

"""
    name, type, dims = get_value_info(value_info::ValueInfoProto;
                                      params_as_zero = false)

Extract `name`, `type`, and `dims` from a `ValueInfoProto`. If
`params_as_zero` is `true`, return `dims` as an all integer vector,
where dynamic dimensions are set to zero.
"""
function get_value_info(value_info::ValueInfoProto; params_as_zero = false)
    t = value_info.var"#type".value
    if t.name !== :tensor_type
        error("get_value_info only supports tensors.")
    end
    type = tensorproto_julia_type(t.value.elem_type)
    s = t.value.shape
    dims = Union{String, Int}[d.value.value for d in s.dim]
    if params_as_zero
        dims = Int[(d isa String) ? 0 : d for d in dims]
    end
    return value_info.name, type, dims
end

tensorproto_julia_type(t::Integer) =
    tensorproto_julia_type(var"TensorProto.DataType".T(t))
tensorproto_julia_type(t::var"TensorProto.DataType".T) =
    tensorproto_julia_type(Val(t))
tensorproto_julia_type(::Val{var"TensorProto.DataType".FLOAT}) = Float32
tensorproto_julia_type(::Val{var"TensorProto.DataType".UINT8}) = UInt8
tensorproto_julia_type(::Val{var"TensorProto.DataType".INT8}) = Int8
tensorproto_julia_type(::Val{var"TensorProto.DataType".UINT16}) = UInt16
tensorproto_julia_type(::Val{var"TensorProto.DataType".INT16}) = Int16
tensorproto_julia_type(::Val{var"TensorProto.DataType".INT32}) = Int32
tensorproto_julia_type(::Val{var"TensorProto.DataType".INT64}) = Int64
tensorproto_julia_type(::Val{var"TensorProto.DataType".STRING}) = String
tensorproto_julia_type(::Val{var"TensorProto.DataType".BOOL}) = Bool
tensorproto_julia_type(::Val{var"TensorProto.DataType".FLOAT16}) = Float16
tensorproto_julia_type(::Val{var"TensorProto.DataType".DOUBLE}) = Float64
tensorproto_julia_type(::Val{var"TensorProto.DataType".UINT32}) = UInt32
tensorproto_julia_type(::Val{var"TensorProto.DataType".UINT64}) = UInt64
tensorproto_julia_type(::Val{var"TensorProto.DataType".COMPLEX64}) = ComplexF32
tensorproto_julia_type(::Val{var"TensorProto.DataType".COMPLEX128}) = ComplexF64

tensorproto_data_field(::Val{var"TensorProto.DataType".FLOAT}) = :float_data
tensorproto_data_field(::Val{var"TensorProto.DataType".UINT8}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".INT8}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".UINT16}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".INT16}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".INT32}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".INT64}) = :int64_data
tensorproto_data_field(::Val{var"TensorProto.DataType".STRING}) = :string_data
tensorproto_data_field(::Val{var"TensorProto.DataType".BOOL}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".FLOAT16}) = :int32_data
tensorproto_data_field(::Val{var"TensorProto.DataType".DOUBLE}) = :double_data
tensorproto_data_field(::Val{var"TensorProto.DataType".UINT32}) = :uint64_data
tensorproto_data_field(::Val{var"TensorProto.DataType".UINT64}) = :uint64_data
tensorproto_data_field(::Val{var"TensorProto.DataType".COMPLEX64}) = :float_data
tensorproto_data_field(::Val{var"TensorProto.DataType".COMPLEX128}) = :double_data

"""
    get_tensor(tensor::TensorProto)

Convert a `TensorProto` to a Julia `Array`. The conversion does not
change the data but emulates row-major storage by reversing the tensor
dimensions.
"""
function get_tensor(tensor::TensorProto)
    isnothing(tensor.segment) || error("get_tensor does not support segmented tensors.")
    if tensor.data_location != var"TensorProto.DataLocation".DEFAULT
        error("get_tensor does not support external data location.")
    end
    type = var"TensorProto.DataType".T(tensor.data_type)
    T = tensorproto_julia_type(type)
    field = tensorproto_data_field(Val(type))
    typed_data = getfield(tensor, field)
    if field === :string_data
        data = String.(copy.(typed_data))
    elseif !isempty(typed_data)
        if T <: Complex
            data = reinterpret(T, typed_data)
        elseif T <: Integer
            data = typed_data .% T
        else
            data = reinterpret(T, typed_data .& ((1 << 8 * sizeof(T)) - 1))
        end
    else
        data = reinterpret(T, tensor.raw_data)
    end
    return reshape(data, reverse(tensor.dims)...)
end
