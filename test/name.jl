using UnifiedPseudopotentialFormat

@testset "Parse file name" begin
    for str in (
        "Be.pbe-n-kjpaw_psl.1.0.0.UPF",
        # "Be.pbesol-sl-rrkjus_psl.1.0.0.UPF",
        "Be.rel-pz-n-rrkjus_psl.0.2.UPF",
    )
        @test string(parse(UPFFileName, str)) == str
    end
end
