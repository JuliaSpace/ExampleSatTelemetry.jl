## Description #############################################################################
#
# In this file, we define the source interface for our hypothetical satellite.
#
############################################################################################

# First, we need to create the structure that will store the telemetry source. For our
# example, it is just a text file. Hence, we will create a vector to store the timestamps
# and another to store the lines.
struct ExampleSatTelemetrySource <: TelemetrySource
    vt::Vector{DateTime}
    vlines::Vector{String}
end

# Now we can define the API functions.

# Function to initialize the telemetry source. In this case, we only read the file, parse
# the timestamps, and store the telemetry frames.
function TelemetryAnalysis._api_init_telemetry_source(
    ::Type{ExampleSatTelemetrySource},
    filename::String
)
    vlines = readlines(filename)
    vt = DateTime[]
    sizehint!(vt, length(vlines))

    # Fill the timestamps.
    epoch = DateTime("1980-01-06T00:00:00.000")
    for l in vlines
        # The data in the telemetry is expressed in GPS time. Hence, we should subtract the
        # number o leap seconds to obtain UTC.
        Δt = parse(UInt32, @views(l[7:14]), base = 16) - 18
        push!(vt, epoch + Dates.Second(Δt))
    end

    return ExampleSatTelemetrySource(vt, vlines)
end

# Function to return the telemetries.
function TelemetryAnalysis._api_get_telemetry(
    source::ExampleSatTelemetrySource,
    start_time::DateTime,
    end_time::DateTime
)
    # Output vector.
    vtms = TelemetryPacket{ExampleSatTelemetrySource}[]

    # Loop through all telemetries we have, checking if we are inside the interval.
    @views for k in eachindex(source.vt)
        !(start_time <= source.vt[k] <= end_time) && continue

        # Here, we must:
        #
        #   1. Remove the ID from the telemetry frame.
        #   2. Convert the string to a sequence of bytes.
        #   3. Check if the checksum is valid.
        #   4. Add to the output vector.

        line = source.vlines[k][7:end]
        num_bytes = div(length(line), 2)

        data_with_crc = UInt8[]
        sizehint!(data_with_crc, num_bytes)

        for k in 1:num_bytes
            push!(data_with_crc, parse(UInt8, line[2k - 1:2k], base = 16))
        end

        # Check the CRC.
        crc = convert(UInt16, 0xFFFF & sum(data_with_crc[1:end - 2]))
        expected_crc = first(reinterpret(UInt16, reverse(data_with_crc[end - 1:end])))

        if crc != expected_crc
            @warn "Wrong checksum found in telemetry $k."
            continue
        end

        push!(vtms, TelemetryPacket{ExampleSatTelemetrySource}(
            timestamp = source.vt[k],
            data = data_with_crc
        ))
    end

    return vtms
end

# Function to return all the telemetries.
function TelemetryAnalysis._api_get_telemetry(source::ExampleSatTelemetrySource)
    # Output vector.
    vtms = TelemetryPacket{ExampleSatTelemetrySource}[]

    # Loop through all telemetries we have, checking if we are inside the interval.
    @views for k in eachindex(source.vt)
        # Here, we must:
        #
        #   1. Remove the ID from the telemetry frame.
        #   2. Convert the string to a sequence of bytes.
        #   3. Check if the checksum is valid.
        #   4. Add to the output vector.

        line = source.vlines[k][7:end]
        num_bytes = div(length(line), 2)

        data_with_crc = UInt8[]
        sizehint!(data_with_crc, num_bytes)

        for k in 1:num_bytes
            push!(data_with_crc, parse(UInt8, line[2k - 1:2k], base = 16))
        end

        # Check the CRC.
        crc = convert(UInt16, 0xFFFF & sum(data_with_crc[1:end - 2]))
        expected_crc = first(reinterpret(UInt16, reverse(data_with_crc[end - 1:end])))

        if crc != expected_crc
            @warn "Wrong checksum found in telemetry $k."
            continue
        end

        push!(vtms, TelemetryPacket{ExampleSatTelemetrySource}(
            timestamp = source.vt[k],
            data = data_with_crc
        ))
    end

    return vtms
end
