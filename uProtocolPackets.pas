unit uProtocolPackets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDeviceModels;

type
  TParsedDevicePacket = record
    IsValid: Boolean;
    DeviceID: string;
    Temperature: Double;
    RPM: Integer;
    Voltage: Double;
    Current: Double;
    SignalQuality: Integer;
    ErrorCount: Integer;
    ErrorMessage: string;
  end;

  TProtocolPacketBuilder = class
  public
    class function BuildDevicePacket(const ADeviceID: string;
      const ADiagnostics: TDiagnosticValues; AErrorCount: Integer): string;
    class function TryParseDevicePacket(const APacket: string;
      out AParsedPacket: TParsedDevicePacket): Boolean;
  end;

implementation

class function TProtocolPacketBuilder.BuildDevicePacket(const ADeviceID: string;
  const ADiagnostics: TDiagnosticValues; AErrorCount: Integer): string;
var
  FormatSettings: TFormatSettings;
begin
  FormatSettings := DefaultFormatSettings;
  FormatSettings.DecimalSeparator := '.';
  Result := Format('$DEV,%s,TEMP,%.1f,RPM,%d,VOLT,%.1f,CURR,%.1f,SIGNAL,%d,ERR,%d#',
    [ADeviceID, ADiagnostics.Temperature, ADiagnostics.RPM,
     ADiagnostics.Voltage, ADiagnostics.Current,
     ADiagnostics.SignalQuality, AErrorCount], FormatSettings);
end;

class function TProtocolPacketBuilder.TryParseDevicePacket(const APacket: string;
  out AParsedPacket: TParsedDevicePacket): Boolean;
var
  Body: string;
  Parts: TStringList;
  FormatSettings: TFormatSettings;

  function ReadTokenValue(const AToken: string): string;
  var
    Index: Integer;
  begin
    Result := '';
    for Index := 0 to Parts.Count - 2 do
      if SameText(Parts[Index], AToken) then
      begin
        Result := Parts[Index + 1];
        Exit;
      end;
  end;

begin
  AParsedPacket.IsValid := False;
  AParsedPacket.DeviceID := '';
  AParsedPacket.Temperature := 0;
  AParsedPacket.RPM := 0;
  AParsedPacket.Voltage := 0;
  AParsedPacket.Current := 0;
  AParsedPacket.SignalQuality := 0;
  AParsedPacket.ErrorCount := 0;
  AParsedPacket.ErrorMessage := 'Invalid packet.';
  Result := False;

  if (Length(APacket) < 6) or (APacket[1] <> '$') or (APacket[Length(APacket)] <> '#') then
  begin
    AParsedPacket.ErrorMessage := 'Packet must start with $ and end with #.';
    Exit;
  end;

  Body := Copy(APacket, 2, Length(APacket) - 2);
  Parts := TStringList.Create;
  try
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := ',';
      Parts.DelimitedText := Body;

      if (Parts.Count < 14) or (not SameText(Parts[0], 'DEV')) then
      begin
        AParsedPacket.ErrorMessage := 'Packet header is not a DEV packet.';
        Exit;
      end;

      FormatSettings := DefaultFormatSettings;
      FormatSettings.DecimalSeparator := '.';
      AParsedPacket.DeviceID := Parts[1];
      AParsedPacket.Temperature := StrToFloat(ReadTokenValue('TEMP'), FormatSettings);
      AParsedPacket.RPM := StrToInt(ReadTokenValue('RPM'));
      AParsedPacket.Voltage := StrToFloat(ReadTokenValue('VOLT'), FormatSettings);
      AParsedPacket.Current := StrToFloat(ReadTokenValue('CURR'), FormatSettings);
      AParsedPacket.SignalQuality := StrToInt(ReadTokenValue('SIGNAL'));
      AParsedPacket.ErrorCount := StrToInt(ReadTokenValue('ERR'));
      AParsedPacket.IsValid := True;
      AParsedPacket.ErrorMessage := '';
      Result := True;
    except
      on E: Exception do
      begin
        AParsedPacket.IsValid := False;
        AParsedPacket.ErrorMessage := E.Message;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

end.
