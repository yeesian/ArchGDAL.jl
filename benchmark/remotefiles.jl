using Downloads
using SHA

# this file downloads files which are used during testing the package
# if they are already present and their checksum matches, they are not downloaded again

REPO_URL = "https://github.com/yeesian/ArchGDALDatasets/blob/master/"

# remote files with SHA-2 256 hash
"""
To add more files, follow the below steps to generate the SHA
```
julia> using SHA
julia> open(filepath/filename) do f
           bytes2hex(sha256(f))
       end
```
"""
remotefiles = [
    (
        "data/road.zip",
        "058bdc549d0fc5bfb6deaef138e48758ca79ae20df79c2fb4c40cb878f48bfd8",
    ),
]

function verify(path::AbstractString, hash::AbstractString)
    @assert occursin(r"^[0-9a-f]{64}$", hash)
    hash = lowercase(hash)
    if isfile(path)
        calc_hash = open(path) do file
            return bytes2hex(sha256(file))
        end
        @assert occursin(r"^[0-9a-f]{64}$", calc_hash)
        if calc_hash != hash
            @error "Hash Mismatch! Expected: $hash, Calculated: $calc_hash\n"
            return false
        else
            return true
        end
    else
        error("File read error: $path")
    end
end

function download_verify(
    url::AbstractString,
    hash::Union{AbstractString,Nothing},
    dest::AbstractString,
)
    file_existed = false
    # verify if file exists
    if isfile(dest)
        file_existed = true
        if hash !== nothing && verify(dest, hash)
            # hash verified
            return true
        else
            # either hash is nothing or couldn't pass the SHA test
            @error(
                "Failed to verify file: $dest with hash: $hash. Re-downloading file..."
            )
        end
    end
    # if the file exists but some problem exists, we delete it to start from scratch
    file_existed && Base.rm(dest; force = true)
    # Make sure the containing folder exists
    mkpath(dirname(dest))
    # downloads the file at dest
    Downloads.download(url, dest)
    # hash exists and verification fails
    if hash !== nothing && !verify(dest, hash)
        if file_existed
            # the file might be corrupted so we start from scracth
            Base.rm(dest; force = true)
            Downloads.download(url, dest)
            if hash !== nothing && !verify(dest, hash)
                error("Verification failed")
            end
        else
            error("Verification failed. File not created after download.")
        end
    end
    return !file_existed
end

for (f, sha) in remotefiles
    # create the directories if they don't exist
    currdir = dirname(f)
    isdir(currdir) || mkpath(currdir)
    # download the file if it is not there or if it has a different checksum
    currfile = normpath(joinpath(@__DIR__, f))
    url = REPO_URL * f * "?raw=true"
    download_verify(url, sha, currfile)
end
