using ONNXLowLevel: AttributeProto, TensorProto, GraphProto,
                    SparseTensorProto, TypeProto, get_attribute, get_attributes

testcases =
    [(3.14f0,
      """
      f: 3.14
      type: FLOAT
      """),

     (BigFloat(3.14f0),
      """
      f: 3.14
      type: FLOAT
      """),

     (Float16(3.14),
      """
      f: 3.140625
      type: FLOAT
      """),

     (-1,
      """
      i: -1
      type: INT
      """),

     (0xff,
      """
      i: 255
      type: INT
      """),

     ("foo",
      """
      s: "foo"
      type: STRING
      """),

     
     (SubString("bar"),
      """
      s: "bar"
      type: STRING
      """),

     
     (TensorProto("foo", Int64[1]),
      raw"""
      t {
        dims: 1
        data_type: 7
        name: "foo"
        raw_data: "\001\000\000\000\000\000\000\000"
      }
      type: TENSOR
      """),

     (GraphProto(),
      """
      g {
      }
      type: GRAPH
      """),

     (SparseTensorProto(),
      """
      type: SPARSE_TENSOR
      sparse_tensor {
      }
      """),

     
     (TypeProto(),
      """
      tp {
      }
      type: TYPE_PROTO
      """),

     
     (Float32[1, 2],
      """
      floats: 1
      floats: 2
      type: FLOATS
      """),

     ([1.0, 2.0],
      """
      floats: 1
      floats: 2
      type: FLOATS
      """),

     ([1, 2],
      """
      ints: 1
      ints: 2
      type: INTS
      """),

     (Integer[Int8(1), UInt16(2)],
      """
      ints: 1
      ints: 2
      type: INTS
      """),

     (Int32(4):Int32(6),
      """
      ints: 4
      ints: 5
      ints: 6
      type: INTS
      """),

     (["foo", "bar"],
      """
      strings: "foo"
      strings: "bar"
      type: STRINGS
      """),

     ((@view SubString["foo"][1:1]),
      """
      strings: "foo"
      type: STRINGS
      """),

     ([TensorProto("foo", Int64[1]), TensorProto("bar", [-0.0f0])],
      raw"""
      tensors {
        dims: 1
        data_type: 7
        name: "foo"
        raw_data: "\001\000\000\000\000\000\000\000"
      }
      tensors {
        dims: 1
        data_type: 1
        name: "bar"
        raw_data: "\000\000\000\200"
      }
      type: TENSORS
      """),

     ((@view [TensorProto("foo", Int64[1])][1:1]),
      raw"""
      tensors {
        dims: 1
        data_type: 7
        name: "foo"
        raw_data: "\001\000\000\000\000\000\000\000"
      }
      type: TENSORS
      """),

     ([GraphProto(), GraphProto()],
      """
      graphs {
      }
      graphs {
      }
      type: GRAPHS
      """),

     ((@view [GraphProto(), GraphProto()][:]),
      """
      graphs {
      }
      graphs {
      }
      type: GRAPHS
      """),

     ([SparseTensorProto(), SparseTensorProto()],
      """
      type: SPARSE_TENSORS
      sparse_tensors {
      }
      sparse_tensors {
      }
      """),

     ((@view [SparseTensorProto(), SparseTensorProto()][:]),
      """
      type: SPARSE_TENSORS
      sparse_tensors {
      }
      sparse_tensors {
      }
      """),

     ([TypeProto(), TypeProto()],
      """
      type_protos {
      }
      type_protos {
      }
      type: TYPE_PROTOS
      """),

     ((@view [TypeProto(), TypeProto()][:]),
      """
      type_protos {
      }
      type_protos {
      }
      type: TYPE_PROTOS
      """)]

for (value, expected) in testcases
    @test protoc_decode(AttributeProto("", value)) == expected
end

@test protoc_decode(AttributeProto("foo", 0)) ==
    """
    name: "foo"
    type: INT
    """

@test protoc_decode(AttributeProto("föö", "bär")) ==
    raw"""
    name: "f\303\266\303\266"
    s: "b\303\244r"
    type: STRING
    """

values = first.(testcases)
attributes = [AttributeProto(string(i), value)
              for (i, value) in enumerate(values)]

for (i, value) in enumerate(values)
    @test get_attribute(attributes[i]) == (string(i) => value)
end

@test get_attributes(attributes) == Dict(string(i) => value
                                         for (i, value) in enumerate(values))

attributes = get_attributes([AttributeProto("a", 1), AttributeProto("b", 2.0)],
                            dicttype = Dict{String, Real})
@test attributes == Dict("a" => 1, "b" => 2.0)
@test typeof(attributes) == Dict{String, Real}
@test typeof(attributes["b"]) == Float32
