unit uConfigDiff;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TConfigDiffTool = class
  public
    class procedure BuildLineDiff(AOriginal, AModified, ADiff: TStrings);
  end;

implementation

class procedure TConfigDiffTool.BuildLineDiff(AOriginal, AModified, ADiff: TStrings);
var
  Index, MaxCount: Integer;
  LeftLine, RightLine: string;
begin
  ADiff.Clear;
  MaxCount := AOriginal.Count;
  if AModified.Count > MaxCount then
    MaxCount := AModified.Count;

  ADiff.Add('ControlDesk Configuration Diff');
  ADiff.Add('Legend: = unchanged, - original, + modified');
  ADiff.Add('');

  for Index := 0 to MaxCount - 1 do
  begin
    if Index < AOriginal.Count then
      LeftLine := AOriginal[Index]
    else
      LeftLine := '';
    if Index < AModified.Count then
      RightLine := AModified[Index]
    else
      RightLine := '';

    if LeftLine = RightLine then
      ADiff.Add(Format('= %4d  %s', [Index + 1, LeftLine]))
    else
    begin
      if Index < AOriginal.Count then
        ADiff.Add(Format('- %4d  %s', [Index + 1, LeftLine]));
      if Index < AModified.Count then
        ADiff.Add(Format('+ %4d  %s', [Index + 1, RightLine]));
    end;
  end;
end;

end.
