export save
using ProtoBuf: ProtoEncoder, encode

"""
    save(filename::AbstractString, model::ModelProto)
    save(io::IO, model::ModelProto)
    save(model::ModelProto)

Save a `ModelProto` into an ONNX file. The file can be specified by a
filename or an open stream. If the file argument is omitted, it is
returned in memory as a `Vector{UInt8}`.
"""
save(io::IO, model::ModelProto) = encode(ProtoEncoder(io), model)

function save(filename::AbstractString, model::ModelProto)
    open(filename, "w") do io
        save(io, model)
    end
end

function save(model::ModelProto)
    buffer = IOBuffer()
    save(buffer, model)
    return take!(buffer)
end
