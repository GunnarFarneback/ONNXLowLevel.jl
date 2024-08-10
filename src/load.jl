using ProtoBuf: ProtoDecoder, decode
export load

"""
    load(filename::AbstractString)
    load(io::IO)
    load(data::Vector{UInt8})

Load an ONNX file into a `ModelProto`. The file can be given by
filename, as an open stream, or in memory.
"""
load(io::IO) = decode(ProtoDecoder(io), ModelProto)
load(data::Vector{UInt8}) = load(IOBuffer(data))
load(filename::AbstractString) = open(load, filename, "r")
