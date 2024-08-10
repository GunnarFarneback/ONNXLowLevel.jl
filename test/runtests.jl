using Test: @testset, @test

include("utils.jl")

@testset "Attribute" include("attributes.jl")
@testset "Tensor" include("tensors.jl")
@testset "ValueInfo" include("value_infos.jl")

@testset "load and save" include("load_save.jl")
