for x in names(ONNXLowLevel)
    type = getfield(ONNXLowLevel, x)
    if isstructtype(type)
        typename = string(x)
        proto_path = joinpath(dirname(@__DIR__), "proto", "onnx.proto3")
        if contains(typename, ".")
            typename = "var\"$typename\""
        end
        fields = String[]
        for (f, t) in zip(fieldnames(type), fieldtypes(type))
            if contains(string(f), "#")
                f = "var\"$f\""
            end
            push!(fields, "* `$f::$t`")
        end
        s = """
                $typename

            Automatically generated ONNX type with fields:
            $(join(fields, "\n"))

            The constructor accepts all fields as keyword arguments with empty/neutral defaults. See $(proto_path) for the meaning of the fields.
            """
        @eval @doc $s $x
    end
end
