include "console.iol"
include "dependencies.iol"

interface mainInterface {
RequestResponse:
  stampa(string)(void),
  incNum(int)(int)
OneWay:
}

interface dep1Interface {
RequestResponse: inc(int)(int)
OneWay:
}

execution{ concurrent }

inputPort mainIn {
Location: "socket://localhost:8001"
Protocol: sodep
Interfaces: mainInterface
}

outputPort dep1Out {
Location: JDEP_LOCATION_dep1Out
Protocol: sodep
Interfaces: dep1Interface
}

main
{
  [stampa(request)( ){
    println@Console( request )()
    }]

  [incNum(request)(response){
    inc@dep1Out(request)(response)
  }]
}
