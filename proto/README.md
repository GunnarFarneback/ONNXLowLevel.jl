The `onnx.proto3` file is a verbatim copy of
https://github.com/onnx/onnx/blob/main/onnx/onnx.proto3 and licensed
under the Apache license used by the https://github.com/onnx/onnx
repository. The file `LICENSE` in this directory is a verbatim copy of
https://github.com/onnx/onnx/blob/main/LICENSE.

The file `onnx3_pb.jl` is generated from `onnx.proto3` and follows the
same license.

To regenerate `onnx3_pb.jl` after updating `onnx.proto3`, run the
following in julia with this directory as current directory:

    using Pkg
    Pkg.activate("..")
    using ProtoBuf
    protojl("onnx.proto3", ".", ".", add_kwarg_constructors = true)
    write("onnx3_pb.jl",
          replace(read("onnx/onnx3_pb.jl", String),
                  r"(original file: .*/onnx.proto3)" =>
                  "original file: ./onnx.proto3"))
    rm("onnx", recursive = true)
