unit uNetworkSimulation;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TNetworkSimulationMode = (nsmNone, nsmTcpServer, nsmUdpBroadcast);

  TNetworkSimulation = class
  private
    FMode: TNetworkSimulationMode;
    FTcpPort: Integer;
    FUdpPort: Integer;
    FBroadcastAddress: string;
  public
    constructor Create;
    procedure Stop;
    function StartTcpServerSimulation(APort: Integer): string;
    function StartUdpBroadcastSimulation(const AAddress: string; APort: Integer): string;
    function BuildTransmitLog(const APacket: string): string;
    property Mode: TNetworkSimulationMode read FMode;
  end;

function NetworkSimulationModeToText(AMode: TNetworkSimulationMode): string;

implementation

function NetworkSimulationModeToText(AMode: TNetworkSimulationMode): string;
begin
  case AMode of
    nsmNone: Result := 'Local simulation';
    nsmTcpServer: Result := 'TCP server simulation';
    nsmUdpBroadcast: Result := 'UDP broadcast simulation';
  else
    Result := 'Unknown';
  end;
end;

constructor TNetworkSimulation.Create;
begin
  inherited Create;
  FMode := nsmNone;
  FTcpPort := 15020;
  FUdpPort := 15021;
  FBroadcastAddress := '239.10.10.20';
end;

procedure TNetworkSimulation.Stop;
begin
  FMode := nsmNone;
end;

function TNetworkSimulation.StartTcpServerSimulation(APort: Integer): string;
begin
  if APort <= 0 then
    raise Exception.Create('Invalid TCP simulation port.');
  FTcpPort := APort;
  FMode := nsmTcpServer;
  Result := Format('TCP server simulation armed on port %d (no real socket opened)', [FTcpPort]);
end;

function TNetworkSimulation.StartUdpBroadcastSimulation(const AAddress: string;
  APort: Integer): string;
begin
  if APort <= 0 then
    raise Exception.Create('Invalid UDP simulation port.');
  if Trim(AAddress) = '' then
    raise Exception.Create('Invalid UDP broadcast address.');
  FBroadcastAddress := AAddress;
  FUdpPort := APort;
  FMode := nsmUdpBroadcast;
  Result := Format('UDP broadcast simulation armed for %s:%d (no real socket opened)',
    [FBroadcastAddress, FUdpPort]);
end;

function TNetworkSimulation.BuildTransmitLog(const APacket: string): string;
begin
  case FMode of
    nsmTcpServer:
      Result := Format('TCP-SIM:%d %s', [FTcpPort, APacket]);
    nsmUdpBroadcast:
      Result := Format('UDP-SIM:%s:%d %s', [FBroadcastAddress, FUdpPort, APacket]);
  else
    Result := APacket;
  end;
end;

end.
