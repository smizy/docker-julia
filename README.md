# docker-julia

Julia + Jupyter Notebook docker image based on alpine


```
# run jupyter
docker run -it --rm -p 8888:8888 -v $(pwd):/code  smizy/julia:0.6-alpine

# open browser (see token in log)
open http://$(docker-machine ip default):8888?token=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# create a notebook selecting "Julia 0.6.x" from [New] pulldown  

# run cell
> ["a", "b", "c"]
3-element Array{String,1}:
 "a"
 "b"
 "c"

```