using Test, URIs
if isinteractive()
    using Revise
end
using SpaceTrack

##

@testset "SpaceTrack.jl" begin

    @testset "Credentials" begin

        creds = SpaceTrack.Credentials(ENV["SPACETRACK_IDENTITY"], ENV["SPACETRACK_PASSWORD"])

        @test creds isa SpaceTrack.Credentials

        io = IOBuffer()
        show(io, creds)
        @test String(take!(io)) == "Credentials()"

        @test isnothing(SpaceTrack.default_state.credentials)
        @test_throws SpaceTrack.MissingCredentials SpaceTrack.login!()

        SpaceTrack.set_credentials!(creds)
        @test SpaceTrack.default_state.credentials === creds

    end

    @testset "login/logout" begin

        @test SpaceTrack.login!(ENV["SPACETRACK_IDENTITY"], ENV["SPACETRACK_PASSWORD"])
        @test SpaceTrack.default_state.logged_in
        @test SpaceTrack.logout!()
        @test !SpaceTrack.default_state.logged_in 

        @test SpaceTrack.login!()
        @test SpaceTrack.default_state.logged_in
        @test SpaceTrack.logout!()
        @test !SpaceTrack.default_state.logged_in

    end

    @testset "state" begin

        SpaceTrack.set_base_uri!("https://for-testing-only.space-track.org")
        @test SpaceTrack.default_state.base_uri === "https://for-testing-only.space-track.org"

        SpaceTrack.reset!()
        @test SpaceTrack.default_state.base_uri === "https://www.space-track.org"

        state = SpaceTrack.State()
        @test state isa SpaceTrack.State

    end

    @testset "request validation" begin

        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("invalidcontroller", "query", "gp", ["predicates"=>"object_id"], "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "invalidaction", "gp", ["predicates"=>"object_id"], "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query", "invalidclass", ["predicates"=>"object_id"], "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query", "gp", ["invalidpredicate"=>"false"], "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query", "gp", ["predicates"=>"object_id"], "invalidformat")
        
    end

    @testset "requests" begin
        
        example_uri = SpaceTrack.compose_uri("https://www.space-track.org", "basicspacedata", "query", "gp", ["EPOCH"=>">2022-11-15T01:23:45", "OBJECT_NAME"=>"~~USA", "orderby"=>"EPOCH desc", "limit"=>"10", "metadata"=>"true", "emptyresult"=>"show"])
        example_uri_expected = "https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3E2022-11-15T01%3A23%3A45/OBJECT_NAME/%7E%7EUSA/orderby/EPOCH%20desc/limit/10/metadata/true/emptyresult/show"
        @test example_uri isa URI
        @test string(example_uri) == example_uri_expected
        
    end
    
end

