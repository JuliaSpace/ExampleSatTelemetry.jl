## Description #############################################################################
#
# This file defines the database with the variables for our hypothetical satellite.
#
############################################################################################

# Return the timestamp of the telemetry packet.
#
# Notice that sometimes it can be different from the timestamp we computed previously
# because the latter might be the instant when the ground station received the frame. In our
# example, they are equal.
_get_telemetry_timestamp(tm::TelemetryPacket{ExampleSatTelemetrySource}) = tm.timestamp

# This function unpack the telemetry by removing the CRC field.
_unpack_telemetry(tm::TelemetryPacket{ExampleSatTelemetrySource}) = tm.data[1:end - 2]

# Create the database.
db = create_telemetry_database(
    "ExampleSat";
    get_telemetry_timestamp = _get_telemetry_timestamp,
    unpack_telemetry = _unpack_telemetry
)

# Now, we can register the variables.

# == Auxiliary Functions ===================================================================

# General functions for the variables that are `Float32`.
_f32_btf(frame::AbstractVector{UInt8}) = frame
_f32_rtf(byte_array::AbstractVector{UInt8}) = first(reinterpret(UInt32, byte_array))
_f32_tf(raw) = reinterpret(Float32, raw)

# == V001 ==================================================================================

# Bit transfer function.
_v001_btf(frame::AbstractVector{UInt8}) = frame

# Raw transfer function.
_v001_rtf(byte_array::AbstractVector{UInt8}) = first(reinterpret(UInt32, byte_array))

# Transfer function.
const _GPS_EPOCH = DateTime("1980-01-06T00:00:00.000")
function _v001_tf(raw)
    return _GPS_EPOCH + Dates.Second(raw)
end

# Register the variable.
add_variable!(
    db,
    :V001,
    1,
    4,
    _v001_tf,
    _v001_btf,
    _v001_rtf;
    alias = :obt,
    description = "Satellite onboard time [GPS Time]",
    endianess = :bigendian
)

# == V002 ==================================================================================

# Bit transfer function.
_v002_btf(frame::AbstractVector{UInt8}) = UInt8[frame[1]]

# Raw transfer function.
_v002_rtf(byte_array::AbstractVector{UInt8}) = byte_array[1]

# Transfer function.
function _v002_tf(raw)
    if raw == 0
        return "Stand-By"
    elseif raw == 1
        return "Survival"
    elseif raw == 2
        return "Safe-hold"
    elseif raw == 3
        return "Mission"
    else
        return "Undefined"
    end
end

# Register the variable.
add_variable!(
    db,
    :V002,
    5,
    1,
    _v002_tf,
    _v002_btf,
    _v002_rtf;
    alias = :mode,
    description = "Satellite mode",
    endianess = :bigendian
)

# == V003 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V003,
    6,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vR_tod_x,
    description = "Satellite X-axis position represented in the TOD reference frame",
    endianess = :bigendian
)

# == V004 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V004,
    10,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vR_tod_y,
    description = "Satellite Y-axis position represented in the TOD reference frame",
    endianess = :bigendian
)

# == V005 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V005,
    14,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vR_tod_z,
    description = "Satellite Z-axis position represented in the TOD reference frame",
    endianess = :bigendian
)

# == V006 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V006,
    18,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vV_tod_x,
    description = "Satellite X-axis velicity represented in the TOD reference frame",
    endianess = :bigendian
)

# == V007 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V007,
    22,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vV_tod_y,
    description = "Satellite Y-axis velicity represented in the TOD reference frame",
    endianess = :bigendian
)

# == V008 ==================================================================================

# Register the variable.
add_variable!(
    db,
    :V008,
    26,
    4,
    _f32_tf,
    _f32_btf,
    _f32_rtf;
    alias = :vV_tod_z,
    description = "Satellite Z-axis velicity represented in the TOD reference frame",
    endianess = :bigendian
)

# == V009 ==================================================================================

# This variable is a derived one. Hence, we only need to define the transfer function.

function _v009_tf(raw, processed_variables)
    # Get the satellite Z-axis velocity represented in the TOD reference frame, which is a
    # dependency for this variable.
    vV_tod_z = processed_variables[:V008].processed

    if vV_tod_z >= 0
        return "Ascending"
    else
        return "Descending"
    end
end

# Register the variable.
add_variable!(
    db,
    :V009,
    _v009_tf;
    alias = :passage_type,
    description = "Ascending or descending passage",
    dependencies = [:V008]
)
