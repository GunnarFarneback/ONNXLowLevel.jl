# ONNXLowLevel

Low level support for ONNX files. This package is useful if you want
to investigate ONNX files in detail or create new tools to read or
write ONNX files. It is not useful if you just want to load an ONNX
file into your favorite machine learning library or run inference. For
the former, search for ONNX loading support in the library. For the
latter you can use
[ONNXRunTime.jl](https://github.com/jw3126/ONNXRunTime.jl).

## Comparison to ONNX.jl

The [ONNX.jl](https://github.com/FluxML/ONNX.jl) package has roughly
the same purpose as this package. The fundamental difference is that
ONNXLowLevel has no dependencies apart from ProtoBuf whereas ONNX
supports saving and loading graphs with a tape representation and can
run inference on some of the ONNX operations.

Both packages export the ProtoBuf generated structs but differ
slightly in their additional convenience constructors and functions.

## Installation

```
using Pkg
Pkg.add("ONNXLowLevel")
```

## Usage

The ONNX format is defined by the [onnx.proto3](proto/onnx.proto3)
file, which defines ProtoBuf messages and their meanings. These are
automatically converted into structs, and an ONNX file corresponds to
nested structs with a `ModelProto` at the top.

### Loading and Saving

An ONNX file can be loaded into a `ModelProto` with either of these
methods:

    load(filename::AbstractString)
    load(io::IO)
    load(data::Vector{UInt8})

Correspondingly a `ModelProto` can be saved with

    save(filename::AbstractString, model::ModelProto)
    save(io::IO, model::ModelProto)
    save(model::ModelProto)

### Exploring an ONNX File

The contents of an ONNX file or a `ModelProto` can be interactively
explored with a text user interface tool:

    @explore filename
    @explore model

### Default ONNX Struct Constructors

All ONNX structs, such as `ModelProto`, have keyword argument
constructors, where omitted fields are set to empty or neutral values.
The struct docstring lists all fields, which can also be found in
`onnx.proto3`.

Some structs and fields have names which do not match Julia's naming
rules. Those can be accessed with the `var"X"` syntax, such as
`var"TensorShapeProto.Dimension"` or `value_info.var"#type"`.

### Convenience Constructors and Accessors

Some of the frequently used and complicated to construct ONNX structs
have additional convenience constructors and accessors to convert them
back to common Julia types.

#### `AttributeProto`

    AttributeProto(name, value)
    AttributeProto(name => value)

Construct an AttributeProto with the given `name` and a `value`, which
can be a `Float64`, `Int64`, `String`, `TensorProto`, `GraphProto`,
`SparseTensorProto`, or `TypeProto`. Additionally it can be a `Vector`
of the aforementioned types, and also generalizes to all subtypes of
`AbstractFloat`, `Integer`, `AbstractString`, and `AbstractVector`.

    AttributeProto.(dict::AbstractDict)

A `Dict` of name, value pairs can be converted to a
`Vector{AttributeProto}` by broadcasting the constructor.

    get_attribute(attribute::AttributeProto)

Convert an `AttributeProto` to a `Pair` of `name => value`.

    get_attributes(attributes::Vector{<:AttributeProto})

Convert a `Vector` of `AttributeProto` to a `Dict`.

    get_attributes(attributes::Vector{<:AttributeProto}; dicttype)

Convert a `Vector` of `AttributeProto` to a dictionary of specific
`dicttype`.

#### `ValueInfoProto`

    ValueInfoProto(name::AbstractString, type::DataType,
                   dims::Vector{<:Any})

Construct a `ValueInfoProto` with the given `name` for a tensor. The
`type` can be `Int64`, `UInt64`, `Int32`, `UInt32`, `Int16`, `UInt16`,
`Int8`, `UInt8`, `Float64`, `Float32`, `Float16`, `ComplexF64`, or
`ComplexF32`. Each element of `dims` can be either an integer or a
string, where the former is the size of the dimension and the latter
is a symbolic name for the dimension, which can be set dynamically.

See a later section for support of four bit integer, 8 bit float, and
bfloat16 types.

    name, type, dims = get_value_info(value_info::ValueInfoProto;
                                      params_as_zero = false)

Extract `name`, `type`, and `dims` from a `ValueInfoProto`. If
`params_as_zero` is `true`, return `dims` as an all integer vector
where dynamic dimensions are set to zero.

#### TensorProto

ONNX tensors are stored in row-major format, which is contrary to
Julia's native column-major. This means that conversion between a
Julia `Array` and an ONNX `TensorProto` either needs to reverse the
dimensions or transpose the data. ONNXLowLevel chooses the former
option since transposing the data is relatively expensive and it is
easy to convert to the latter option with `permutedims(x,
ndims(x):-1:1)`.

    TensorProto(name::AbstractString, x::AbstractArray)

Create a `TensorProto` with the given `name`. The data `x` can have
any shape and an element type of either `Int64`, `UInt64`, `Int32`,
`UInt32`, `Int16`, `UInt16`, `Int8`, `UInt8`, `Float64`, `Float32`,
`Float16`, `ComplexF64`, `ComplexF32`, `Bool`, or `String`.

See a later section for support of four bit integer, 8 bit float, and
bfloat16 element types.

    TensorProto(x::AbstractArray)

Like above but `name` is set to the empty string.

    get_tensor(tensor::TensorProto)

Convert a `TensorProto` to a Julia `Array`.

### Support of Exotic ONNX Data Types

The ONNX format includes a number of data types which are not natively
supported by Julia: `BFLOAT16`, `FLOAT8E4M3FN`, `FLOAT8E4M3FNUZ`,
`FLOAT8E5M2`, `FLOAT8E5M2FNUZ`, `INT4`, and `UINT4`.

Neither of these are currently supported by ONNXLowLevel. The plan is
to support `BFLOAT16` as an extension for the `BFloat16s` package. The
other data types may get minimal support within this package.
