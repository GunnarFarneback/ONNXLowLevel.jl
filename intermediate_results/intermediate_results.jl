import ONNXLowLevel as ONNX
import ONNXRunTime
using ProtoBuf: OneOf

function intermediate_result(filename, output_name, num_dims, elem_type, inputs)
    onnx = ONNX.load(filename)

    dim = ONNX.var"TensorShapeProto.Dimension"[]
    for i in 1:num_dims
        axis = string(i)
        value = OneOf(:dim_param, "intermediate_$(axis)")
        push!(dim, ONNX.var"TensorShapeProto.Dimension"(; value))
    end
    shape = ONNX.TensorShapeProto(; dim)
    t = ONNX.var"TypeProto.Tensor"(elem_type, shape)
    type = ONNX.TypeProto(value = OneOf(:tensor_type, t))
    value_info = ONNX.ValueInfoProto(; name = output_name, var"#type" = type)
    
    push!(onnx.graph.output, value_info)

    onnx_filename, io = mktemp()
    ONNX.save(io, onnx)
    close(io)
    ort = ONNXRunTime.load_inference(onnx_filename)
    input_dict = Dict(name => input
                      for (name, input) in zip(ONNXRunTime.input_names(ort), inputs))
    output_dict = ort(input_dict)

    return output_dict[output_name]
end

function ort_inference(filename, inputs)
    ort = ONNXRunTime.load_inference(filename)
    input_dict = Dict(name => input
                      for (name, input) in zip(ONNXRunTime.input_names(ort), inputs))
    output_dict = ort(input_dict)

    return only(values(output_dict))
end

struct OrtPredictor
    ort
    OrtPredictor(filename::AbstractString, ep=:cpu) = new(ONNXRunTime.load_inference(filename, execution_provider = ep))
end

function (x::OrtPredictor)(inputs)
    input_dict = Dict(name => input
                      for (name, input) in zip(ONNXRunTime.input_names(x.ort), inputs))
    output_dict = x.ort(input_dict)

    return first(values(output_dict))
end
