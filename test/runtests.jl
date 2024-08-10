using Test: @testset, @test

include("utils.jl")

@testset "Attribute" include("attributes.jl")
@testset "Tensor" include("tensors.jl")
@testset "ValueInfo" include("value_infos.jl")

# Deserialization doesn't work for 32 bits and it looks like a bug in
# the ProtoBuf package.
if Sys.WORD_SIZE == 64
    @testset "load and save" include("load_save.jl")
end
