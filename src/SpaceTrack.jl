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

struct InvalidRequest <: SpaceTrackError
    msg
end

struct FailedRequest <: SpaceTrackError
    body
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

const default_http_headers = Pair{String, String}[]
const default_http_options = Dict(
    :retry => false,
    :keep_alive => true, # work-around for HTTP.jl not noticing when TLS connections are closed. space-track.org seems to nuke connections after 240s idle time.
    :connect_timeout => 30,
    :readtimeout => 120,
)

State() = State(
    nothing, 
    default_http_headers, 
    copy(default_http_options), 
    HTTP.Cookies.CookieJar(), 
    false, 
    DEFAULT_BASE_URI,
)

const default_state = State()

function reset!()
    default_state.credentials = nothing
    default_state.http_headers = default_http_headers
    default_state.http_options = default_http_options
    default_state.http_cookie_jar = HTTP.Cookies.CookieJar()
    default_state.logged_in = false
    default_state.base_uri = DEFAULT_BASE_URI
    nothing
end

set_base_uri!(uri::String) = set_base_uri!(default_state, uri)
function set_base_uri!(state::State, uri::String)
    state.base_uri = uri
    nothing
end

# Auth

set_credentials!(creds::Credentials) = set_credentials!(default_state, creds)
function set_credentials!(state::State, creds::Credentials)
    state.credentials = creds
    nothing
end

login!() = login!(default_state)
function login!(state::State)

    if isnothing(state.credentials)
        return throw(MissingCredentials())
    end

    res = HTTP.request(:POST, 
        joinpath(URI(state.base_uri), "/ajaxauth/login"),
        state.http_headers,
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

login!(username::String, password::String) = login!(default_state, username, password)
function login!(state::State, username::String, password::String)
    set_credentials!(Credentials(username, password))
    login!(state)
end

logout!() = logout!(default_state)
function logout!(state::State)

    res = HTTP.request(:GET, 
        joinpath(URI(state.base_uri), "/ajaxauth/logout"),
        state.http_headers;
        cookies = true, cookiejar = state.http_cookie_jar,
        status_exception = true,
        state.http_options...,
    )

    state.logged_in = res.status != 200

    return !state.logged_in
end

# Validation

const valid_controllers = ("basicspacedata", "expandedspacedata", "fileshare", "combinedopsdata")
const valid_actions = ("query", "modeldef")
const valid_classes = Dict(
    "basicspacedata" => ("announcement", "boxscore", "cdm_public", "decay", "gp", "gp_history", "launch_site", "omm", "satcat", "satcat_change", "satcat_debut", "tip", "tle", "tle_latest", "tle_publish"),
    "publicfiles" => ("dirs", "getpublicdatafile", "loadpublicdata"),
    "fileshare" => missing, # permission controlled, no idea what's valid
    "combinedopsdata" => missing, # permission controlled, no idea what's valid
)
const valid_predicates = ("predicates", "metadata", "limit", "orderby", "distinct", "format", "emptyresult", "favorites", "recursive")
const valid_formats = ("xml", "json", "html", "csv", "tle", "3le", "kvn", "stream")

function validate_request(controller::String, action::String, class::String, predicates::Dict{String, String}, format::Union{Nothing, String})

    if controller ∉ valid_controllers
        throw(InvalidRequest("controller `$(controller)` not valid."))
    end
    if action ∉ valid_actions
        throw(InvalidRequest("action `$(action)` not valid."))
    end
    if ismissing(valid_classes[controller]) || class ∉ valid_classes[controller]
        throw(InvalidRequest("class `$(class)` not valid with controller `$(controller)`."))
    end

    if any(keys(predicates) .∉ Ref(valid_predicates))
        throw(InvalidRequest("one or more predicates is not valid."))
    end

    if !isnothing(format) && format ∉ valid_formats
        throw(InvalidRequest("format `$(format)` not valid."))
    end

    return true
end

# Requests

function compose_uri(base_uri::String, controller::String, action::String, class::String, predicates::Dict{String, String})
    predicates = escapepath.(keys(predicates)) .* "/" .* escapepath.(values(predicates))
    return joinpath(URI(base_uri), controller, action, "class", class, predicates...)
end

function _get(state::State, controller::String, action::String, class::String, predicates::Dict{String, String} = Dict{String, String}())
    
    uri = compose_uri(state.base_uri, controller, action, class, predicates)

    res = HTTP.request(:GET,
        uri,
        state.http_headers;
        cookies = true, cookiejar = state.http_cookie_jar,
        status_exception = false,
        state.http_options...
    )

    return res
end

function get_raw(state::State, controller::String, action::String, class::String, predicates::Dict{String, String} = Dict{String, String}(); format = nothing, validate = true)

    # kw format should overwrite predicate
    if isnothing(format) && haskey(predicates, "format")
        format = predicates["format"]
        delete!(predicates, "format")
    else
        format = string(format)
    end

    if validate
        validate_request(controller, action, class, predicates, format)
    end

    response = _get(state, controller, action, class, predicates)

    if response.status >= 300
        throw(FailedRequest(String(response.body)))
    end

    String(response.body)
end
get_raw(controller::String, action::String, class::String, predicates::Dict{String, String} = Dict{String, String}(); kwargs...) = get_raw(default_state, controller, action, class, predicates; kwargs...)

end
