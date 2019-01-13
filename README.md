# ASP NETCORE + DOCKER + JENKINS自动化部署说明

## 初始化debian 9.x系统(国内环境)
用中科大源替换系统默认的源
```
wget https://mirrors.ustc.edu.cn/repogen/conf/debian-http-4-stretch -O /etc/apt/sources.list && \
apt-get update
```

## 安装docker环境
```
sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common -y && \
 curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - && \
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable" && \
sudo sed -i 's/download.docker.com/mirrors.ustc.edu.cn\/docker-ce/g' /etc/apt/sources.list && \
sudo apt-get update && \
sudo apt-get install docker-ce -y && \
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
sudo chmod +x /usr/local/bin/docker-compose && \
clear && echo “DOCKER VERSION: ”&& docker version && \
echo “DOCKER COMPOSE VERSION:” &&  docker-compose version
```
配置中科大docker hub代理
```
cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF

//启用新的镜像代理
service docker restart 
```

初始化单节点的docker swarm集群
```
docker swarm init
--查看集群节点列表, 确认集群创建成功
docker node ls
//output:
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
xxxxxxx                   *   dotnetbuilder       Ready               Active              Leader              18.09.1
```

## ASP NETCORE应用构建，发布，镜像打包
### restore & build
```
export codeBuildCommand="dotnet restore ./demoweb.sln && dotnet build ./demoweb.sln" && \
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "${codeBuildCommand}" 
```
### publish
```
export imageBuildProject="./demoweb.csproj" && \
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "rm -rf ./obj/Docker/publish && dotnet publish ${imageBuildProject} -c Release -o ./obj/Docker/publish"
```

### app docker image build
```
docker build -t demoweb:1.0.demo.1 --file Dockerfile .
```

### run app with docker
```
export IM_TAG=1.0.demo.1 && docker-compose -f deploy.base.yml -f deploy.Development.yml config > docker-stack.yml 
docker stack deploy --with-registry-auth -c docker-stack.yml demoweb 
```




## Jenkins安装与配置

### 通过docker启动jenkins
```
mkdir -p /var/jenkins_home && \
chmod +777 /var/jenkins_home

docker run -d -it --name jenkins -v /var/jenkins_home:/var/jenkins_home -p 8080:8080 jenkins/jenkins:lts

防火墙开启 8080端口, 允许外部访问
```
### 配置jenkins插件
从SCM下载代码： git
SSH连接编译节点: ssh slave

### Jenkins Slave(子节点配置)
```
//jenkins是基于java开发的，需要安装jdk

sudo apt install openjdk-8-jdk -y
```

### 创建freestyle job并配置自动构建
```
#!/bin/sh -xe
codeBuildCommand="dotnet restore ./demoweb.sln && dotnet build ./demoweb.sln"
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "${codeBuildCommand}" 

imageBuildProject="./demoweb.csproj"
docker run -t --rm -v ~/.dotnet:/root/.dotnet -v ~/.nuget:/root/.nuget  -v ${WORKSPACE}:/src --workdir /src dukecheng/aspnetcore:aspnetcore-sdk-2.2.100 bash -c "rm -rf ./obj/Docker/publish && dotnet publish ${imageBuildProject} -c Release -o ./obj/Docker/publish"

imagesName=demoweb
buildversion=1.0.${BUILD_NUMBER}
mkdir -p ${WORKSPACE}/buildreport
echo "Image Version: ${imagesName}:${buildversion}
    GIT COMMIT: $GIT_COMMIT
    GIT_BRANCH:$GIT_BRANCH
    GIT_URL:$GIT_URL" > ${WORKSPACE}/buildreport/buildversion.txt
docker build -t ${imagesName}:${buildversion} --file ${WORKSPACE}/Dockerfile ${WORKSPACE}

export IM_TAG=${buildversion} && docker-compose -f deploy.base.yml -f deploy.Development.yml config > docker-stack.yml 
docker stack deploy --with-registry-auth -c docker-stack.yml demoweb 

```

## end

