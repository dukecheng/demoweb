# demoweb
asp.net core demo web



asp.net core linux Docker部署


1. Linux系统  Debian 9 9.x

2. Docker环境  Docker安装 & 初始化Docker环境 针对国内的情况

3. Docker镜像 提前准备好.net core & 打包到docker镜像 & docker运行起来

4. Docker部署 程序更新发布，重新部署


环境准备:
1. debian 9.x/ubuntu 16.x的linux系统
2. 使用中科大源替换系统的源, 用来加快下载的速度
     ubuntu: https://lug.ustc.edu.cn/wiki/mirrors/help/ubuntu
     debian: https://lug.ustc.edu.cn/wiki/mirrors/help/debian
3. 安装docker : https://docs.docker.com/install/linux/docker-ce/debian/#install-docker-ce-1
     docker安装的时候 源要换为中科大的，会加快速度, http://mirrors.ustc.edu.cn/help/docker-ce.html
4. docker使用中科大的镜像代理:  https://lug.ustc.edu.cn/wiki/mirrors/help/docker



docker run --rm \
-v ~/.dotnet:/root/.dotnet \
-v ~/.nuget:/root/.nuget \
-v $(pwd):/src \
--workdir /src \
dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 \
bash -c "dotnet restore ./demoweb.sln && rm -rf ./obj/Docker/publish && dotnet publish ./demoweb.csproj -c Release -o ./obj/Docker/publish"

docker build -t ./Dockerfile .


export IM_TAG=ver_1 \
&& docker-compose -f deploy.base.yml -f deploy.Production.yml config > docker-stack.yml \
&& docker stack deploy --with-registry-auth -c docker-stack.yml demo

#deploy.base.yml 
version: '3'

services:
  web:
    image: app:${IM_TAG-latest}
    networks:
      - appnet
    volumes:
      - /var/log:/var/log
      - /data/app_data:/app/data
networks:
  appnet:

#deploy.Production.yml
services:
  web:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
    ports:
      - 8080:80  

#Dockerfile
FROM dukecheng/aspnetcore:aspnetcore-runtime-2.2.0
ARG source
WORKDIR /app
EXPOSE 80
COPY ${source:-obj/Docker/publish} .
ENTRYPOINT ["dotnet", "Gmandarin.FrontWeb.dll"]


#nginx.conf
server {
    listen        80;
    server_name   _;
    location / {
        proxy_pass         http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}

