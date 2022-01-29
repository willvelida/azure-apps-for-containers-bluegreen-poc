FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY ["HelloBlueGreen.csproj", "HelloBlueGreen/"]
RUN dotnet restore "HelloBlueGreen/HelloBlueGreen.csproj"

COPY . .
RUN dotnet publish "HelloBlueGreen.csproj" -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "HelloBlueGreen.dll"]