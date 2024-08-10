using ProtoBuf: encode, ProtoEncoder
using protoc_jll: protoc

function protoc_decode(proto)
    path, io = mktemp()
    encode(ProtoEncoder(io), proto)
    close(io)
    proto_type = typeof(proto).name.name
    proto_dir = joinpath(dirname(@__DIR__), "proto")
    args = ["--decode=onnx.$(string(proto_type))",
            "-I$(proto_dir)",
            "onnx.proto3"]
    return replace(read(pipeline(path, `$(protoc()) $args`), String),
                   "\r\n" => "\n")
end

function proto_is_equal(x, y)
    typeof(x) == typeof(y) || return false
    if isstructtype(typeof(x))
        return all(proto_is_equal(getfield(x, field), getfield(y, field))
                   for field in fieldnames(typeof(x)))
    elseif x isa Vector
        size(x) == size(y) || return false
        return all(proto_is_equal.(x, y))
    end
    return x == y
end
