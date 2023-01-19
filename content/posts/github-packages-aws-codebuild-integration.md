--- 
draft: true
date: 2023-01-13T21:48:16+01:00
title: "Github packages and AWS codeBuild integration"
description: "A short guide on how to configure github packages with AWS codeBuild"
slug: ""
authors: [ "A.G. Tony Barletta "]
tags: ["cloud", "AWS", "Github", "Maven" ]
categories: ["posts"]
---

Github Pacakges is a handy service to create your own private package repository. But how can you use it in a CICD pipeline ?

In this short guide We are going to integrate our maven repository with AWS CICD services.

To help the steps I created an [hello world maven project](code.zip) called `app` that depends on two dependencies `dep1` and `dep2`. The app is packaged as a jar and the Main class prints its version and the versions of the two dependencies.


## Create Github packages maven repository

To have a functional private maven repository hosted on github packages we have to configure 2 things. The Github repository itself and maven settings files.

The first step is already done when we create a new repository. Github provide us with the service needed to handle packages using maven.
All the packages we will publish are going to refer to this repository.

Our local maven version is going to connect to our private maven repository using a private token. We will to use it in the next steps but we will generate it now.

To generate the token from you github homepage go to setting -> developer settings -> Personal access tokens -> Tokens (classic).

At this point click on Generate new token -> Generate new token(Classic).

Enter a note, select permisisons `write:packages` and `read:packages` and click Generate token.

Now that we have a private maven repository we have to instruct maven to use it for packages that are not in the central maven repository.

Maven allows to set servers and repositories using an `settings.xml` file. For global configuration can be place under `~/.m2/settings.xml`. We are going to pass it in the command line arguments.

settings.xml
```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                      http://maven.apache.org/xsd/settings-1.0.0.xsd">

  <profiles>
    <profile>
      <id>dev</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo1.maven.org/maven2</url>
        </repository>
        <repository>
          <id>github</id>
          <url>$GITHUB_URL</url>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>

  <servers>
    <server>
      <id>github</id>
      <username>$GITHUB_USERNAME</username>
      <password>$GITHUB_TOKEN</password>
    </server>
  </servers>
</settings>
```

To make is work in our local environment we have to make a copy of this file, e.g. `settings_local.xml` and subtitute `$GITHUB_URL`, `$GITHUB_USERNAME` and `$GITHUB_TOKEN` accordingly.

- `$GITHUB_URL` contain the url of the maven repository, for example `https://maven.pkg.github.com/agtonybarletta/private-maven-repository-example`.
- `$GITHUB_USERNAME` contain the our github username.
- `$GITHUB_TOKEN` contains the token generated

Having done this we can test our own private maven repository. We can deploy a package using the command
```bash
mvn -s settings_local.xml -Ddev -DaltDeploymentRepository=$GITHUB_URL deploy
```
`$GITHUB_URL` must be substitute as above.

> NOTE: We use `-DaltDeploymentRepository` parameter to leave the file `pom.xml` untouched.
> A better way to handle this situation is to modify `pom.xml` and use the tag `<distributionManagement>`

We can repeat this process for every package we want to deploy to our repository.

> Note that in settings.xml and settings_local.xml we setup this repository for the dev environment. We are ignoring multiple environment configurations in this tutorial.

![packages](images/packages.png)

## AWS CodeBuild


Our private maven repository can be used in the build phase of AWS CodePipeline.

For the sake of semplicity we are not goint to show how to setup a AWS CodePipeline pipeline, but we will concentrate on the build phase only.

We will assume our app has the following structure

```plain
$ tree .
.
├── app
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   └── it
│       │   │       └── agtb
│       │   │           └── app
│       │   │               └── App.java
│       │   └── resources
│       │       └── app.properties
│       └── test
│           └── java
│               └── it
│                   └── agtb
│                       └── app
│                           └── AppTest.java
├── buildspec.yml
└── settings.xml
```

To make the this easier we are going to define the building step using  the file `buildspec.yml`.

buildspec.yml
```yml
version: 0.1

phases:
  pre_build:
    commands:
      - echo Build completed on `date`
      - sed -i "s@\$GITHUB_URL@$GITHUB_URL@g" settings.xml
      - sed -i "s@\$GITHUB_USERNAME@$GITHUB_USERNAME@g" settings.xml
      - sed -i "s@\$GITHUB_TOKEN@$GITHUB_TOKEN@g" settings.xml
  build:
    commands:
      - cd app/ && mvn -s ../settings.xml -DaltDeploymentRepositery=github::default::$GITHUB_URL -Pdev package
  post_build:
    commands:
      java -jar app/target/app-*.jar
artifacts:
  files:
    - app/target/app-*.jar
```

The environment variable will be set in pipeline building phase and will be provided automatically by the AWS codePipeline.

To substitute the environment variables in the settings.xml file we use the `sed` command.

For example command `sed -i "s@\$GITHUB_URL@$GITHUB_URL@g" settings.xml` will substitute the string `$GITHUB_URL` in the `settings.xml` file with the evironament variable `$GITHUB_URL`. This evnironment variable will be set in the Environment Variable section of Pipeline building.

![env_varialbe](images/env_variables.png)

In the `post_build` phase we run the jar to check our application using the logs. In a real case scenario this step will not be run.

## Results

When we trigger our CICD pipeline, the build step will build the source code using dependencies that are in our private maven repository.

```log
[Container] 2023/01/13 15:40:12 Running command cd app/ && mvn -s ../settings.xml -DaltDeploymentRepositery=github::default::$GITHUB_URL -Pdev package
[INFO] Scanning for projects...
[INFO] 
[INFO] --------------------------< it.agtb.app:app >---------------------------
[INFO] Building app 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/org/apache/maven/plugins/maven-resources-plugin/3.0.2/maven-resources-plugin-3.0.2.pom


...


Downloading from github: https://maven.pkg.github.com/agtonybarletta/private-maven-repository-example/it/agtb/app/dep1/dep1/1.0.0/dep1-1.0.0.pom
Progress (1): 2.7 kB
                    
Downloading from github: https://maven.pkg.github.com/agtonybarletta/private-maven-repository-example/it/agtb/app/dep2/dep2/1.0.0/dep2-1.0.0.pom
Progress (1): 2.6 kB
                    
...

                            
[INFO] Building jar: /codebuild/output/src899861325/src/app/target/app-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  11.358 s
[INFO] Finished at: 2023-01-13T15:40:29Z
[INFO] ------------------------------------------------------------------------

[Container] 2023/01/13 15:40:29 Phase complete: BUILD State: SUCCEEDED
[Container] 2023/01/13 15:40:29 Phase context status code:  Message: 
[Container] 2023/01/13 15:40:29 Entering phase POST_BUILD
[Container] 2023/01/13 15:40:29 Running command java -jar app/target/app-*.jar
Hello World from App with version: 1.0.0
Message from Dep1 Hello World from Dependency1 fn with version: 1.0.0
Message from Dep2 Hello World from Dependency2 fn with version: 1.0.0
```
