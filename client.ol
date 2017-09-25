include "console.iol"
include "dependencies.iol"

interface mainInterface {
RequestResponse:
  stampa(string)(void),
  incNum(int)(int)
OneWay:
}

outputPort mainOut {
Location: "socket://main-cnt:8001"
Protocol: sodep
Interfaces: mainInterface
}
main
{
  stampa@mainOut("Stampa")();
  incNum@mainOut(5)(response);
  println@Console( response )()
}
