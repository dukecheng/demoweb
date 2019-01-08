#!/bin/sh -xe
codeBuildCommand="dotnet restore ./demoweb.sln && dotnet build ./demoweb.sln"
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "${codeBuildCommand}" 

imageBuildProject="./demoweb.csproj"
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "rm -rf ./obj/Docker/publish && dotnet publish ${imageBuildProject} -c Release -o ./obj/Docker/publish"

imagesName=demoweb
buildversion=1.0.${BUILD_NUMBER}
mkdir -p ${WORKSPACE}/buildreport
echo "Image Version: ${imagesName}:${buildversion}    GIT COMMIT: $GIT_COMMIT    GIT_BRANCH:$GIT_BRANCH    GIT_URL:$GIT_URL" > ${WORKSPACE}/buildreport/buildversion.txt
docker build -t ${imagesName}:${buildversion} --file ${WORKSPACE}/Dockerfile ${WORKSPACE}

export IM_TAG=${buildversion} && docker-compose -f deploy.base.yml -f deploy.Development.yml config > docker-stack.yml 
docker stack deploy --with-registry-auth -c docker-stack.yml demoweb 
