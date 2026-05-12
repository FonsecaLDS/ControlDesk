unit uDeviceSimulator;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, uDeviceModels;

type
  TApplicationState = (appDisconnected, appConnected, appSimulating, appError);

  TDeviceSimulator = class
  private
    FState: TApplicationState;
    FDiagnostics: TDiagnosticValues;
    procedure SetDefaultDiagnostics;
  public
    constructor Create;
    procedure Connect;
    procedure Disconnect;
    procedure StartSimulation;
    procedure StopSimulation;
    procedure MarkError;
    function GenerateDiagnostics(ADevice: TDevice): TDiagnosticValues;
    property State: TApplicationState read FState;
    property Diagnostics: TDiagnosticValues read FDiagnostics;
  end;

function ApplicationStateToText(AState: TApplicationState): string;

implementation

function ClampInt(AValue, AMin, AMax: Integer): Integer;
begin
  Result := AValue;
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function ApplicationStateToText(AState: TApplicationState): string;
begin
  case AState of
    appDisconnected: Result := 'Disconnected';
    appConnected: Result := 'Connected';
    appSimulating: Result := 'Simulating';
    appError: Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

constructor TDeviceSimulator.Create;
begin
  inherited Create;
  Randomize;
  FState := appDisconnected;
  SetDefaultDiagnostics;
end;

procedure TDeviceSimulator.SetDefaultDiagnostics;
begin
  FDiagnostics.Temperature := 0;
  FDiagnostics.RPM := 0;
  FDiagnostics.Voltage := 0;
  FDiagnostics.Current := 0;
  FDiagnostics.SignalQuality := 0;
  FDiagnostics.PacketLoss := 0;
  FDiagnostics.AlarmState := asNormal;
  FDiagnostics.LastPacketTime := 0;
end;

procedure TDeviceSimulator.Connect;
begin
  if FState = appSimulating then
    raise Exception.Create('Stop simulation before reconnecting.');
  if FState = appConnected then
    raise Exception.Create('Device network is already connected.');
  FState := appConnected;
end;

procedure TDeviceSimulator.Disconnect;
begin
  if FState = appDisconnected then
    raise Exception.Create('Device network is already disconnected.');
  FState := appDisconnected;
  SetDefaultDiagnostics;
end;

procedure TDeviceSimulator.StartSimulation;
begin
  if FState = appSimulating then
    raise Exception.Create('Simulation is already running.');
  if FState <> appConnected then
    raise Exception.Create('Connect before starting simulation.');
  FState := appSimulating;
end;

procedure TDeviceSimulator.StopSimulation;
begin
  if FState <> appSimulating then
    raise Exception.Create('Simulation is not running.');
  FState := appConnected;
end;

procedure TDeviceSimulator.MarkError;
begin
  FState := appError;
end;

function TDeviceSimulator.GenerateDiagnostics(ADevice: TDevice): TDiagnosticValues;
var
  BaseTemp: Double;
begin
  if ADevice = nil then
    raise Exception.Create('No device selected for simulation.');

  BaseTemp := 44 + Random(220) / 10;
  if ADevice.Location = 'Engine Room' then
    BaseTemp := BaseTemp + 12;

  FDiagnostics.Temperature := BaseTemp;
  FDiagnostics.RPM := 650 + Random(1850);
  FDiagnostics.Voltage := 11.8 + Random(28) / 10;
  FDiagnostics.Current := 4.0 + Random(190) / 10;
  FDiagnostics.SignalQuality := ClampInt(72 + Random(29) - ADevice.ErrorCount * 2, 30, 100);
  FDiagnostics.PacketLoss := Random(80) / 10;

  if (ADevice.Status = dsError) or (FDiagnostics.PacketLoss > 6.5) then
    FDiagnostics.AlarmState := asActive
  else if (ADevice.Status = dsWarning) or (FDiagnostics.Temperature > 68) then
    FDiagnostics.AlarmState := asAcknowledged
  else
    FDiagnostics.AlarmState := asNormal;

  FDiagnostics.LastPacketTime := Now;
  ADevice.LastSeen := FDiagnostics.LastPacketTime;
  if FDiagnostics.PacketLoss > 7.0 then
    Inc(ADevice.ErrorCount);

  Result := FDiagnostics;
end;

end.
