using UnifiedPseudopotentialFormat.PSlibrary

@testset "Test `potential_exists`" begin
    @test potential_exists("S.rel-pz-n-rrkjus_psl.0.1.UPF")
    @test potential_exists("S.pbe-nl-rrkjus_psl.1.0.0.UPF")
    @test potential_exists("S.rel-pbesol-n-kjpaw_psl.0.1.UPF")
end
