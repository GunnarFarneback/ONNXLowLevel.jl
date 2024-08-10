function Base.show(io::IO, model::ModelProto)
    (; ir_version, opset_import, producer_name, producer_version, domain,
     model_version, doc_string, graph, metadata_props, training_info,
     functions) = model
    print(io, "ModelProto")
    ir_version_string = get(Base.Enums.namemap(Version.T), ir_version, "unknown")
    print(io, "\n  ir_version: $(ir_version) ($(ir_version_string))")
    print(io, "\n  opset_import: ", join(string.(opset_import), ", "))
    isempty(producer_name) || print(io, "\n  producer_name: $(producer_name)")
    isempty(producer_version) || print(io, "\n  producer_version: $(producer_version)")
    isempty(domain) || print(io, "\n  domain: $(domain)")
    print(io, "\n  model_version: $(model_version)")
    isempty(doc_string) || print(io, "\n  doc_string: $(doc_string)")
    isnothing(graph) || print(io, "\n  graph: $(graph.name)")
    isempty(metadata_props) || print(io, "\n  metadata_props: $(map_summary(metadata_props))")
    if !isempty(training_info)
        print(io, "\n  training_info: $(length(training_info)) training info$(plural(training_info))")
    end

    if !isempty(functions)
        print(io, "\n  function: $(length(functions)) function$(plural(functions))")
    end
end

function Base.show(io::IO, graph::GraphProto)
    (; node, name, initializer, sparse_initializer, doc_string, input, output,
     value_info, quantization_annotation, metadata_props) = graph
    print(io, "GraphProto")
    print(io, "\n  node: $(length(node)) node$(plural(node))")
    print(io, "\n  name: $(name)")
    if !isempty(initializer)
        print(io, "\n  initializer: $(length(initializer)) initializer$(plural(initializer))")
    end
    if !isempty(sparse_initializer)
        print(io, "\n  sparse_initializer: $(length(sparse_initializer)) sparse initializer$(plural(sparse_initializer))")
    end
    isempty(doc_string) || print(io, "\n  doc_string: $(doc_string)")
    print(io, "\n  input: $(length(input)) input$(plural(input))")
    print(io, "\n  output: $(length(output)) output$(plural(output))")
    isempty(value_info) || print(io, "\n  value_info: $(length(value_info)) value info$(plural(value_info))")
    isempty(quantization_annotation) || print(io, "\n  quantization_annotation: $(length(quantization_annotation)) annotation$(plural(quantization_annotation))")
    isempty(metadata_props) || print(io, "\n  metadata_props: $(map_summary(metadata_props))")    
end

function Base.show(io::IO, ::MIME"text/plain", node::NodeProto)
    (; input, output, name, op_type, domain, overload, attribute,
     doc_string, metadata_props) = node
    print(io, "NodeProto")
    isempty(name) || print(io, "\n  name: $(name)")
    print(io, "\n  op_type: $(op_type)")
    if !isempty(input) && sum(2 .+ length.(input)) <= 70
        print(io, "\n  input: ", join(input, ", "))
    else
        print(io, "\n  input: ", number_of(input, "input"))
    end
    if !isempty(output) && sum(2 .+ length.(output)) <= 70
        print(io, "\n  output: ", join(output, ", "))
    else
        print(io, "\n  output: ", number_of(output, "output"))
    end
    isempty(domain) || print(io, "\n  domain: $(domain)")
    isempty(overload) || print(io, "\n  overload: $(overload)")
    isempty(attribute) || print(io, "\n  attribute: ", number_of(attribute, "attribute"))
    isempty(doc_string) || print(io, "\n  doc_string: $(doc_string)")
    isempty(metadata_props) || print(io, "\n  metadata_props: ", map_summary(metadata_props))
end

function Base.show(io::IO, node::NodeProto)
    print(io, isempty(node.name) ? "<unnamed>" : node.name)
end

function Base.show(io::IO, ::MIME"text/plain", attribute::AttributeProto)
    (; name, ref_attr_name, doc_string, var"#type", f, i, s, t, g,
     sparse_tensor, tp, floats, ints, strings, tensors, graphs,
     sparse_tensors, type_protos) = attribute
    print(io, "AttributeProto")
    print(io, "\n  name: $(name)")
    isempty(ref_attr_name) || print(io, "\n  ref_attr_name: $(ref_attr_name)")
    isempty(doc_string) || print(io, "\n  doc_string: $(doc_string)")
    print(io, "\n  type: ", var"#type")
    type = string(var"#type")
    if type == "FLOAT"
        print(io, "\n  f: ", f)
    elseif type == "INT"
        print(io, "\n  i: ", i)
    elseif type == "STRING"
        print(io, "\n  s: ", s)
    elseif type == "TENSOR"
        if isnothing(t)
            print(io, "\n  t: nothing")
        else
            print(io, "\n  t: tensor")
        end
    elseif type == "GRAPH"
        if isnothing(g)
            print(io, "\n  g: nothing")
        else
            print(io, "\n  g: graph")
        end
    elseif type == "SPARSE_TENSOR"
        if isnothing(sparse_tensor)
            print(io, "\n  sparse_tensor: nothing")
        else
            print(io, "\n  sparse_tensor: sparse tensor")
        end
    elseif type == "TYPE_PROTO"
        print(io, "\n  tp: ", tp)
    elseif type == "FLOATS"
        print(io, "\n  floats: ", values_or_number_of(floats, "float"))
    elseif type == "INTS"
        print(io, "\n  ints: ", values_or_number_of(ints, "int"))
    elseif type == "STRINGS"
        print(io, "\n  strings: ", values_or_number_of(strings, "string"))
    elseif type == "TENSORS"
        print(io, "\n  tensors: ", number_of(tensors, "tensor"))
    elseif type == "GRAPHS"
        print(io, "\n  graphs: ", number_of(graphs, "graph"))
    elseif type == "SPARSE_TENSORS"
        print(io, "\n  sparse_tensors: ", number_of(sparse_tensors, "sparse tensor"))
    elseif type == "TYPE_PROTOS"
        print(io, "\n  type_protos: ", number_of(type_protos, "type proto"))
    end
end

function Base.show(io::IO, attribute::AttributeProto)
    (; name, ref_attr_name, doc_string, var"#type", f, i, s, t, g,
     sparse_tensor, tp, floats, ints, strings, tensors, graphs,
     sparse_tensors, type_protos) = attribute
    print(io, "$(name): ")
    type = string(var"#type")
    if type == "FLOAT"
        print(io, f)
    elseif type == "INT"
        print(io, i)
    elseif type == "STRING"
        print(io, s)
    elseif type == "TENSOR"
        if isnothing(t)
            print(io, "nothing")
        else
            print(io, "tensor")
        end
    elseif type == "GRAPH"
        if isnothing(g)
            print(io, "nothing")
        else
            print(io, "graph")
        end
    elseif type == "SPARSE_TENSOR"
        if isnothing(sparse_tensor)
            print(io, "nothing")
        else
            print(io, "sparse tensor")
        end
    elseif type == "TYPE_PROTO"
        print(io, tp)
    elseif type == "FLOATS"
        print(io, values_or_number_of(floats, "float"))
    elseif type == "INTS"
        print(io, values_or_number_of(ints, "int"))
    elseif type == "STRINGS"
        print(io, values_or_number_of(strings, "string"))
    elseif type == "TENSORS"
        print(io, number_of(tensors, "tensor"))
    elseif type == "GRAPHS"
        print(io, number_of(graphs, "graph"))
    elseif type == "SPARSE_TENSORS"
        print(io, number_of(sparse_tensors, "sparse tensor"))
    elseif type == "TYPE_PROTOS"
        print(io, number_of(type_protos, "type proto"))
    end
end

function Base.show(io::IO, ::MIME"text/plain", value_info::ValueInfoProto)
    (; name, doc_string, metadata_props) = value_info
    type = value_info.var"#type"
    print(io, "ValueInfoProto")
    isempty(name) || print(io, "\n  name: $(name)")
    isnothing(type) || print(io, "\n  type: $(type)")
    isempty(doc_string) || print(io, "\n  doc_string: $(doc_string)")
    isempty(metadata_props) || print(io, "\n  metadata_props: ", map_summary(metadata_props))
end

function Base.show(io::IO, value_info::ValueInfoProto)
    print(io, value_info.name)
end

function Base.show(io::IO, ::MIME"text/plain", type_proto::TypeProto)
    (; value, denotation) = type_proto
    print(io, "TypeProto")
    isnothing(value) || print(io, "\n  value: $(value.value)")
    isempty(denotation) || print(io, "\n  denotation: $(denotation)")
end

function Base.show(io::IO, type_proto::TypeProto)
    (; value, denotation) = type_proto
    isnothing(value) || print(io, value.value)
end

function Base.show(io::IO, ::MIME"text/plain", tensor::var"TypeProto.Tensor")
    (; elem_type, shape) = tensor
    print(io, "TypeProto.Tensor")
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "\n  elem_type: $(elem_type_name) ($(elem_type))")
    isnothing(shape) || print(io, "\n  shape: [", join(shape.dim, ", "), "]")
end

function Base.show(io::IO, tensor::var"TypeProto.Tensor")
    (; elem_type, shape) = tensor
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "tensor ", elem_type_name, "[", join(shape.dim, ", "), "]")
end

function Base.show(io::IO, ::MIME"text/plain",
                   sequence::var"TypeProto.Sequence")
    (; elem_type) = sequence
    print(io, "TypeProto.Sequence")
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "\n  elem_type: $(elem_type_name) ($(elem_type))")
end

function Base.show(io::IO, sequence::var"TypeProto.Sequence")
    (; elem_type) = sequence
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "sequence ", elem_type_name)
end

function Base.show(io::IO, ::MIME"text/plain", map::var"TypeProto.Map")
    (; key_type, value_type) = map
    print(io, "TypeProto.Map")
    key_type_name = tensorproto_datatype(key_type)
    value_type_name = tensorproto_datatype(value_type)
    print(io, "\n  key_type: $(key_type_name) ($(key_type))")
    print(io, "\n  value_type: $(value_type_name) ($(value_type))")
end

function Base.show(io::IO, map::var"TypeProto.Map")
    (; key_type, value_type) = map
    key_type_name = tensorproto_datatype(key_type)
    value_type_name = tensorproto_datatype(value_type)
    print(io, "map<$(elem_type_name), $(value_type_name)>")
end

function Base.show(io::IO, ::MIME"text/plain",
                   optional::var"TypeProto.Optional")
    (; elem_type) = optional
    print(io, "TypeProto.Optional")
    # Proto definition says:
    # // Possible values correspond to OptionalProto.DataType enum
    # but the definition of OptionalProto is in another Proto file.
    print(io, "\n  elem_type: $(elem_type)")
end

function Base.show(io::IO, optional::var"TypeProto.Optional")
    (; elem_type) = optional
    elem_type_name = optionalproto_datatype(elem_type)
    print(io, "optional ", elem_type_name)
end

function Base.show(io::IO, ::MIME"text/plain",
                   sparse_tensor::var"TypeProto.SparseTensor")
    (; elem_type, shape) = sparse_tensor
    print(io, "TypeProto.SparseTensor")
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "\n  elem_type: $(elem_type_name) ($(elem_type))")
    print(io, "\n  shape: [", join(shape.dim, ", "), "]")
end

function Base.show(io::IO, sparse_tensor::var"TypeProto.SparseTensor")
    (; elem_type, shape) = sparse_tensor
    elem_type_name = tensorproto_datatype(elem_type)
    print(io, "sparse tensor ", elem_type_name, "[", join(shape.dim, ", "), "]")
end

function Base.show(io::IO, tensor_shape::TensorShapeProto)
    dim = tensor_shape.dim
    print(io, "TensorShapeProto")
    for (i, dim) in enumerate(dim)
        print(io, "\n  dim[$i]: ", dim)
    end
end

function Base.show(io::IO, ::MIME"text/plain",
                   tensor_shape_dim::var"TensorShapeProto.Dimension")
    value = tensor_shape_dim.value
    denotation = tensor_shape_dim.denotation
    print(io, "TensorShapeProto.Dimension")
    isnothing(value) || isempty(value.value) || print(io, "\n  value: $(value.value)")
    isempty(denotation) || print(io, "\n  denotation: $(denotation)")
end

function Base.show(io::IO, tensor_shape_dim::var"TensorShapeProto.Dimension")
    print(io, tensor_shape_dim.value.value)
end


function Base.show(io::IO, ::MIME"text/plain", id::OperatorSetIdProto)
    print(io, "OperatorSetIdProto")
    isempty(id.domain) || print(io, "\n  domain: $(id.domain)")
    print(io, "\n  version: $(id.version)")
end

function Base.show(io::IO, id::OperatorSetIdProto)
    if isempty(id.domain)
        print(io, id.version)
    else
        print(io, "($(id.domain), $(id.version))")
    end
end

function Base.show(io::IO, ::MIME"text/plain", tensor::TensorProto)
    (; dims, data_type, segment, float_data, int32_data, string_data,
     int64_data, name, doc_string, raw_data, external_data,
     data_location, double_data, uint64_data, metadata_props) = tensor
    print(io, "TensorProto")
    isempty(name) || print(io, "\n  name: $name")
    data_type_name = tensorproto_datatype(data_type)
    print(io, "\n  data_type: $(data_type_name) ($(data_type))")
    print(io, "\n  dims: ", join(dims, ", "))
    if !isnothing(segment)
        a = segment.var"#begin"
        b = segment.var"#end"
        print(io, "\n  segment: [$a, $b]")
    end
    isempty(float_data) || print(io, "\n  float_data: ", number_of(float_data, "element"))
    isempty(int32_data) || print(io, "\n  int32_data: ", number_of(int32_data, "element"))
    isempty(string_data) || print(io, "\n  string_data: ", number_of(string_data, "string"))
    isempty(int64_data) || print(io, "\n  int64_data: ", number_of(int64_data, "element"))
    isempty(doc_string) || print(io, "\n  doc_string: $doc_string")
    isempty(raw_data) || print(io, "\n  raw_data: ", number_of(raw_data, "byte"))
    isempty(external_data) || print(io, "\n  external_data: ", number_of(external_data, "item"))
    data_location_name = string(data_location)
    data_location_name == "DEFAULT" || print(io, "\n data_location: ", data_location_name)
    isempty(double_data) || print(io, "\n  double_data: ", number_of(double_data, "element"))
    isempty(uint64_data) || print(io, "\n  uint64_data: ", number_of(uint64_data, "element"))
    isempty(metadata_props) || print(io, "\n  metadata_props: $(map_summary(metadata_props))")
end

function Base.show(io::IO, tensor::TensorProto)
    print(io, isempty(tensor.name) ? "<unnamed>" : tensor.name)
end

function map_summary(x::Vector)
    if length(x) == 1
        return "Map with 1 entry"
    else
        return "Map with $(length(x)) entries"
    end
end

plural(x) = (length(x) == 1) ? "" : "s"

number_of(x, name) = string(length(x), " ", name, plural(x))

function values_or_number_of(x, name)
    values = join(x, ", ")
    length(values) <= 40 && return values
    return number_of(x, name)
end

function tensorproto_datatype(i)
    return get(Base.Enums.namemap(ONNXLowLevel.var"TensorProto.DataType".T),
               i, :UNKNOWN_TENSORPROTO_DATATYPE)
end
