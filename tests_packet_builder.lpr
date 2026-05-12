program tests_packet_builder;

{$mode objfpc}{$H+}

uses
  SysUtils, uDeviceModels, uProtocolPackets;

procedure AssertEquals(const AExpected, AActual, AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('%s Expected "%s", got "%s".',
      [AMessage, AExpected, AActual]);
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

var
  Diagnostics: TDiagnosticValues;
  Packet: string;
  Parsed: TParsedDevicePacket;
begin
  Diagnostics.Temperature := 58.3;
  Diagnostics.RPM := 1200;
  Diagnostics.Voltage := 12.8;
  Diagnostics.Current := 7.4;
  Diagnostics.SignalQuality := 94;
  Diagnostics.PacketLoss := 0.2;
  Diagnostics.AlarmState := asNormal;
  Diagnostics.LastPacketTime := Now;

  Packet := TProtocolPacketBuilder.BuildDevicePacket('AHD_570', Diagnostics, 2);
  AssertEquals('$DEV,AHD_570,TEMP,58.3,RPM,1200,VOLT,12.8,CURR,7.4,SIGNAL,94,ERR,2#',
    Packet, 'Packet builder mismatch.');

  AssertTrue(TProtocolPacketBuilder.TryParseDevicePacket(Packet, Parsed),
    'Packet parser rejected a valid packet: ' + Parsed.ErrorMessage);
  AssertEquals('AHD_570', Parsed.DeviceID, 'Parsed device id mismatch.');
  AssertTrue(Parsed.RPM = 1200, 'Parsed RPM mismatch.');
  AssertTrue(not TProtocolPacketBuilder.TryParseDevicePacket('bad-packet', Parsed),
    'Packet parser accepted an invalid packet.');

  WriteLn('All packet builder/parser tests passed.');
end.
