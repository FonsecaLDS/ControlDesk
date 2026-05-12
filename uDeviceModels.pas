unit uDeviceModels;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs;

type
  TDeviceStatus = (dsOffline, dsOnline, dsWarning, dsError);
  TAlarmState = (asNormal, asActive, asAcknowledged);

  TDiagnosticValues = record
    Temperature: Double;
    RPM: Integer;
    Voltage: Double;
    Current: Double;
    SignalQuality: Integer;
    PacketLoss: Double;
    AlarmState: TAlarmState;
    LastPacketTime: TDateTime;
  end;

  TDevice = class
  public
    ItemID: string;
    DeviceName: string;
    DeviceType: string;
    Location: string;
    Protocol: string;
    Address: string;
    Status: TDeviceStatus;
    FirmwareVersion: string;
    LastSeen: TDateTime;
    ErrorCount: Integer;
    Model: string;
    Notes: string;
    constructor Create(const AItemID, ADeviceName, ADeviceType, ALocation,
      AProtocol, AAddress: string; AStatus: TDeviceStatus;
      const AFirmwareVersion, AModel, ANotes: string; AErrorCount: Integer);
  end;

function DeviceStatusToText(AStatus: TDeviceStatus): string;
function AlarmStateToText(AAlarmState: TAlarmState): string;
procedure LoadDemoDevices(ADevices: TObjectList);

implementation

constructor TDevice.Create(const AItemID, ADeviceName, ADeviceType, ALocation,
  AProtocol, AAddress: string; AStatus: TDeviceStatus;
  const AFirmwareVersion, AModel, ANotes: string; AErrorCount: Integer);
begin
  inherited Create;
  ItemID := AItemID;
  DeviceName := ADeviceName;
  DeviceType := ADeviceType;
  Location := ALocation;
  Protocol := AProtocol;
  Address := AAddress;
  Status := AStatus;
  FirmwareVersion := AFirmwareVersion;
  Model := AModel;
  Notes := ANotes;
  ErrorCount := AErrorCount;
  LastSeen := Now - (Random(240) / 1440);
end;

function DeviceStatusToText(AStatus: TDeviceStatus): string;
begin
  case AStatus of
    dsOffline: Result := 'Offline';
    dsOnline: Result := 'Online';
    dsWarning: Result := 'Warning';
    dsError: Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

function AlarmStateToText(AAlarmState: TAlarmState): string;
begin
  case AAlarmState of
    asNormal: Result := 'Normal';
    asActive: Result := 'Active';
    asAcknowledged: Result := 'Acknowledged';
  else
    Result := 'Unknown';
  end;
end;

procedure LoadDemoDevices(ADevices: TObjectList);
begin
  ADevices.Clear;
  ADevices.Add(TDevice.Create('AHD_570', 'Display Panel AHD-570', 'Display Panel',
    'Bridge', 'NMEA-0183', 'BRG-01', dsOnline, '2.4.7', 'AHD-570',
    'Primary bridge monitoring display with multi-page alarm overview.', 0));
  ADevices.Add(TDevice.Create('LCU_210', 'Control Unit LCU', 'Logic Control Unit',
    'Bridge', 'Modbus RTU', 'BRG-02', dsOnline, '1.9.3', 'LCU-210',
    'Local control unit for navigation and lighting relay groups.', 1));
  ADevices.Add(TDevice.Create('ALM_DISP', 'Alarm Display', 'Alarm Annunciator',
    'Alarm System', 'CANopen', 'ALM-01', dsWarning, '3.1.2', 'AAD-320',
    'Dedicated alarm display, warning state caused by simulated packet loss.', 2));
  ADevices.Add(TDevice.Create('SNS_MOD', 'Sensor Module', 'Remote I/O',
    'Alarm System', 'CANopen', 'ALM-02', dsOnline, '2.0.5', 'RSM-88',
    'Remote sensor acquisition module for alarm contact inputs.', 0));
  ADevices.Add(TDevice.Create('ENG_CTRL', 'Engine Controller', 'Engine Controller',
    'Engine Room', 'J1939', 'ENG-01', dsOnline, '5.8.1', 'ECU-M450',
    'Simulated propulsion controller publishing RPM and current load.', 0));
  ADevices.Add(TDevice.Create('TMP_SENS', 'Temperature Sensor', 'Sensor',
    'Engine Room', '1-Wire Gateway', 'ENG-02', dsWarning, '1.2.0', 'TS-40',
    'High ambient temperature warning used for diagnostic demonstration.', 3));
  ADevices.Add(TDevice.Create('VLT_MON', 'Voltage Monitor', 'Power Monitor',
    'Engine Room', 'Modbus TCP', 'ENG-03', dsOffline, '4.0.4', 'VM-120',
    'Offline monitor included to demonstrate state handling and reporting.', 5));
end;

end.
