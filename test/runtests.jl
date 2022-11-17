using SpaceTrack
using Test

@testset "SpaceTrack.jl" begin
    
    @test isnothing(SpaceTrack.default_state.credentials)

    @test_throws SpaceTrack.MissingCredentials SpaceTrack.login!()

    creds = SpaceTrack.Credentials(ENV["SPACETRACK_IDENTITY"], ENV["SPACETRACK_PASSWORD"])
    SpaceTrack.set_credentials!(creds)
    @test SpaceTrack.default_state.credentials === creds

    @test SpaceTrack.login!()

    @test SpaceTrack.default_state.logged_in

end
