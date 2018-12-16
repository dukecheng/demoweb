FROM dukecheng/aspnetcore:aspnetcore-runtime-2.2.0
ARG source
WORKDIR /app
EXPOSE 80
COPY ${source:-obj/Docker/publish} .
ENTRYPOINT ["dotnet", "demoweb.dll"]