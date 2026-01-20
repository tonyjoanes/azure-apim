FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["SampleAPI.csproj", "./"]
RUN dotnet restore "SampleAPI.csproj"
COPY . .
RUN dotnet build "SampleAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SampleAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SampleAPI.dll"]
