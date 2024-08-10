using ONNXLowLevel: AttributeProto, GraphProto, ModelProto, NodeProto,
                    TensorProto, ValueInfoProto
import ONNXLowLevel as ONNX

input = [ValueInfoProto("input", Float32, ["batch", 3, "height", "width"])]
output = [ValueInfoProto("output", Float32, ["batch", 10, "height", "width"])]
initializer = [TensorProto("kernel", rand(Float32, 3, 3, 10, 3)),
               TensorProto("bias", rand(Float32, 10))]
node = [NodeProto(input = ["input", "kernel", "bias"],
                  output = ["intermediate"],
                  name = "conv",
                  op_type = "Conv",
                  attribute = [AttributeProto("pads", [1, 1, 1, 1])]),
        NodeProto(input = ["intermediate"],
                  output = ["output"],
                  name = "relu",
                  op_type = "Relu")]
graph = GraphProto(; name = "graph", node, initializer, input, output)
model = ModelProto(; ir_version = Int64(7),
                   opset_import = [ONNX.OperatorSetIdProto(version = 12)],
                   producer_name = "Test",
                   producer_version = "0.0.1",
                   graph)

mktempdir() do tmpdir
    onnx1 = joinpath(tmpdir, "test1.onnx")
    onnx2 = joinpath(tmpdir, "test2.onnx")
    ONNX.save(onnx1, model)
    open(onnx2, "w") do io
        ONNX.save(io, model)
    end
    model1 = ONNX.load(onnx1)
    model2 = open(onnx2, "r") do io
        ONNX.load(io)
    end
    model3 = ONNX.load(ONNX.save(model))
    @test proto_is_equal(model, model1)
    @test proto_is_equal(model, model2)
    @test proto_is_equal(model, model3)
end
