# Extract the bow shock location from 2D equatorial run outputs and save into file.
#
# To run in multi-threading mode
#   julia -t nthreads demo_bowshock_series.jl
# or alternatively
#   JULIA_NUM_THREADS=$nthreads ./julia demo_bowshock_series.jl
#
# Hongyang Zhou, hyzhou@umich.edu

using Vlasiator, Glob
using JLD2: jldsave

# Upstream solar wind temperature
const Tsw = 0.5e6 #[K]

function extract_bowshock_position(filenames; verbose=true)
   nfiles = length(filenames)

   verbose && println("Number of files: $nfiles")

   meta = load(filenames[1])

   x = LinRange{Float32}(meta.coordmin[1], meta.coordmax[1], meta.ncells[1])
   y = LinRange{Float32}(meta.coordmin[2], meta.coordmax[2], meta.ncells[2])

   close(meta.fid)

   # Only extract bow shock location near the front between y = ±20Re
   Re = Vlasiator.Re
   ymin_ = findlast(<(-20Re), y)
   ymax_ = findfirst(>(20Re), y)

   x_crossing = zeros(Float32, ymax_-ymin_+1, nfiles)
   y_crossing = y[ymin_:ymax_]

   Threads.@threads for ifile = 1:nfiles
      verbose && println("$(filenames[ifile]) on thread $(Threads.threadid())")
      f = load(filenames[ifile])
      # Obtain thermal temperature
      T = f["T"]
      close(f.fid)
      T = reshape(T, f.ncells[1], f.ncells[2])
      # Extract bow shock location from the 1st point which fulfills
      # the threshold: T > 4 * Tsw
      for (i,j) in enumerate(ymin_:ymax_) # scan in y direction
         ind_ = findlast(>(4*Tsw), @view T[:,j]) # count from upstream
         x_crossing[i,ifile] = x[ind_]
      end
   end

   return x_crossing, y_crossing
end

#####
filenames = glob("bulk*.vlsv", "run_rho2_bz-5_timevarying_startfrom300s")

@time x_crossing, y_crossing = extract_bowshock_position(filenames)

jldsave("example.jld2"; x_crossing, y_crossing)