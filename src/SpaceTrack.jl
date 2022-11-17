module SpaceTrack

using HTTP, URIs, Dates

import Pkg, StructTypes, JSON3

let proj = Pkg.project(), deps = Pkg.dependencies()
    pkg_version = proj.version
    http_version = try
        deps[proj.dependencies["HTTP"]].version
    catch
        "missing"
    end
    global const HTTP_USER_AGENT = "SpaceTrack.jl/$pkg_version HTTP.jl/$http_version julia/$VERSION"
end

# bad idea? use header directly instead?
HTTP.setuseragent!(HTTP_USER_AGENT)

const DEFAULT_BASE_URI = "https://www.space-track.org"

# Exceptions

abstract type SpaceTrackError <: Exception end

struct MissingCredentials <: SpaceTrackError 
end

# Structs

struct Credentials
    username::String
    password::String
end
Base.show(io::IO, ::Credentials) = print(io, "Credentials()")

mutable struct State
    credentials::Union{Credentials, Nothing}
    http_headers::Vector{Pair{String, String}}
    http_options::Dict{Symbol, Any}
    http_cookie_jar::HTTP.Cookies.CookieJar
    logged_in::Bool
    base_uri::String
end

const default_state = State(
    nothing, 
    [], 
    Dict(
        :retry => false,
        :keep_alive => true, # work-around for HTTP.jl not noticing when TLS connections are closed. space-track.org seems to nuke connections after 240s idle time.
        :connect_timeout => 30,
        :readtimeout => 120,
    ), 
    HTTP.Cookies.CookieJar(), 
    false, 
    DEFAULT_BASE_URI,
)

function set_base_uri!(uri::String)
    default_state.base_uri = uri
end

# Auth

function set_credentials!(creds::Credentials)
    default_state.credentials = creds
end

login!(username::String, password::String) = login!(default_state, username::String, password::String)
function login!(state::State, username::String, password::String)
    set_credentials!(Credentials(username, password))
    login!(state)
end

login!() = login!(default_state)
function login!(state::State)

    if isnothing(state.credentials)
        return throw(MissingCredentials())
    end

    res = HTTP.request(:POST, state.base_uri * "/ajaxauth/login", 
        [],
        Dict(
            "identity" => state.credentials.username,
            "password" => state.credentials.password,
        );
        cookies = true, cookiejar = state.http_cookie_jar,
        status_exception = true,
        state.http_options...,
    )

    data = JSON3.read(res.body)
    state.logged_in = isempty(data)
end

end
