module ExampleSatTelemetry

using Dates
using TelemetryAnalysis

export ExampleSatTelemetrySource

############################################################################################
#                                          Source                                          #
############################################################################################

include("./source.jl")

############################################################################################
#                                         Database                                         #
############################################################################################

include("./database.jl")

function __init__()
    # We will set our database as the default one.
    set_default_telemetry_database!(db)
end

end # module ExampleSatTelemetry
