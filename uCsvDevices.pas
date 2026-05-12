unit uCsvDevices;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, uDeviceModels;

type
  TCsvDeviceImporter = class
  public
    class function ImportFromFile(const AFileName: string; ADevices: TObjectList;
      out AMessage: string): Boolean;
  end;

implementation

function ParseStatus(const AText: string): TDeviceStatus;
begin
  if SameText(AText, 'Online') then
    Result := dsOnline
  else if SameText(AText, 'Warning') then
    Result := dsWarning
  else if SameText(AText, 'Error') then
    Result := dsError
  else
    Result := dsOffline;
end;

procedure SplitCsvLine(const ALine: string; AFields: TStrings);
var
  I: Integer;
  InQuotes: Boolean;
  Field: string;
begin
  AFields.Clear;
  InQuotes := False;
  Field := '';
  I := 1;
  while I <= Length(ALine) do
  begin
    if ALine[I] = '"' then
    begin
      if InQuotes and (I < Length(ALine)) and (ALine[I + 1] = '"') then
      begin
        Field := Field + '"';
        Inc(I);
      end
      else
        InQuotes := not InQuotes;
    end
    else if (ALine[I] = ',') and (not InQuotes) then
    begin
      AFields.Add(Field);
      Field := '';
    end
    else
      Field := Field + ALine[I];
    Inc(I);
  end;
  AFields.Add(Field);
end;

class function TCsvDeviceImporter.ImportFromFile(const AFileName: string;
  ADevices: TObjectList; out AMessage: string): Boolean;
var
  Lines, Fields: TStringList;
  Row: Integer;
  ErrorCount: Integer;
  Imported: TObjectList;
begin
  Result := False;
  AMessage := '';
  if not FileExists(AFileName) then
  begin
    AMessage := 'CSV file does not exist.';
    Exit;
  end;

  Lines := TStringList.Create;
  Fields := TStringList.Create;
  Imported := TObjectList.Create(True);
  try
    Lines.LoadFromFile(AFileName);
    for Row := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[Row]) = '' then
        Continue;
      if (Row = 0) and (Pos('Item', Lines[Row]) > 0) then
        Continue;

      SplitCsvLine(Lines[Row], Fields);
      if Fields.Count < 11 then
        raise Exception.CreateFmt('CSV row %d has %d fields; expected 11.',
          [Row + 1, Fields.Count]);

      ErrorCount := StrToIntDef(Trim(Fields[10]), 0);
      Imported.Add(TDevice.Create(Trim(Fields[0]), Trim(Fields[1]), Trim(Fields[2]),
        Trim(Fields[3]), Trim(Fields[4]), Trim(Fields[5]), ParseStatus(Trim(Fields[6])),
        Trim(Fields[7]), Trim(Fields[8]), Trim(Fields[9]), ErrorCount));
    end;

    if Imported.Count = 0 then
      raise Exception.Create('CSV did not contain any devices.');

    ADevices.Clear;
    Imported.OwnsObjects := False;
    while Imported.Count > 0 do
    begin
      ADevices.Add(Imported[0]);
      Imported.Delete(0);
    end;
    AMessage := Format('%d device(s) imported from CSV.', [ADevices.Count]);
    Result := True;
  except
    on E: Exception do
      AMessage := E.Message;
  end;
  Imported.Free;
  Fields.Free;
  Lines.Free;
end;

end.
