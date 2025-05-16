# Dockerfile for FunC end Blueprint

This docker image should come in handy to run [toncli](https://github.com/disintar/toncli) with the [new tests support](https://github.com/disintar/toncli/blob/master/docs/advanced/func_tests_new.md).  
Setting it all up manually could be cumbersome otherwise.  
Inspired by [Dockerfile for FunC](https://hub.docker.com/r/trinketer22/func_docker/).  
Built on Ubuntu 22.04 so should be WSL docker compatible.
Mult-arch supported *x86_64 (amd64)* and *arm64/v8* **(M4 compatible!)**.  

## Set environment variables

`TARGET_PLATFORM` - *x86_64 (linux/amd64)* or *x86_64 (linux/arm64)*

`HOST_CODE_DIR` - mount local directory


## Build

 To build an image run: `docker build . -t ton-local [ optional --build-arg ]`  
 Where *ton-local* would be an image name.

 For arch supported *arm64/v8* run `docker build --platform=linux/arm64 . -t ton-local`

 Or run `docker compose build`
 
 In most cases that's it. 
 However, if you need something special, there are custom build arguments available.
 
 ### Custom build arguments
-   **TON_GIT** specifies git repo url to fetch sources from. [ton-blockchain](https://github.com/ton-blockchain/ton) by default.
-   **TON_BRANCH** specifies git branch to fetch from.
-   **BUILD_DEBUG** is self-explaintatory. By default *Release* binaries are built. Set *BUILD_DEBUG=1* to build debug binaries.
	
Example of building debug binaries from [ton-blockchain/ton](https://github.com/ton-blockchain/ton) testnet branch

```console
docker build . -t toncli-local \
--build-arg TON_GIT=https://github.com/ton-blockchain/ton \
--build-arg TON_BRANCH=testnet \
--build-arg BUILD_DEBUG=1
```

## Use

 You're going to need to pass your workdir like HOST_CODE_DIR from environment variable

### Creating project
 Run  
 
 ``` console
 docker run --rm -it -v ~/Dev:/code ton-local start --name test_project wallet 
 ```

 or

 ``` console
 docker run --rm -it -v ~/Dev:/code ton-local npm create ton@latest 
 ```
  
 ### Building
 
  Run  
  
  ``` console
  docker run --rm -it -v ~/Dev/test_project:/code ton-local build
  ```

  or

  ``` console
  docker run --rm -it -v ~/Dev/test_project:/code ton-local npx blueprint build
  ```
	
 ### Running tests
   
  ``` console
  docker run --rm -it -v ~/Dev/test_project:/code ton-local run_tests
  ``` 

  or

  ``` console
  docker run --rm -it -v ~/Dev/test_project:/code ton-local npx blueprint test
  ``` 

 ### Deploying contract
   Now here is the tricky part, if you use Toncli.  
   **Toncli** stores deployment info in it's config directory instead of your project directory.  
   So we're going to have to create another volume for that to persist.  
   
  Run
  ``` console
  docker run --rm -it \
  -v ~/Dev/test_project:/code \
  -v /path/to/toncli_conf_dir/:/root/.config \
  ton-local update_libs
  ```
  After that you should go through standard toncli initialization dialog and pass absolute paths to the binaries
-   /usr/local/bin/func
-   /usr/local/bin/fift
-   /usr/local/bin/lite-client
  
  Don't get confused those path's are inside the docker image and not your local system.  
  After that you should get an initialized toncli directory on your local system at */path/to/toncli_conf_dir/toncli*.  
  Looking like:
  
  ``` console
  config.ini
  fift-libs
  func-libs
  test-libs
  ``` 
  
  Now you can use it in the deploy or any other process like so.  
  
  Run  
  
  ``` console
  docker run --rm -it -v /path/to/project:/code -v /path/to/toncli_conf_dir/:/root/.config ton-local deploy --net testnet
  ```
  
  **project** directory would be created inside your local config dir with all the usefull deployment information


  With blueprint it's easier:

  ``` console
  docker run --rm -it -v ~/Dev/test_project:/code ton-local npx blueprint run
  ``` 

### General usage
 ``` console
 docker run --rm -it -v <code_volume> -v [optional config volume] <docker image name> <toncli | npm> <command you want to run>
 ```
