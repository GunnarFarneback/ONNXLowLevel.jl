module ONNXLowLevel

# See `../proto/README.md` for information about `../proto/onnx3_pb.jl`.
include("../proto/onnx3_pb.jl")
include("proto_docstrings.jl")
include("load.jl")
include("save.jl")
include("show.jl")
include("read.jl")
include("write.jl")

# This is a placeholder for functionality loaded from `../ext/REPLExt.jl`
# in interactive sessions (or always, for Julia < 1.11).
function explore end
macro explore end
export explore, @explore

end # module ONNXLowLevel
