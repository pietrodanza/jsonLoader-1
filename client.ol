include "console.iol"
include "dependencies.iol"

interface mainInterface {
RequestResponse:
  stampa(string)(void),
  incNum(int)(int)
OneWay:
}

outputPort mainOut {
Location: "socket://172.17.0.3:8001"
Protocol: sodep
Interfaces: mainInterface
}
main
{
  stampa@mainOut("Stampa")();
  incNum@mainOut(5)(response);
  println@Console( response )()
}
