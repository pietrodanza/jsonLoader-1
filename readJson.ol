include "json_utils.iol"
include "string_utils.iol"
include "console.iol"
include "file.iol"
include "exec.iol"
include "InterfaceAPI.iol"
include "metajolie.iol"
include "time.iol"

outputPort Jocker {
Location: "socket://localhost:8008"
Protocol: sodep
Interfaces: InterfaceAPI
}

main
{
  file.filename = "containerArch.json";
  file.format = "json";
  readFile@File(file)(responseC);

  valueToPrettyString@StringUtils(responseC)(pretty);

  fileM.filename = "microservicesArch.json";
  fileM.format = "json";
  readFile@File(fileM)(responseM);

  global.freshname = new;
  for ( i=0, i< #responseC.containers, i++ ) {
    rqCnt.name = global.freshname +"-CNT-"+(i+1);
    cmd[i].name = rqCnt.name;
    container -> responseC.containers[i];

    launcherFile.filename = "launch"+i+".sh";
    launcherFile.content = "sh /microservice/get_dependencies.sh > /dependencies.iol\n";
    for ( j=0, j< #container.microservices, j++ ) {
      nameMicroservice = container.microservices[j].name[0];

      dockerFile.filename = "dockerFile" + nameMicroservice;
      dockerFile.content = "" +
      "FROM jolielang/jolie-docker-deployer\n"+
      "COPY "+ nameMicroservice+ ".ol " + nameMicroservice + ".ol\n";

      cmd[i].path = "tar -cf " + rqCnt.name + ".tar " +
                    dockerFile.filename + " " +
                    launcherFile.filename + " ";
      cmd[i].path += nameMicroservice+".ol ";

      if( j == #container.microservices-1 ) {
        launcherFile.content += "jolie " + nameMicroservice + ".ol "
      }else{
        launcherFile.content += "jolie " + nameMicroservice + ".ol & "
      };

      for (z=0, z< #container.links, z++){
        nameLink = container.links[z].name[0];
        for (l=0, l<#responseM.links, l++){
          linkToCompare -> responseM.links[l];
          if( nameLink == linkToCompare.name[0]) {
            if( nameMicroservice == linkToCompare.inputMicroservice[0].name[0] ) {
                //salvare indirizzo --MANCA CONTROLLO PORT
                port= 9000+l;
                dockerFile.content += "EXPOSE " + port + "\n";

                rq.filename = nameMicroservice +".ol";
                rq.name.name = "";
                getMetaData@MetaJolie( rq )( metadata );
                locationInputPort = metadata.input[0].location[0];
                stringToSplit = locationInputPort;
                stringToSplit.regex = ":";
                split@StringUtils(stringToSplit)(splitResult);
                portInput = splitResult.result[2];

                println@Console( nameMicroservice + " " + portInput )();

                rqCnt.HostConfig.PortBindings.(port+"/tcp")._.HostPort = portInput;

                inMicroserviceArr.(nameMicroservice).port = portInput;
                inMicroserviceArr.(nameMicroservice).containerName = rqCnt.name;
                println@Console( nameMicroservice +" è del " + linkToCompare.name[0] + " è input" )()

            }else if( nameMicroservice == responseM.links[l].outputMicroservice[0].name[0] ) {

                portOut = responseM.links[l].outputMicroservice[0].portName[0];
                inputMicroName = responseM.links[l].inputMicroservice[0].name[0];
                portInputMicro = inMicroserviceArr.(inputMicroName).port;
                nameCntInputMicro = inMicroserviceArr.(inputMicroName).containerName;

                dockerFile.content += "ENV JDEP_LOCATION_"+ portOut +"="+
                "socket://" + nameCntInputMicro +":"+ portInputMicro + "\n";
                id = arr.(nameCntInputMicro).id;
                println@Console( "id: "+arr.(nameCntInputMicro).id )();
                println@Console( "name: "+nameCntInputMicro  )();

                rqCnt.HostConfig.Links[0] = id;

                println@Console( nameMicroservice +" è del " + linkToCompare.name[0] + " è output" )()
            }
          }
        }
      }

    };

    writeFile@File(launcherFile)( );
    dockerFile.content += "COPY " + launcherFile.filename + " / \n"+
    "CMD [\"/bin/bash\",\"/"+launcherFile.filename+"\"]";
    writeFile@File(dockerFile)( );
    exec@Exec(cmd[i].path[0])( response );

    fileTar.filename = cmd[i].name[0]+".tar";
    fileTar.format = "binary";
    readFile@File( fileTar)( rqImg.file);

    command = "rm " + launcherFile.filename + " && rm " + dockerFile.filename + " && rm "+fileTar.filename ;
    exec@Exec(command)( response );

    rqImg.t = global.freshname + ":latest";
    rqImg.dockerfile = dockerFile.filename;
    rqCnt.Image = global.freshname;
    crq.id = rqCnt.name;

    println@Console( "crq.id: "+crq.id )();


    build@Jocker( rqImg )( responseBuild );
    println@Console( "IMAGE CREATED: "+ rqImg.t )( );

    createContainer@Jocker( rqCnt )( responseCreate );
    println@Console( "CONTAINER CREATED: "+ rqCnt.name )( );

    startContainer@Jocker( crq )( responseStart );

    arr.(rqCnt.name).id = responseCreate.Id;

    println@Console( "id1: "+  arr.(rqCnt.name).id )();
    println@Console( "name1: "+rqCnt.name  )();


    sleep@Time(5000)()

  }
}



  /*
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

*/
