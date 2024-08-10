using ONNXLowLevel: ValueInfoProto, get_value_info

testcases =
    [(Float32, [1, 2, 3, 4],
      """
      type {
        tensor_type {
          elem_type: 1
          shape {
            dim {
              dim_value: 1
            }
            dim {
              dim_value: 2
            }
            dim {
              dim_value: 3
            }
            dim {
              dim_value: 4
            }
          }
        }
      }
      """),

     (Int64, ["batch", "channel", "height", "width"],
      """
      type {
        tensor_type {
          elem_type: 7
          shape {
            dim {
              dim_param: "batch"
            }
            dim {
              dim_param: "channel"
            }
            dim {
              dim_param: "height"
            }
            dim {
              dim_param: "width"
            }
          }
        }
      }
      """),

     (UInt16, ["batch", 3],
      """
      type {
        tensor_type {
          elem_type: 4
          shape {
            dim {
              dim_param: "batch"
            }
            dim {
              dim_value: 3
            }
          }
        }
      }
      """)]


for (type, dims, expected) in testcases
    v = ValueInfoProto("", type, dims)
    @test protoc_decode(v) == expected
    @test get_value_info(v) == ("", type, dims)
end

v = ValueInfoProto("foo", Float16, [1], doc_string = "bar")
@test protoc_decode(v) ==
    """
    name: "foo"
    type {
      tensor_type {
        elem_type: 10
        shape {
          dim {
            dim_value: 1
          }
        }
      }
    }
    doc_string: "bar"
    """
@test get_value_info(v) == ("foo", Float16, [1])
