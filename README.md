# ExampleSat

This repository contains an example of how we can implement an interface using
[**TelemetryAnalysis.jl**](https://github.com/JuliaSpace/TelemetryAnalysis.jl) with a
hypothetical satellite called **ExampleSat**.

## Telemetry Format

The telemetries of our hypothetical satellite are available in a text file where each line
has the following format:

```text
<ID> <telemetry><crc>
```

The `<ID>` is an incrementing counter with 5 digits, and `<telemetry>` is a set of 29 bytes
with the telemetry frame. Those 29 bytes contains the information about the following
variables:

| Name | Alias          | Description                                                      | Start byte | Size [bytes] |
| ---- | -------------- | ---------------------------------------------------------------- | ---------- | ------------ |
| V001 | `obt`          | Onboard time (number of seconds from GPS epoch)                  | 1          | 4            |
| V002 | `mode`         | Satellite operating mode                                         | 5          | 1            |
| V003 | `vR_tod_x`     | Satellite X-axis position represented in the TOD reference frame | 6          | 4            |
| V004 | `vR_tod_y`     | Satellite Y-axis position represented in the TOD reference frame | 10         | 4            |
| V005 | `vR_tod_z`     | Satellite Z-axis position represented in the TOD reference frame | 14         | 4            |
| V006 | `vR_tod_x`     | Satellite X-axis velocity represented in the TOD reference frame | 18         | 4            |
| V007 | `vR_tod_y`     | Satellite Y-axis velocity represented in the TOD reference frame | 22         | 4            |
| V008 | `vR_tod_z`     | Satellite Z-axis velocity represented in the TOD reference frame | 26         | 4            |
| V009 | `passage_type` | Ascending or descending passage                                  | -          | -            |

Notice that `V009` is what we call a derived variable. It depends on the values of other
telemetries but does not have a direct relationship to a set of bytes in the frame.

All variables are stored in big endian format (most significant byte first).

The `<crc>` is the sum of all bytes converted to a `UInt16`.

## Telemetry Transfer Functions

We also need to define how we can convert the sequence of bytes in each variable to a
processed value.

- `obt`: Number of seconds elapsed from GPS epoch.
- `mode`: Direct conversion using the table below.
- `vR_tod_{x, y, z}`: A set of 4 bytes describing a `Float32`.
- `vV_tod_{x, y, z}`: A set of 4 bytes describing a `Float32`.
- `passage_type`: Ascending if `vV_tod_z >= 0`, or descending otherwise.

## Interface

The package **ExampleSatTelemetry.jl** implements the source interface and database, as
required by [**TelemetryAnalysis.jl**](https://github.com/JuliaSpace/TelemetryAnalysis.jl).
For more information about the implementation, refer to the files `./src/source.jl` and
`./src/database.jl`.

## Usage

First, we need to load the packages:

```jl
julia> using TelemetryAnalysis, ExampleSatTelemetry
```

Now, we can initialize the telemetry source using the example file with the telemetries:

```jl
julia> init_telemetry_source(ExampleSatTelemetrySource, "examples/ExampleSatTelemetry.txt")
```

Let’s load all the available telemetries:

```jl
julia> tms = get_telemetry()
30000-element Vector{TelemetryPacket{ExampleSatTelemetrySource}}:
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:01, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:02, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:03, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:04, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:05, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:06, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T11:00:07, 31 bytes)
 ⋮
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:54, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:55, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:56, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:57, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:58, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:19:59, 31 bytes)
 TelemetryPacket {ExampleSatTelemetrySource} (Timestamp = 2021-06-19T19:20:00, 31 bytes)
```

Finally, we can process all the variables:

```jl
julia> df = process_telemetry_packets(
           tms,
           [:V001, :V002, :V003, :V004, :V005, :V006, :V007, :V008, :V009]
       )
Progress: 100%|██████████████████████████████████████████████████| Time: 0:00:00
[ Info: 30000 packets out of 30000 were processed correctly.
30000×10 DataFrame
   Row │ timestamp            V001                 V002      V003        V004        V0 ⋯
       │ DateTime             DateTime             String    Float32     Float32     Fl ⋯
───────┼─────────────────────────────────────────────────────────────────────────────────
     1 │ 2021-06-19T11:00:01  2021-06-19T11:00:19  Stand-By   0.0         0.0        0. ⋯
     2 │ 2021-06-19T11:00:02  2021-06-19T11:00:20  Stand-By   0.0         0.0        0.
     3 │ 2021-06-19T11:00:03  2021-06-19T11:00:21  Stand-By   0.0         0.0        0.
     4 │ 2021-06-19T11:00:04  2021-06-19T11:00:22  Stand-By   0.0         0.0        0.
     5 │ 2021-06-19T11:00:05  2021-06-19T11:00:23  Stand-By   0.0         0.0        0. ⋯
   ⋮   │          ⋮                    ⋮              ⋮          ⋮           ⋮          ⋱
 29996 │ 2021-06-19T19:19:56  2021-06-19T19:20:14  Mission   -2.65117e6  -3.97796e6  5.
 29997 │ 2021-06-19T19:19:57  2021-06-19T19:20:15  Mission   -2.64952e6  -3.97254e6  5.
 29998 │ 2021-06-19T19:19:58  2021-06-19T19:20:16  Mission   -2.64786e6  -3.96712e6  5.
 29999 │ 2021-06-19T19:19:59  2021-06-19T19:20:17  Mission   -2.64621e6  -3.96169e6  5. ⋯
 30000 │ 2021-06-19T19:20:00  2021-06-19T19:20:18  Mission   -2.64455e6  -3.95625e6  5.
                                                         5 columns and 29990 rows omitted
```
