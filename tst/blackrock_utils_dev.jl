using Neuro, StatsBase, StatsPlots, BenchmarkTools, Distributions
gr(fmt = :png) # Fast / not interactive
#plotlyjs() # Slow / interactive
## Spike Rates
    max_spikes = 1000
    num_trials = 100
    spike_times = [randn(rand(1:max_spikes)) for i in 1:num_trials]
    time_windows = -.5:.5:1
    spike_rates = Neuro.ComputeSpikeRates(spike_times[1], time_windows)

## RasterPlot
    max_spikes = 1000
    num_trials = 10
    spike_times = [rand(rand(1:max_spikes)) for i in 1:num_trials]
    raster(spike_times, group_offset = 1)

## PSTH
    max_spikes = 100
    num_trials = 500
    groups = [rand(1:4)  for i in 1:num_trials]
    spike_times = [randn(rand(1:max_spikes)) .+ groups[i] for i in 1:num_trials]
    psth(spike_times, groupidx = groups, subsamplemethod=:Bootstrap, numbootstraps = 100, errormode=:STD,
     smoothingmethod=:gaussian, smoothingbins=5)

## Import blackrock utah array map
    # Declare serial number for
    anterior_serial = "4566-002368"
    posterior_serial = "4566-002318"
    
    # File names for loading - check drive mapping
    anterior_map_path = raw"Z:\BCI02\SurgicalData\4566-002368\SN 4566-002368.cmp"
    posterior_map_path = raw"Z:\BCI02\SurgicalData\4566-002318\SN 4566-002318.cmp"
    
    ProfileView.@profview anterior_map = Neuro.LoadUtahArrayMap(anterior_map_path)
    
## Defining NEV Structs
    struct NEVMetaTags
        Subject::String
        Experimenter::String
        DateTime::String
        SampleRes::Int
        Comment::String
        FileTypeID::String
        Flags::String
        OpenNEVver::String
        DateTimeRaw::Vector{Int}
        FileSpec::String
        PacketBytes::Int
        HeaderOffset::Int
    end

    mutable struct NEVData
        SerialDigitalIO
        Spikes
        Comments
        VideoSync
        Tracking
        TrackingEvents
        PatientTrigger
        Reconfig
    end

    # Structs need to be defined from the bottom up
    mutable struct NEV
        MetaTags
        ElectrodeInfo
        Data::NEVData
        IOLabels
    end

## Loading NEV file
fpath = raw"C:\Users\somlab\Desktop\cua1401_Peroni_neuraldata_20180918T112943001.nev"
FID = htol(open(fpath, "r")) # Assert little endian (32-bit)

### Extract header information
Header_Raw = convert.(UInt8, read(FID, 336 * sizeof(UInt8)))
Header_Int = parse.(Int, Base.dec.(Header_Raw, 1, false))

FileTypeID = String(Header_Raw[1:8])
FileSpec = string(Header_Int[9]) * '.' * string(Header_Int[10])
Flags = Base.bin(reinterpret(UInt16, Header_Raw[11:12])[1], 16, false)
fExtendedHeader = parse(Int, Base.dec.(reinterpret(UInt16, Header_Raw[13:16])[1], 1, false))
countPacketBytes  = parse(Int, Base.dec.(reinterpret(UInt16, Header_Raw[17:20])[1], 1, false))
TimeRes = parse(Int, Base.dec.(reinterpret(UInt16, Header_Raw[21:24])[1], 1, false))
SampleRes = parse(Int, Base.dec.(reinterpret(UInt16, Header_Raw[25:28])[1], 1, false))
temp_FileDialog = Header_Raw[45:76]
FileDialog = String(temp_FileDialog[temp_FileDialog .!= 0])
temp_Comment = Header_Raw[77:332]
Comment = String(temp_Comment[temp_Comment .!= 0])

# Assign to struct