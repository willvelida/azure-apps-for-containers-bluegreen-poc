FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app
EXPOSE 80
EXPOSE 443

WORKDIR /src
COPY *.sln ./
COPY HelloBlueGreen.csproj, HelloBlueGreen/
RUN dotnet restore HelloBlueGreen/HelloBlueGreen.csproj
COPY . .
WORKDIR /src/HelloBlueGreen
RUN dotnet build -c Release -o /app

FROM build AS publish
RUN dotnet publish "HelloBlueGreen.csproj" -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "HelloBlueGreen.dll"]