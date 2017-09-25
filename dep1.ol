include "console.iol"
include "dependencies.iol"

interface dep1Interface {
RequestResponse: inc(int)(int)
OneWay:
}

inputPort dep1In {
Location: "socket://localhost:8000"
Protocol: sodep
Interfaces: dep1Interface
}

execution{ concurrent }

main
{
  [inc(request)(response){
    response = request +1
    }]
}
