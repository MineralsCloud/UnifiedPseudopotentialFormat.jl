using UnifiedPseudopotentialFormat: analyzename

@testset "Test `analyzename`" begin
    @test_throws AssertionError analyzename(UPFFile("xxyyzz"))
    @test_throws AssertionError analyzename(UPFFile("xxyyzz.xml"))
    @test_throws ArgumentError analyzename(UPFFile("x.upf"))
    @test_throws ArgumentError analyzename(UPFFile("x.UPF"))
end
