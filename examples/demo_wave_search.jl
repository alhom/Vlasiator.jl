# Sample postprocessing script for wave-like structure spatial distribution searching.
#
# Usage:
#   julia -t 4 demo_wave_search.jl
# or
#   JULIA_NUM_THREADS=4 julia demo_wave_search.jl
#
# Procedures:
# 1. Extract variables in all cells from all snapshots.
# 2. For each cell, count time-series local peaks.
# 3. Plot the number of peaks across the whole domain as an indicator for waves.
#
# Note:
# 1. When dealing with multiple variables, it is recommended to handle one variable at a
# time through the whole process due to memory considerations.
# 2. This approach cannot tell the temporal variation of wave-like activities. To also track
# the temporal distribution, we would need the spectra density over time.
#
# Hongyang Zhou, hyzhou@umich.edu

using Glob, Vlasiator, PyPlot, LaTeXStrings

"Extract time series variable"
function extract_var(files, ncells, varname, component=0)
   nfiles = length(files)
   var = zeros(Float32, ncells[1], ncells[2], nfiles)

   # Extract data from each frame
   if component == 0 # scalar
      Threads.@threads for i = eachindex(files)
         meta = load(files[i])
         var[:,:,i] = meta[varname]
      end
   else # vector component
      Threads.@threads for i = eachindex(files)
         meta = load(files[i])
         var[:,:,i] = meta[varname][component,:]
      end
   end

   return var
end

function localpeaks(y)
   mins, maxs = eltype(y)[], eltype(y)[]
   for i in 2:length(y)-1
      if y[i+1] < y[i] > y[i-1]
         push!(maxs, i)
      elseif y[i+1] > y[i] < y[i-1]
         push!(mins, i)
      end
   end
   length(mins) + length(maxs)
end

function checkwaves(var)
   npeaks = zeros(Int, size(var,1), size(var,2))

   Threads.@threads for j in axes(var, 2)
      for i in axes(var, 1)
         var_series = @view var[i,j,:]
         npeaks[i,j] = localpeaks(var_series)
      end
   end
   npeaks
end

function plot_spatial_dist(files, varnames, varnames_print, components)
   local x, y, tStart, tEnd, ncells
   let Re = Vlasiator.Re
      meta = load(files[1])
      tStart = meta.time
      ncells = meta.ncells
      x = LinRange{Float32}(meta.coordmin[1]/Re, meta.coordmax[1]/Re, meta.ncells[1])
      y = LinRange{Float32}(meta.coordmin[2]/Re, meta.coordmax[2]/Re, meta.ncells[2])
      meta = load(files[end])
      tEnd = meta.time
   end

   fig, ax = plt.subplots(figsize=(16,9))
   fontsize = 14

   for i in eachindex(varnames)
      # Obtain time series data
      var = extract_var(files, ncells, varnames[i], components[i])
      # Count local peaks at each location
      npeaks = checkwaves(var)
      ## Visualization
      im = ax.pcolormesh(y, x, npeaks, shading="auto")
      ax.set_title("$(varnames_print[i]) Perturbation Detection, "*
         "t = $(round(tStart, digits=1)) ~ $(round(tEnd, digits=1))s";
         fontsize, fontweight="bold")
      ax.set_xlabel(L"y [$R_E$]"; fontsize, weight="black")
      ax.set_ylabel(L"x [$R_E$]"; fontsize, weight="black")
      ax.set_aspect("equal")
      ax.xaxis.set_minor_locator(matplotlib.ticker.AutoMinorLocator())
      ax.yaxis.set_minor_locator(matplotlib.ticker.AutoMinorLocator())
      ax.grid(color="grey", linestyle="-")

      cb = fig.colorbar(im; ax)
      cb.ax.set_ylabel("# of local peaks"; fontsize)

      savefig(
         "../out/spatial_perturbation_distribution_$(lowercase(varnames_print[i])).png",
         bbox_inches="tight")
      cla()
      cb.remove()
   end
end

##### Main

varnames = ["proton/vg_rho", "vg_pressure", "proton/vg_v", "proton/vg_v", "vg_b_vol",
   "vg_e_vol", "vg_e_vol"]
varnames_print = ["Density", "Thermal Pressure", "Vx", "Vy", "Bz", "Ex", "Ey"]
components = [0, 0, 1, 2, 3, 1, 2] # 0: scalar; 1: x, 2: y, 3: z
dir = "../run_rho2_bz-5_timevarying_startfrom300s" # data directory

files = glob("bulk*.vlsv", dir)

println("Total number of snapshots: $(length(files))")
println("Running with $(Threads.nthreads()) threads...")

@time plot_spatial_dist(files, varnames, varnames_print, components)

println("Virtual satellite extraction done!")