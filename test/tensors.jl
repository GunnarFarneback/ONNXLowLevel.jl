using ONNXLowLevel: TensorProto, get_tensor

testcases =
    ((Int8, (), [97],
      """
      data_type: 3
      raw_data: "a"
      """),
     (UInt8, (2,), 97:98,
      """
      dims: 2
      data_type: 2
      raw_data: "ab"
      """),
     (Int8, (2, 1), 97:98,
      """
      dims: 1
      dims: 2
      data_type: 3
      raw_data: "ab"
      """),
     (UInt8, (1, 2), 97:98,
      """
      dims: 2
      dims: 1
      data_type: 2
      raw_data: "ab"
      """),
     (Int8, (2, 3), 97:102,
      """
      dims: 3
      dims: 2
      data_type: 3
      raw_data: "abcdef"
      """),
     (UInt8, (2, 1, 3), 97:102,
      """
      dims: 3
      dims: 1
      dims: 2
      data_type: 2
      raw_data: "abcdef"
      """),
     (Int8, (2, 1, 2, 1, 3, 1, 2), 97:120,
      """
      dims: 2
      dims: 1
      dims: 3
      dims: 1
      dims: 2
      dims: 1
      dims: 2
      data_type: 3
      raw_data: "abcdefghijklmnopqrstuvwx"
      """),
     (Int16, (1,), [0x6162],
      """
      dims: 1
      data_type: 5
      raw_data: "ba"
      """),
     (UInt16, (1,), [0x6364],
      """
      dims: 1
      data_type: 4
      raw_data: "dc"
      """),
     (Int32, (1,), [0x61626364],
      """
      dims: 1
      data_type: 6
      raw_data: "dcba"
      """),
     (UInt32, (1,), [0x65666768],
      """
      dims: 1
      data_type: 12
      raw_data: "hgfe"
      """),
     (Int64, (1,), [0x6162636465666768],
      """
      dims: 1
      data_type: 7
      raw_data: "hgfedcba"
      """),
     (UInt64, (1,), [0x696a6b6c6d6e6f70],
      """
      dims: 1
      data_type: 13
      raw_data: "ponmlkji"
      """),
     (Bool, (2,), [false, true],
      raw"""
      dims: 2
      data_type: 9
      raw_data: "\000\001"
      """),
     (Float64, (1,), [1],
      raw"""
      dims: 1
      data_type: 11
      raw_data: "\000\000\000\000\000\000\360?"
      """),
     (Float32, (1,), [1],
      raw"""
      dims: 1
      data_type: 1
      raw_data: "\000\000\200?"
      """),
     (Float16, (1,), [1],
      raw"""
      dims: 1
      data_type: 10
      raw_data: "\000<"
      """),
     (ComplexF64, (1,), [1+2im],
      raw"""
      dims: 1
      data_type: 15
      raw_data: "\000\000\000\000\000\000\360?\000\000\000\000\000\000\000@"
      """),
     (ComplexF32, (1,), [1+2im],
      raw"""
      dims: 1
      data_type: 14
      raw_data: "\000\000\200?\000\000\000@"
      """),
     (String, (1,), ["test"],
      """
      dims: 1
      data_type: 8
      string_data: "test"
      """),
     )

for (type, dims, values, expected) in testcases
    x = reshape(type.(values), dims)
    t = TensorProto(x)
    @test protoc_decode(t) == expected
    @test get_tensor(t) == x
end

t = TensorProto("foo", UInt8[97], doc_string = "bar")
@test protoc_decode(t) ==
    raw"""
    dims: 1
    data_type: 2
    name: "foo"
    raw_data: "a"
    doc_string: "bar"
    """
@test get_tensor(t) == UInt8[97]

@test get_tensor(TensorProto(1:5)) == 1:5
@test get_tensor(TensorProto(@view fill(SubString("foo"), 3)[1:2])) == ["foo", "foo"]
