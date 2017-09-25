include "json_utils.iol"
include "string_utils.iol"
include "console.iol"
include "file.iol"
include "exec.iol"
include "InterfaceAPI.iol"

outputPort Jocker {
Location: "socket://localhost:8008"
Protocol: sodep
Interfaces: InterfaceAPI
}

main
{
file.filename = "System.json";
file.format = "json";
readFile@File(file)(response);

valueToPrettyString@StringUtils(response)(pretty);
for (i=0, i< #response.microservices, i++) {
    name = response.microservices[i].name[0];
    dockerFile.filename = "dockerFile" + name;
    dockerFile.content = "" +
    "FROM jolielang/jolie-docker-deployer\n"+
    "COPY " +name+".ol main.ol\n";
    if( response.microservices[i].inputPort[0].channel != null ) {
        inputChannel = response.microservices[i].inputPort[0].channel;
        for ( j=0, j<#response.channels, j++ ) {
            if( response.channels[j].num == inputChannel) {
                portIn = response.channels[j].port;
                dockerFile.content += "EXPOSE " + portIn + "\n"
            }
        }
    } else {
      println@Console("no inputport")()
    };

    for ( k=0, k<#response.microservices[i].outputPort, k++ ) {
      nameOutput = response.microservices[i].outputPort[k].name;
      numChannel = response.microservices[i].outputPort[k].channel;
      for ( z=0, z<#response.channels, z++ ) {
          if( response.channels[z].num == numChannel) {
              portOut = response.channels[z].port;
              cmd[i].portOut = portOut;
              inputService = response.channels[z].inputMicroservice;
              cmd[i].inputService = inputService;
              dockerFile.content += "ENV JDEP_LOCATION_"+ nameOutput +"="+
              "socket://" + inputService +"-cnt:"+ portOut
          }
      }
    };
    writeFile@File( dockerFile )( );
    cmd[i].path = "tar -cf "+name+".tar dockerFile"+name+ " " + name+".ol";
    cmd[i].name = name
  };

  for ( i=#cmd-1, i>=0, i--) {
    exec@Exec(cmd[i].path[0])( response );

    //Write file tar
    fileTar.filename = cmd[i].name[0]+".tar";
    fileTar.format = "binary";
    readFile@File( fileTar)( rqImg.file);

    //Set images
    rqImg.t = cmd[i].name[0] + ":latest";
    rqImg.dockerfile = "dockerFile"+cmd[i].name[0];
    //Set container
    rqCnt.name = cmd[i].name[0]+"-cnt";
    if( cmd[i].portOut != null ) {
      rqCnt.HostConfig.PortBindings.(cmd[i].portOut)._.HostIp = cmd[i].inputService+"-cnt";
    	rqCnt.HostConfig.PortBindings.(cmd[i].portOut)._.HostPort = cmd[i].portOut+""
      //rqCnt.NetworkingConfig.EndpointsConfig.isolated_nw.Links = cmd[i].inputService + "-cnt:" + cmd[i].portOut
    };
    rqCnt.Image = cmd[i].name[0];
    crq.id = rqCnt.name[0];


    build@Jocker( rqImg )( response );
    println@Console( "IMAGE CREATED: "+ rqImg.t )( );

    createContainer@Jocker( rqCnt )( response );
    println@Console( "CONTAINER CREATED: "+ rqCnt.name )( );

    startContainer@Jocker( crq )( response );
    println@Console( "CONTAINER STARTED: "+ crq.id )( )
  }


}
