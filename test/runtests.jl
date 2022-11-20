using Test, URIs, HTTP, JSON3, OrderedCollections
if isinteractive()
    using Revise
end
using SpaceTrack

##

if !haskey(ENV, "SPACETRACK_IDENTITY") || !haskey(ENV, "SPACETRACK_PASSWORD")
    error("No credentials provided. Please set `SPACETRACK_IDENTITY` and `SPACETRACK_PASSWORD`")
end

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

        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("invald",         "query",   "gp",      Dict("predicates" => "object_id"), "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "invalid", "gp",      Dict("predicates" => "object_id"), "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query",   "invalid", Dict("predicates" => "object_id"), "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query",   "gp",      Dict("invalid" => "false"),        "json")
        @test_throws SpaceTrack.InvalidRequest SpaceTrack.validate_request("basicspacedata", "query",   "gp",      Dict("predicates" => "object_id"), "invalid")
        
        @test SpaceTrack.validate_request("basicspacedata", "query", "gp", Dict("predicates" => "object_id"), "json")
        
    end

    @testset "requests" begin

        @testset "compose_uri" begin
            uri_test_cases = [
                ("https://www.space-track.org", "basicspacedata", "query", "gp", Dict("EPOCH"=>">2022-11-15T01:23:45")) => "https://www.space-track.org/basicspacedata/query/class/gp/EPOCH/%3E2022-11-15T01%3A23%3A45",
                ("https://for-testing-only.space-track.org", "basicspacedata", "query", "gp", Dict("object_name"=>"~~NAVSTAR")) => "https://for-testing-only.space-track.org/basicspacedata/query/class/gp/object_name/%7E%7ENAVSTAR",
                ("https://for-testing-only.space-track.org", "basicspacedata", "query", "satcat_debut", OrderedDict("object_name"=>"~~USA", "orderby"=>"launch desc", "DEBUT"=>"2022-01-01T00:00:00--2022-11-15T01:23:45", "object_number"=>"<>54220", "INTLDES"=>"^2022", "decay"=>"null-val", "limit"=>"5,5")) => "https://for-testing-only.space-track.org/basicspacedata/query/class/satcat_debut/object_name/%7E%7EUSA/orderby/launch%20desc/DEBUT/2022-01-01T00%3A00%3A00--2022-11-15T01%3A23%3A45/object_number/%3C%3E54220/INTLDES/%5E2022/decay/null-val/limit/5%2C5",
            ]

            for (args, expected_uri_string) ∈ uri_test_cases
                test_uri = SpaceTrack.compose_uri(args...)
                @test test_uri isa URI
                @test string(test_uri) == expected_uri_string
            end
        end
        
        # TODO: Probably should think about mocking these requests and do separate tests that the API still returns the expected schema
        SpaceTrack.login!(ENV["SPACETRACK_IDENTITY"], ENV["SPACETRACK_PASSWORD"])

        http_response = SpaceTrack._get(SpaceTrack.default_state, "basicspacedata", "query", "announcement", Dict("format"=>"json"))
        @test http_response isa HTTP.Response
        @test http_response.status == 200
        @test JSON3.read(http_response.body) isa AbstractArray # just to see if parsable JSON is returned

        announcements_json = SpaceTrack.get_raw("basicspacedata", "query", "announcement", Dict("format"=>"json"))
        @test !isempty(announcements_json)
        @test JSON3.read(announcements_json) isa AbstractArray # just to see if parsable JSON is returned

        announcements = SpaceTrack.get("basicspacedata", "query", "announcement")
        @test announcements isa AbstractDict # TODO: change this once proper structs are implemented
        @test announcements.data isa AbstractArray

        SpaceTrack.logout!()
        
    end
    
end
