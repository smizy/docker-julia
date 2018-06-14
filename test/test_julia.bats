@test "julia is the correct version" {
  run docker run smizy/julia:${TAG} julia --version
  echo "${output}" 

  [ $status -eq 0 ]
  [ "${lines[0]}" = "julia version ${VERSION}" ]
}

@test "No error using PyPlot" {
  run docker run smizy/julia:${TAG} julia -e 'using PyPlot'
  echo "${output}" 

  [ $status -eq 0 ]
}