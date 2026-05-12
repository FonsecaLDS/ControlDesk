unit uLogger;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TLogLevel = (llInfo, llTx, llRx, llWarn, llError);

function LogLevelToText(ALevel: TLogLevel): string;
function FormatLogLine(ALevel: TLogLevel; const AMessage: string): string;

implementation

function LogLevelToText(ALevel: TLogLevel): string;
begin
  case ALevel of
    llInfo: Result := 'INFO ';
    llTx: Result := 'TX   ';
    llRx: Result := 'RX   ';
    llWarn: Result := 'WARN ';
    llError: Result := 'ERROR';
  else
    Result := 'INFO ';
  end;
end;

function FormatLogLine(ALevel: TLogLevel; const AMessage: string): string;
begin
  Result := FormatDateTime('[hh:nn:ss] ', Now) + LogLevelToText(ALevel) + ' ' + AMessage;
end;

end.
